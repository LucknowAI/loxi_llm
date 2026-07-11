// JNI bridge for the llama_engine Flutter plugin.
//
// Clean-room implementation written against the public llama.cpp API and its
// MIT-licensed examples. Provides: model load/free, incremental (one-token-per
// call) streaming generation with a hold-back stop-sequence trim, a batch-safe
// chunked prompt decode, per-turn KV reset, a penalty/top-k/top-p/temp sampler
// chain, and a lock-free stop flag.

#include <jni.h>
#include <string>
#include <vector>
#include <mutex>
#include <atomic>
#include <android/log.h>

#include "llama.h"

#define LOG_TAG "LlamaEngine"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// ---- Global state (guarded by g_mutex; g_should_stop is lock-free) ----------

static llama_model* g_model = nullptr;
static llama_context* g_context = nullptr;
static const llama_vocab* g_vocab = nullptr;
static llama_sampler* g_sampler = nullptr;
static std::mutex g_mutex;
static std::atomic<bool> g_should_stop{false};

// Persistent per-generation streaming state.
struct GenState {
    bool active = false;
    bool stopped_on_seq = false;
    int n_pos = 0;
    int n_ctx = 0;
    int remaining = 0;
    std::string generated;   // all decoded text so far
    size_t pushed = 0;       // chars already emitted
    std::vector<std::string> stops;
    size_t max_stop_len = 0;
    void reset() {
        active = false;
        stopped_on_seq = false;
        n_pos = n_ctx = remaining = 0;
        generated.clear();
        pushed = 0;
        stops.clear();
        max_stop_len = 0;
    }
};
static GenState g_gen;

// ---- Helpers ----------------------------------------------------------------

static std::vector<std::string> jStringArrayToVector(JNIEnv* env, jobjectArray arr) {
    std::vector<std::string> out;
    if (arr == nullptr) return out;
    const jsize len = env->GetArrayLength(arr);
    for (jsize i = 0; i < len; i++) {
        jstring js = (jstring) env->GetObjectArrayElement(arr, i);
        if (js == nullptr) continue;
        const char* cs = env->GetStringUTFChars(js, nullptr);
        if (cs != nullptr) {
            out.emplace_back(cs);
            env->ReleaseStringUTFChars(js, cs);
        }
        env->DeleteLocalRef(js);
    }
    return out;
}

static size_t earliestStop(const std::string& text,
                           const std::vector<std::string>& stops) {
    size_t best = std::string::npos;
    for (const auto& s : stops) {
        if (s.empty()) continue;
        const size_t p = text.find(s);
        if (p != std::string::npos && p < best) best = p;
    }
    return best;
}

static size_t longestStopLen(const std::vector<std::string>& stops) {
    size_t m = 0;
    for (const auto& s : stops) if (s.size() > m) m = s.size();
    return m;
}

// Build the sampler chain: penalties -> top_k -> top_p -> temp -> dist.
static void rebuildSampler(float temperature, float top_p, int top_k,
                           float repeat_penalty) {
    if (g_sampler) {
        llama_sampler_free(g_sampler);
        g_sampler = nullptr;
    }
    auto params = llama_sampler_chain_default_params();
    g_sampler = llama_sampler_chain_init(params);
    llama_sampler_chain_add(g_sampler,
        llama_sampler_init_penalties(256, repeat_penalty, 0.0f, 0.0f));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_top_k(top_k));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_top_p(top_p, 1));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_temp(temperature));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_dist(1234));
}

