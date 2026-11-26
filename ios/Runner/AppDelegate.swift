import AVFoundation
import Flutter
import Speech
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TranscribePlugin")
    TranscribePlugin.register(messenger: registrar.messenger())
  }
}

private enum TranscribeError: Error {
  case denied, unsupported, failed
  var code: String {
    switch self {
    case .denied: return "denied"
    case .unsupported: return "unsupported"
    case .failed: return "failed"
    }
  }
}

/// On-device transcription for Notes recordings. One call transcribes one
/// chunk `[startMs, endMs)` of a file and returns `{startMs, endMs, text}`
/// maps in file time. iOS 26+ uses SpeechAnalyzer, older iOS uses
/// SFSpeechRecognizer with on-device recognition required.
enum TranscribePlugin {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "lumway/transcribe", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "transcribe",
        let a = call.arguments as? [String: Any],
        let path = a["path"] as? String,
        let start = a["startMs"] as? Int,
        let end = a["endMs"] as? Int,
        let language = a["language"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      Task {
        do {
          result(try await transcribe(path: path, startMs: start, endMs: end, language: language))
        } catch let e as TranscribeError {
          result(FlutterError(code: e.code, message: nil, details: nil))
        } catch {
          result(FlutterError(code: "failed", message: "\(error)", details: nil))
        }
      }
    }
  }

  private static func transcribe(path: String, startMs: Int, endMs: Int, language: String)
    async throws -> [[String: Any]]
  {
    guard await authorized() else { throw TranscribeError.denied }
    let locale = Locale(identifier: language == "en" ? "en-US" : language)
    let slice = try await cut(URL(fileURLWithPath: path), startMs: startMs, endMs: endMs)
    defer { try? FileManager.default.removeItem(at: slice) }
    let raw: [[String: Any]]
    if #available(iOS 26.0, *) {
      raw = try await modern(slice, locale)
    } else {
      raw = try await legacy(slice, locale)
    }
    return raw.map {
      ["startMs": ($0["startMs"] as! Int) + startMs, "endMs": ($0["endMs"] as! Int) + startMs,
       "text": $0["text"] as! String]
    }
  }

  private static func authorized() async -> Bool {
    if SFSpeechRecognizer.authorizationStatus() == .authorized { return true }
    return await withCheckedContinuation { c in
      SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0 == .authorized) }
    }
  }

  /// Copies the chunk into a temp m4a so only that part is recognised.
  private static func cut(_ url: URL, startMs: Int, endMs: Int) async throws -> URL {
    guard
      let export = AVAssetExportSession(
        asset: AVURLAsset(url: url), presetName: AVAssetExportPresetAppleM4A)
    else { throw TranscribeError.failed }
    let out = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString + ".m4a")
    export.outputURL = out
    export.outputFileType = .m4a
    export.timeRange = CMTimeRange(
      start: CMTime(value: Int64(startMs), timescale: 1000),
      end: CMTime(value: Int64(endMs), timescale: 1000))
    await withCheckedContinuation { c in export.exportAsynchronously { c.resume() } }
    guard export.status == .completed else { throw TranscribeError.failed }
    return out
  }

  @available(iOS 26.0, *)
  private static func modern(_ url: URL, _ locale: Locale) async throws -> [[String: Any]] {
    guard let supported = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
      throw TranscribeError.unsupported
    }
    let transcriber = SpeechTranscriber(
      locale: supported, transcriptionOptions: [], reportingOptions: [],
      attributeOptions: [.audioTimeRange])
    if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
      try await request.downloadAndInstall()
    }
    let analyzer = SpeechAnalyzer(modules: [transcriber])
    let collector = Task { () -> [[String: Any]] in
      var out = [[String: Any]]()
      for try await r in transcriber.results {
        let text = String(r.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { continue }
        out.append([
          "startMs": Int(r.range.start.seconds * 1000),
          "endMs": Int(r.range.end.seconds * 1000),
          "text": text,
        ])
      }
      return out
    }
    let file = try AVAudioFile(forReading: url)
    if let last = try await analyzer.analyzeSequence(from: file) {
      try await analyzer.finalizeAndFinish(through: last)
    } else {
      await analyzer.cancelAndFinishNow()
    }
    return try await collector.value
  }

  private static func legacy(_ url: URL, _ locale: Locale) async throws -> [[String: Any]] {
    guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable,
      recognizer.supportsOnDeviceRecognition
    else { throw TranscribeError.unsupported }
    let request = SFSpeechURLRecognitionRequest(url: url)
    request.requiresOnDeviceRecognition = true
    request.shouldReportPartialResults = false
    return try await withCheckedThrowingContinuation { c in
      var finished = false
      recognizer.recognitionTask(with: request) { result, error in
        if finished { return }
        if let error = error as NSError? {
          finished = true
          // 1110: no speech detected in this chunk.
          if error.code == 1110 { c.resume(returning: []) } else { c.resume(throwing: error) }
          return
        }
        guard let result = result, result.isFinal else { return }
        finished = true
        // Words to sentence-sized rows: break on a pause or a long line.
        var out = [[String: Any]]()
        var words = [String]()
        var rowStart = 0.0
        var lastEnd = 0.0
        func flush() {
          guard !words.isEmpty else { return }
          out.append([
            "startMs": Int(rowStart * 1000), "endMs": Int(lastEnd * 1000),
            "text": words.joined(separator: " "),
          ])
          words = []
        }
        for s in result.bestTranscription.segments {
          if !words.isEmpty && (s.timestamp - lastEnd > 0.8 || words.joined(separator: " ").count > 160) {
            flush()
          }
          if words.isEmpty { rowStart = s.timestamp }
          words.append(s.substring)
          lastEnd = s.timestamp + s.duration
        }
        flush()
        c.resume(returning: out)
      }
    }
  }
}
