package com.lumway.whisper

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class WhisperLib {
  external fun initContext(path: String): Long
  external fun freeContext(ptr: Long)
  external fun transcribe(ptr: Long, samples: FloatArray, lang: String, threads: Int): ByteArray?

  companion object {
    init {
      System.loadLibrary("lumway_whisper")
    }
  }
}

/**
 * `lumway/transcribe` on Android, mirroring the iOS channel:
 *  - `duration` {path} -> ms
 *  - `transcribe` {path, startMs, endMs, language, modelPath} -> [{startMs, endMs, text}]
 *  - `release` -> frees the loaded model
 * One model stays loaded between chunks of a run; a single thread serialises calls.
 */
class LumwayWhisperPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  private var channel: MethodChannel? = null
  private val worker = Executors.newSingleThreadExecutor()
  private val main = android.os.Handler(android.os.Looper.getMainLooper())
  private var lib: WhisperLib? = null
  private var ctx = 0L
  private var ctxPath: String? = null
  private var appContext: android.content.Context? = null

  override fun onAttachedToEngine(b: FlutterPlugin.FlutterPluginBinding) {
    appContext = b.applicationContext
    channel = MethodChannel(b.binaryMessenger, "lumway/transcribe").also {
      it.setMethodCallHandler(this)
    }
  }

  override fun onDetachedFromEngine(b: FlutterPlugin.FlutterPluginBinding) {
    channel?.setMethodCallHandler(null)
    worker.execute { free() }
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    // Cheap system check: answer now, never queued behind a running chunk.
    if (call.method == "supported") { result.success(supported()); return }
    worker.execute {
      try {
        val out: Any? = when (call.method) {
          "supported" -> supported()
          "duration" -> durationMs(call.argument<String>("path")!!)
          "transcribe" -> transcribe(
            call.argument<String>("path")!!,
            call.argument<Int>("startMs")!!,
            call.argument<Int>("endMs")!!,
            call.argument<String>("language") ?: "en",
            call.argument<String>("modelPath")!!,
          )
          "release" -> { free(); null }
          else -> {
            main.post { result.notImplemented() }
            return@execute
          }
        }
        main.post { result.success(out) }
      } catch (e: Throwable) {
        main.post { result.error("failed", e.message, null) }
      }
    }
  }

  /** 64-bit processor and at least 2.5 GiB of RAM (a 3 GB phone reports a little less): small whisper needs both. */
  private fun supported(): Boolean {
    if (android.os.Build.SUPPORTED_64_BIT_ABIS.isEmpty()) return false
    val am = appContext?.getSystemService(android.content.Context.ACTIVITY_SERVICE)
      as? android.app.ActivityManager ?: return false
    val info = android.app.ActivityManager.MemoryInfo()
    am.getMemoryInfo(info)
    return info.totalMem >= 2_684_354_560L
  }

  private fun free() {
    if (ctx != 0L) lib?.freeContext(ctx)
    ctx = 0L
    ctxPath = null
  }

  private fun durationMs(path: String): Int {
    val ex = MediaExtractor()
    try {
      ex.setDataSource(path)
      for (i in 0 until ex.trackCount) {
        val f = ex.getTrackFormat(i)
        if (f.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true &&
          f.containsKey(MediaFormat.KEY_DURATION)
        ) {
          return (f.getLong(MediaFormat.KEY_DURATION) / 1000).toInt()
        }
      }
      throw IllegalStateException("no audio track")
    } finally {
      ex.release()
    }
  }

  private fun transcribe(
    path: String, startMs: Int, endMs: Int, language: String, modelPath: String,
  ): List<Map<String, Any>> {
    val pcm = decode(path, startMs.toLong() * 1000, endMs.toLong() * 1000)
    if (pcm.isEmpty()) return emptyList()
    if (ctx == 0L || ctxPath != modelPath) {
      free()
      val l = lib ?: WhisperLib().also { lib = it }
      ctx = l.initContext(modelPath)
      if (ctx == 0L) throw IllegalStateException("model failed to load")
      ctxPath = modelPath
    }
    val threads = Runtime.getRuntime().availableProcessors().coerceIn(2, 4)
    val bytes = lib!!.transcribe(ctx, pcm, language, threads)
      ?: throw IllegalStateException("whisper failed")
    val noise = Regex("^[\\[(].*[\\])]$")
    val out = ArrayList<Map<String, Any>>()
    for (line in String(bytes, Charsets.UTF_8).split('\n')) {
      val parts = line.split('\t', limit = 3)
      if (parts.size < 3) continue
      val text = parts[2].trim()
      if (text.isEmpty() || noise.matches(text)) continue
      out.add(
        mapOf(
          "startMs" to startMs + parts[0].toInt() * 10,
          "endMs" to startMs + parts[1].toInt() * 10,
          "text" to text,
        ),
      )
    }
    return out
  }

  /** Decodes [startUs, endUs) of the audio track to 16 kHz mono float PCM. */
  private fun decode(path: String, startUs: Long, endUs: Long): FloatArray {
    val ex = MediaExtractor()
    var codec: MediaCodec? = null
    try {
      ex.setDataSource(path)
      var track = -1
      var format: MediaFormat? = null
      for (i in 0 until ex.trackCount) {
        val f = ex.getTrackFormat(i)
        if (f.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) {
          track = i; format = f; break
        }
      }
      if (track < 0 || format == null) throw IllegalStateException("no audio track")
      ex.selectTrack(track)
      ex.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
      codec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
      codec.configure(format, null, null, 0)
      codec.start()

      var rate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
      var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
      var mono = FloatArray(rate * 70)
      var n = 0
      val info = MediaCodec.BufferInfo()
      var inputDone = false
      var outputDone = false
      while (!outputDone) {
        if (!inputDone) {
          val i = codec.dequeueInputBuffer(10_000)
          if (i >= 0) {
            val buf = codec.getInputBuffer(i)!!
            val size = ex.readSampleData(buf, 0)
            val t = ex.sampleTime
            if (size < 0 || t >= endUs) {
              codec.queueInputBuffer(i, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
              inputDone = true
            } else {
              codec.queueInputBuffer(i, 0, size, t, 0)
              ex.advance()
            }
          }
        }
        val o = codec.dequeueOutputBuffer(info, 10_000)
        if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
          val f = codec.outputFormat
          rate = f.getInteger(MediaFormat.KEY_SAMPLE_RATE)
          channels = f.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        } else if (o >= 0) {
          val shorts = codec.getOutputBuffer(o)!!.order(java.nio.ByteOrder.nativeOrder()).asShortBuffer()
          val frames = info.size / 2 / channels
          for (k in 0 until frames) {
            val tUs = info.presentationTimeUs + k * 1_000_000L / rate
            if (tUs < startUs) continue
            if (tUs >= endUs) break
            var sum = 0f
            for (c in 0 until channels) sum += shorts.get(k * channels + c) / 32768f
            if (n == mono.size) mono = mono.copyOf(n * 2)
            mono[n++] = sum / channels
          }
          codec.releaseOutputBuffer(o, false)
          if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
        }
      }
      return resample(mono, n, rate)
    } finally {
      try { codec?.stop() } catch (_: Throwable) {}
      codec?.release()
      ex.release()
    }
  }

  private fun resample(src: FloatArray, n: Int, rate: Int): FloatArray {
    if (rate == 16000) return src.copyOf(n)
    // Average each output sample's span of input samples (a box low-pass) so
    // speech above 8 kHz does not fold back into the band whisper reads.
    val outN = (n.toLong() * 16000 / rate).toInt()
    val out = FloatArray(outN)
    val step = rate / 16000.0
    for (i in 0 until outN) {
      val from = (i * step).toInt()
      val to = minOf(n - 1, maxOf(from, ((i + 1) * step - 1e-9).toInt()))
      var sum = 0f
      for (k in from..to) sum += src[k]
      out[i] = sum / (to - from + 1)
    }
    return out
  }
}