extern "C" {

JNIEXPORT jboolean JNICALL
Java_dev_lokillm_llama_1engine_LlamaEnginePlugin_nativeInitModel(
    JNIEnv* env, jobject, jstring model_path,
    jint n_threads, jint context_size, jint batch_size) {
    std::lock_guard<std::mutex> lock(g_mutex);

    // Free any previously loaded model.
    if (g_sampler) { llama_sampler_free(g_sampler); g_sampler = nullptr; }
    if (g_context) { llama_free(g_context); g_context = nullptr; }
    if (g_model) { llama_free_model(g_model); g_model = nullptr; }
    g_gen.reset();

    ggml_backend_load_all();

    const char* path = env->GetStringUTFChars(model_path, nullptr);
    LOGI("Loading model: %s (threads=%d ctx=%d batch=%d)", path, n_threads, context_size, batch_size);

    llama_model_params mparams = llama_model_default_params();
    mparams.n_gpu_layers = 0; // CPU only
    g_model = llama_model_load_from_file(path, mparams);
    env->ReleaseStringUTFChars(model_path, path);
    if (!g_model) {
        LOGE("Failed to load model");
        return JNI_FALSE;
    }

    g_vocab = llama_model_get_vocab(g_model);

    llama_context_params cparams = llama_context_default_params();
    cparams.n_ctx = context_size;
    cparams.n_batch = batch_size;
    cparams.n_threads = n_threads;
    cparams.n_threads_batch = n_threads;
    g_context = llama_init_from_model(g_model, cparams);
    if (!g_context) {
        LOGE("Failed to create context");
        llama_free_model(g_model);
        g_model = nullptr;
        return JNI_FALSE;
    }

    LOGI("Model loaded (n_ctx=%d)", (int) llama_n_ctx(g_context));
    return JNI_TRUE;
}

JNIEXPORT void JNICALL
Java_dev_lokillm_llama_1engine_LlamaEnginePlugin_nativeGenerateStreamInit(
    JNIEnv* env, jobject, jstring prompt,
    jfloat temperature, jfloat top_p, jint top_k,
    jint max_tokens, jfloat repeat_penalty, jobjectArray stop_sequences) {
    std::lock_guard<std::mutex> lock(g_mutex);

    if (!g_model || !g_context || !g_vocab) {
        LOGE("nativeGenerateStreamInit: model not loaded");
        return;
    }

    const std::vector<std::string> stops = jStringArrayToVector(env, stop_sequences);

    g_should_stop = false;
    g_gen.reset();

    // Fresh KV cache each turn (the Dart layer resends the full prompt).
    llama_memory_clear(llama_get_memory(g_context), true);

    const char* prompt_str = env->GetStringUTFChars(prompt, nullptr);
    std::string text(prompt_str);
    env->ReleaseStringUTFChars(prompt, prompt_str);

    // Tokenize.
    const int n_prompt = -llama_tokenize(g_vocab, text.c_str(), text.size(), nullptr, 0, true, true);
    std::vector<llama_token> tokens(n_prompt);
    if (llama_tokenize(g_vocab, text.c_str(), text.size(), tokens.data(), tokens.size(), true, true) < 0) {
        LOGE("Failed to tokenize prompt");
        return;
    }

    // Keep the prompt within the context window, reserving room to generate.
    const int n_ctx = (int) llama_n_ctx(g_context);
    const int max_prompt = n_ctx > max_tokens + 4 ? n_ctx - max_tokens : n_ctx - 1;
    if (max_prompt > 0 && (int) tokens.size() > max_prompt) {
        const int overflow = (int) tokens.size() - max_prompt;
        tokens.erase(tokens.begin(), tokens.begin() + overflow);
        LOGI("Truncated prompt by %d tokens to fit n_ctx=%d", overflow, n_ctx);
    }

    // Decode the prompt in chunks no larger than n_batch (a single oversized
    // llama_decode aborts on GGML_ASSERT(n_tokens_all <= n_batch)).
    const uint32_t n_batch = llama_n_batch(g_context);
    for (size_t i = 0; i < tokens.size(); i += n_batch) {
        const size_t remaining = tokens.size() - i;
        const size_t chunk = remaining < (size_t) n_batch ? remaining : (size_t) n_batch;
        llama_batch batch = llama_batch_get_one(tokens.data() + i, chunk);
        if (llama_decode(g_context, batch) != 0) {
            LOGE("Failed to decode prompt chunk at %zu", i);
            return;
        }
    }

    rebuildSampler(temperature, top_p, top_k, repeat_penalty);

    g_gen.active = true;
    g_gen.n_pos = (int) tokens.size();
    g_gen.n_ctx = n_ctx;
    g_gen.remaining = max_tokens;
    g_gen.stops = stops;
    g_gen.max_stop_len = longestStopLen(stops);
    LOGI("Stream init: %d prompt tokens, up to %d generated", g_gen.n_pos, max_tokens);
}

JNIEXPORT jstring JNICALL
Java_dev_lokillm_llama_1engine_LlamaEnginePlugin_nativeGenerateStreamNext(
    JNIEnv* env, jobject) {
    std::lock_guard<std::mutex> lock(g_mutex);

    if (!g_gen.active) return nullptr;

    // Emit any held-back tail once (unless a stop matched), then finish.
    auto end_with_flush = [&]() -> jstring {
        g_gen.active = false;
        if (!g_gen.stopped_on_seq && g_gen.pushed < g_gen.generated.size()) {
            const std::string tail = g_gen.generated.substr(g_gen.pushed);
            g_gen.pushed = g_gen.generated.size();
            return env->NewStringUTF(tail.c_str());
        }
        return nullptr;
    };

    if (g_should_stop.load() || g_gen.remaining <= 0 || g_gen.n_pos >= g_gen.n_ctx) {
        return end_with_flush();
    }

    llama_token new_token = llama_sampler_sample(g_sampler, g_context, -1);
    if (llama_vocab_is_eog(g_vocab, new_token)) {
        return end_with_flush();
    }

    char piece[256] = {0};
    int n = llama_token_to_piece(g_vocab, new_token, piece, sizeof(piece) - 1, 0, true);
    if (n > 0) {
        piece[n] = '\0';
        g_gen.generated.append(piece);
    }

    llama_batch batch = llama_batch_get_one(&new_token, 1);
    g_gen.n_pos++;
    g_gen.remaining--;
    if (llama_decode(g_context, batch) != 0) {
        LOGE("Failed to decode token");
        return end_with_flush();
    }

    // Stop-sequence hold-back trim (state persists across calls).
    const size_t stop_pos = earliestStop(g_gen.generated, g_gen.stops);
    if (stop_pos != std::string::npos) {
        std::string emit;
        if (stop_pos > g_gen.pushed) emit = g_gen.generated.substr(g_gen.pushed, stop_pos - g_gen.pushed);
        g_gen.stopped_on_seq = true;
        g_gen.active = false;
        return env->NewStringUTF(emit.c_str());
    }

    const size_t holdback = g_gen.max_stop_len > 1 ? g_gen.max_stop_len - 1 : 0;
    std::string emit;
    if (g_gen.generated.size() > g_gen.pushed + holdback) {
        const size_t emit_end = g_gen.generated.size() - holdback;
        emit = g_gen.generated.substr(g_gen.pushed, emit_end - g_gen.pushed);
        g_gen.pushed = emit_end;
    }
    // May be "" (a token was generated but nothing is safe to emit yet).
    return env->NewStringUTF(emit.c_str());
}

JNIEXPORT void JNICALL
Java_dev_lokillm_llama_1engine_LlamaEnginePlugin_nativeGenerateStreamEnd(
    JNIEnv*, jobject) {
    std::lock_guard<std::mutex> lock(g_mutex);
    g_gen.reset();
}

JNIEXPORT void JNICALL
Java_dev_lokillm_llama_1engine_LlamaEnginePlugin_nativeStopGeneration(
    JNIEnv*, jobject) {
    // Lock-free so Stop never waits behind an in-flight Next.
    g_should_stop.store(true);
}

JNIEXPORT void JNICALL
Java_dev_lokillm_llama_1engine_LlamaEnginePlugin_nativeFreeModel(
    JNIEnv*, jobject) {
    std::lock_guard<std::mutex> lock(g_mutex);
    g_gen.reset();
    if (g_sampler) { llama_sampler_free(g_sampler); g_sampler = nullptr; }
    if (g_context) { llama_free(g_context); g_context = nullptr; }
    if (g_model) { llama_free_model(g_model); g_model = nullptr; }
    g_vocab = nullptr;
}

} // extern "C"
