#include <jni.h>
#include <string>
#include "whisper.h"

extern "C" {

JNIEXPORT jlong JNICALL Java_com_lumway_whisper_WhisperLib_initContext(
    JNIEnv *env, jobject, jstring path) {
  const char *p = env->GetStringUTFChars(path, nullptr);
  whisper_context_params cp = whisper_context_default_params();
  cp.use_gpu = false;
  whisper_context *ctx = whisper_init_from_file_with_params(p, cp);
  env->ReleaseStringUTFChars(path, p);
  return reinterpret_cast<jlong>(ctx);
}

JNIEXPORT void JNICALL Java_com_lumway_whisper_WhisperLib_freeContext(
    JNIEnv *, jobject, jlong ptr) {
  if (ptr != 0) whisper_free(reinterpret_cast<whisper_context *>(ptr));
}

// Returns UTF-8 bytes of "t0\tt1\ttext" lines (t in 10 ms units), or null when
// whisper_full fails. Bytes, not jstring: partial multi-byte text must not
// reach NewStringUTF.
JNIEXPORT jbyteArray JNICALL Java_com_lumway_whisper_WhisperLib_transcribe(
    JNIEnv *env, jobject, jlong ptr, jfloatArray samples, jstring lang,
    jint threads) {
  auto *ctx = reinterpret_cast<whisper_context *>(ptr);
  const char *l = env->GetStringUTFChars(lang, nullptr);
  std::string language = l;
  env->ReleaseStringUTFChars(lang, l);

  whisper_full_params p = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
  p.print_realtime = false;
  p.print_progress = false;
  p.print_timestamps = false;
  p.print_special = false;
  p.translate = false;
  p.language = language.c_str();
  p.n_threads = threads;
  p.no_context = true;
  p.suppress_nst = true;

  jsize n = env->GetArrayLength(samples);
  jfloat *data = env->GetFloatArrayElements(samples, nullptr);
  int rc = whisper_full(ctx, p, data, n);
  env->ReleaseFloatArrayElements(samples, data, JNI_ABORT);
  if (rc != 0) return nullptr;

  std::string out;
  int count = whisper_full_n_segments(ctx);
  for (int i = 0; i < count; i++) {
    out += std::to_string(whisper_full_get_segment_t0(ctx, i)) + "\t" +
           std::to_string(whisper_full_get_segment_t1(ctx, i)) + "\t" +
           whisper_full_get_segment_text(ctx, i) + "\n";
  }
  jbyteArray arr = env->NewByteArray(static_cast<jsize>(out.size()));
  env->SetByteArrayRegion(arr, 0, static_cast<jsize>(out.size()),
                          reinterpret_cast<const jbyte *>(out.data()));
  return arr;
}

}
