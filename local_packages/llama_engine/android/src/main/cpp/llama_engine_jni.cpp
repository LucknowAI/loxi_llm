// JNI bridge for the llama_engine Flutter plugin.
//
// Clean-room implementation written against the public llama.cpp API and its
// MIT-licensed examples. Provides: model load/free, incremental (one-token-per
// call) streaming generation with a hold-back stop-sequence trim, a batch-safe
// chunked prompt decode, per-turn KV reset, a penalty/top-k/top-p/temp sampler
// chain with a separately-applied lazy GBNF grammar (see sampleNextToken), and
// a lock-free stop flag.

#include <jni.h>
#include <string>
#include <vector>
#include <mutex>
#include <atomic>
#include <cmath>
#include <stdexcept>
#include <android/log.h>

#include "llama.h"
#include "mtmd.h"
#include "mtmd-helper.h"

#define LOG_TAG "LlamaEngine"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// ---- Global state (guarded by g_mutex; g_should_stop is lock-free) ----------

static llama_model* g_model = nullptr;
static llama_context* g_context = nullptr;
static const llama_vocab* g_vocab = nullptr;
static llama_sampler* g_sampler = nullptr;  // penalties -> top_k -> top_p -> temp -> dist (no grammar)
static llama_sampler* g_grammar = nullptr;  // lazy GBNF grammar, applied separately by sampleNextToken
static mtmd_context* g_mtmd_ctx = nullptr;  // vision projector, null when no mmproj was loaded
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

// Returns the length of the longest valid UTF-8 prefix of [text]. Trailing
// bytes that belong to an incomplete multi-byte character are excluded so
// NewStringUTF never receives invalid Modified UTF-8 (which aborts on Android).
static size_t utf8_valid_prefix_len(const std::string& text) {
    const size_t len = text.size();
    if (len == 0) return 0;

    for (size_t i = 1; i <= 4 && i <= len; ++i) {
        const unsigned char c = static_cast<unsigned char>(text[len - i]);
        if ((c & 0xE0) == 0xC0) {
            if (i < 2) return len - i;
        } else if ((c & 0xF0) == 0xE0) {
            if (i < 3) return len - i;
        } else if ((c & 0xF8) == 0xF0) {
            if (i < 4) return len - i;
        }
    }
    return len;
}

static jstring new_jstring_utf8(JNIEnv* env, const std::string& s) {
    if (s.empty()) return env->NewStringUTF("");
    const size_t valid = utf8_valid_prefix_len(s);
    if (valid == 0) return env->NewStringUTF("");
    return env->NewStringUTF(s.substr(0, valid).c_str());
}

// Max safe emit end accounting for stop-sequence hold-back and UTF-8 boundaries.
static size_t safe_emit_end(const GenState& gen) {
    size_t end = gen.generated.size();
    const size_t stop_holdback = gen.max_stop_len > 1 ? gen.max_stop_len - 1 : 0;
    if (end > stop_holdback) end -= stop_holdback;
    return utf8_valid_prefix_len(gen.generated.substr(0, end));
}

// Build the sampler chain: penalties -> top_k -> top_p -> temp -> dist.
//
// Grammar is deliberately kept OUT of this chain and applied separately by
// sampleNextToken(). Chaining it after top_k/top_p (as before) let those
// truncate the candidate pool down to the model's highest-probability
// continuations before grammar ever saw them — so once a grammar-constrained
// generation (e.g. a completed tool-call block) only had one valid
// continuation left (an end-of-generation token), and that token wasn't
// among the surviving top_k/top_p candidates, grammar had nothing valid to
// select from. The sampler still forced a pick, producing a token grammar's
// own accept() then rejected, which threw an uncaught native exception and
// aborted the whole app (see #43). llama.cpp's own reference sampler
// (common/sampling.cpp: common_sampler_sample) avoids this by sampling
// without grammar first and only re-sampling grammar-first when the natural
// pick doesn't satisfy it — sampleNextToken mirrors that.
static void rebuildSampler(float temperature, float top_p, int top_k,
                           float repeat_penalty, const char* grammar_str) {
    if (g_sampler) {
        llama_sampler_free(g_sampler);
        g_sampler = nullptr;
    }
    if (g_grammar) {
        llama_sampler_free(g_grammar);
        g_grammar = nullptr;
    }
    auto params = llama_sampler_chain_default_params();
    g_sampler = llama_sampler_chain_init(params);
    llama_sampler_chain_add(g_sampler,
        llama_sampler_init_penalties(256, repeat_penalty, 0.0f, 0.0f));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_top_k(top_k));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_top_p(top_p, 1));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_temp(temperature));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_dist(1234));

    if (grammar_str != nullptr && grammar_str[0] != '\0' && g_vocab != nullptr) {
        // Use trigger *words* (auto regex-escaped by llama.cpp). Do NOT pass raw
        // patterns like `{"name"` — `{` is a regex metacharacter and aborts.
        static const char* kTriggers[] = {"```tool_call"};
        g_grammar = llama_sampler_init_grammar_lazy(
            g_vocab, grammar_str, "root", kTriggers,
            sizeof(kTriggers) / sizeof(kTriggers[0]), nullptr, 0);
        if (g_grammar != nullptr) {
            LOGI("Lazy GBNF grammar attached");
        } else {
            LOGE("Failed to parse GBNF grammar — continuing without constraints");
        }
    }
}

// Sample the next token, honoring g_grammar (if set) without letting
// top_k/top_p prune away its only valid continuation first. Mirrors
// llama.cpp's common_sampler_sample: sample via the plain chain, verify the
// pick against grammar, and only pay for a grammar-first re-sample when the
// natural pick doesn't satisfy it. The try/catch is defense in depth — with
// correct ordering this should never throw, but a native exception here must
// never be allowed to abort the whole app (see #43).
static llama_token sampleNextToken() {
    try {
        const int n_vocab = llama_vocab_n_tokens(g_vocab);
        const float* logits = llama_get_logits_ith(g_context, -1);

        std::vector<llama_token_data> cur(n_vocab);
        for (int i = 0; i < n_vocab; i++) {
            cur[i] = llama_token_data{i, logits[i], 0.0f};
        }
        llama_token_data_array cur_p = {cur.data(), cur.size(), -1, false};

        llama_sampler_apply(g_sampler, &cur_p);
        llama_token id = cur_p.data[cur_p.selected].id;

        if (g_grammar != nullptr) {
            llama_token_data single = {id, 1.0f, 0.0f};
            llama_token_data_array single_arr = {&single, 1, -1, false};
            llama_sampler_apply(g_grammar, &single_arr);
            const bool valid = single_arr.data[0].logit != -INFINITY;

            if (!valid) {
                // Resample: apply grammar before top_k/top_p this time so its
                // only valid continuation can't be pruned away first.
                for (int i = 0; i < n_vocab; i++) {
                    cur[i] = llama_token_data{i, logits[i], 0.0f};
                }
                cur_p = {cur.data(), cur.size(), -1, false};
                llama_sampler_apply(g_grammar, &cur_p);
                llama_sampler_apply(g_sampler, &cur_p);
                id = cur_p.data[cur_p.selected].id;
            }
            llama_sampler_accept(g_grammar, id);
        }

        llama_sampler_accept(g_sampler, id);
        return id;
    } catch (const std::exception& e) {
        LOGE("sampleNextToken: native sampling error, ending generation: %s", e.what());
        return LLAMA_TOKEN_NULL;
    }
}

extern "C" {

JNIEXPORT jboolean JNICALL
Java_dev_lokillm_llama_1engine_LlamaEnginePlugin_nativeInitModel(
    JNIEnv* env, jobject, jstring model_path,
    jint n_threads, jint context_size, jint batch_size, jstring mmproj_path) {
    std::lock_guard<std::mutex> lock(g_mutex);

    // Free any previously loaded model.
    if (g_sampler) { llama_sampler_free(g_sampler); g_sampler = nullptr; }
    if (g_grammar) { llama_sampler_free(g_grammar); g_grammar = nullptr; }
    if (g_mtmd_ctx) { mtmd_free(g_mtmd_ctx); g_mtmd_ctx = nullptr; }
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

    if (mmproj_path != nullptr) {
        const char* mmproj_cstr = env->GetStringUTFChars(mmproj_path, nullptr);
        mtmd_context_params mtmd_params = mtmd_context_params_default();
        mtmd_params.use_gpu = false;
        mtmd_params.n_threads = n_threads;
        mtmd_params.print_timings = false;
        g_mtmd_ctx = mtmd_init_from_file(mmproj_cstr, g_model, mtmd_params);
        env->ReleaseStringUTFChars(mmproj_path, mmproj_cstr);
        if (g_mtmd_ctx == nullptr) {
            LOGE("Failed to load mmproj — continuing as text-only");
        } else {
            LOGI("mmproj loaded, vision=%d", mtmd_support_vision(g_mtmd_ctx));
        }
    }

    LOGI("Model loaded (n_ctx=%d)", (int) llama_n_ctx(g_context));
    return JNI_TRUE;
}

JNIEXPORT jboolean JNICALL
Java_dev_lokillm_llama_1engine_LlamaEnginePlugin_nativeSupportsVision(
    JNIEnv*, jobject) {
    std::lock_guard<std::mutex> lock(g_mutex);
    return (g_mtmd_ctx != nullptr && mtmd_support_vision(g_mtmd_ctx)) ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jstring JNICALL
Java_dev_lokillm_llama_1engine_LlamaEnginePlugin_nativeMediaMarker(
    JNIEnv* env, jobject) {
    return env->NewStringUTF(mtmd_default_marker());
}

JNIEXPORT jboolean JNICALL
Java_dev_lokillm_llama_1engine_LlamaEnginePlugin_nativeGenerateStreamInit(
    JNIEnv* env, jobject, jstring prompt,
    jfloat temperature, jfloat top_p, jint top_k,
    jint max_tokens, jfloat repeat_penalty, jobjectArray stop_sequences,
    jstring grammar, jobjectArray image_paths) {
    std::lock_guard<std::mutex> lock(g_mutex);

    if (!g_model || !g_context || !g_vocab) {
        LOGE("nativeGenerateStreamInit: model not loaded");
        return JNI_FALSE;
    }

    const std::vector<std::string> stops = jStringArrayToVector(env, stop_sequences);

    // Rebuilt here, immediately adjacent to acquiring grammar_cstr, rather
    // than after the prompt is processed: the sampler chain doesn't depend
    // on anything computed below, and holding a JNI string across several
    // early-return paths (tokenize/decode/eval failures) leaked it on every
    // one of them.
    const char* grammar_cstr = nullptr;
    if (grammar != nullptr) {
        grammar_cstr = env->GetStringUTFChars(grammar, nullptr);
    }
    rebuildSampler(temperature, top_p, top_k, repeat_penalty, grammar_cstr);
    if (grammar_cstr != nullptr) {
        env->ReleaseStringUTFChars(grammar, grammar_cstr);
    }

    g_should_stop = false;
    g_gen.reset();

    // Fresh KV cache each turn (the Dart layer resends the full prompt).
    llama_memory_clear(llama_get_memory(g_context), true);

    const char* prompt_str = env->GetStringUTFChars(prompt, nullptr);
    std::string text(prompt_str);
    env->ReleaseStringUTFChars(prompt, prompt_str);

    const std::vector<std::string> image_path_vec = jStringArrayToVector(env, image_paths);
    const int n_ctx = (int) llama_n_ctx(g_context);
    int n_pos_after_prompt = 0;

    if (!image_path_vec.empty() && g_mtmd_ctx == nullptr) {
        LOGE("Images provided but no mmproj loaded — falling back to text-only");
    }

    if (!image_path_vec.empty() && g_mtmd_ctx != nullptr) {
        // Multimodal priming: build bitmaps from the given image files, tokenize
        // prompt+images together (the prompt must already contain the marker
        // returned by mtmd_default_marker()), then prime the KV cache in one
        // call. sampleNextToken()/nativeGenerateStreamNext below are completely
        // unchanged after this — image priming only affects how the KV cache
        // gets seeded, not how tokens get sampled.
        std::vector<mtmd_bitmap*> bitmaps;
        bool bitmap_error = false;
        for (const auto& path : image_path_vec) {
            mtmd_bitmap* bmp = mtmd_helper_bitmap_init_from_file(g_mtmd_ctx, path.c_str());
            if (bmp == nullptr) {
                LOGE("Failed to load image: %s", path.c_str());
                bitmap_error = true;
                break;
            }
            bitmaps.push_back(bmp);
        }

        if (bitmap_error) {
            for (auto* bmp : bitmaps) mtmd_bitmap_free(bmp);
            return JNI_FALSE;
        }

        mtmd_input_text input_text;
        input_text.text = text.c_str();
        input_text.add_special = true;
        input_text.parse_special = true;

        // mtmd_tokenize() takes `const mtmd_bitmap**`; a std::vector<mtmd_bitmap*>
        // doesn't implicitly convert (multi-level const-qualification isn't an
        // implicit conversion in C++), so build a const-pointer view for the call
        // while keeping the owning vector for the mtmd_bitmap_free() cleanup below.
        std::vector<const mtmd_bitmap*> const_bitmaps(bitmaps.begin(), bitmaps.end());

        mtmd_input_chunks* chunks = mtmd_input_chunks_init();
        const int32_t tok_ret = mtmd_tokenize(
            g_mtmd_ctx, chunks, &input_text, const_bitmaps.data(), const_bitmaps.size());
        for (auto* bmp : bitmaps) mtmd_bitmap_free(bmp);
        if (tok_ret != 0) {
            LOGE("Failed to tokenize multimodal prompt, ret=%d", tok_ret);
            mtmd_input_chunks_free(chunks);
            return JNI_FALSE;
        }

        // Context-window pre-check: make sure the primed prompt plus
        // generation headroom will actually fit before priming the KV cache.
        const int n_pos_needed = (int) mtmd_helper_get_n_pos(chunks);
        if (n_pos_needed + max_tokens > n_ctx) {
            LOGE("Multimodal prompt+image too large for context: needs %d + %d headroom, have n_ctx=%d",
                 n_pos_needed, max_tokens, n_ctx);
            mtmd_input_chunks_free(chunks);
            return JNI_FALSE;
        }

        llama_pos new_n_past = 0;
        const uint32_t n_batch = llama_n_batch(g_context);
        const int32_t eval_ret = mtmd_helper_eval_chunks(
            g_mtmd_ctx, g_context, chunks,
            /*n_past=*/0, /*seq_id=*/0, (int32_t) n_batch,
            /*logits_last=*/true, &new_n_past);
        mtmd_input_chunks_free(chunks);
        if (eval_ret != 0) {
            LOGE("Failed to eval multimodal prompt, ret=%d", eval_ret);
            return JNI_FALSE;
        }

        n_pos_after_prompt = (int) new_n_past;
    } else {
        // Tokenize.
        const int n_prompt = -llama_tokenize(g_vocab, text.c_str(), text.size(), nullptr, 0, true, true);
        std::vector<llama_token> tokens(n_prompt);
        if (llama_tokenize(g_vocab, text.c_str(), text.size(), tokens.data(), tokens.size(), true, true) < 0) {
            LOGE("Failed to tokenize prompt");
            return JNI_FALSE;
        }

        // Keep the prompt within the context window, reserving room to generate.
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
                return JNI_FALSE;
            }
        }

        n_pos_after_prompt = (int) tokens.size();
    }

    g_gen.active = true;
    g_gen.n_pos = n_pos_after_prompt;
    g_gen.n_ctx = n_ctx;
    g_gen.remaining = max_tokens;
    g_gen.stops = stops;
    g_gen.max_stop_len = longestStopLen(stops);
    LOGI("Stream init: %d prompt tokens, up to %d generated", g_gen.n_pos, max_tokens);
    return JNI_TRUE;
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
            const size_t utf8_end = utf8_valid_prefix_len(g_gen.generated);
            if (utf8_end > g_gen.pushed) {
                const std::string tail =
                    g_gen.generated.substr(g_gen.pushed, utf8_end - g_gen.pushed);
                g_gen.pushed = utf8_end;
                return new_jstring_utf8(env, tail);
            }
        }
        return nullptr;
    };

    if (g_should_stop.load() || g_gen.remaining <= 0 || g_gen.n_pos >= g_gen.n_ctx) {
        return end_with_flush();
    }

    llama_token new_token = sampleNextToken();
    if (new_token == LLAMA_TOKEN_NULL || llama_vocab_is_eog(g_vocab, new_token)) {
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
        if (stop_pos > g_gen.pushed) {
            const std::string slice =
                g_gen.generated.substr(g_gen.pushed, stop_pos - g_gen.pushed);
            emit = slice.substr(0, utf8_valid_prefix_len(slice));
        }
        g_gen.stopped_on_seq = true;
        g_gen.active = false;
        return new_jstring_utf8(env, emit);
    }

    const size_t emit_end = safe_emit_end(g_gen);
    std::string emit;
    if (emit_end > g_gen.pushed) {
        emit = g_gen.generated.substr(g_gen.pushed, emit_end - g_gen.pushed);
        g_gen.pushed = emit_end;
    }
    return new_jstring_utf8(env, emit);
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
    if (g_grammar) { llama_sampler_free(g_grammar); g_grammar = nullptr; }
    if (g_mtmd_ctx) { mtmd_free(g_mtmd_ctx); g_mtmd_ctx = nullptr; }
    if (g_context) { llama_free(g_context); g_context = nullptr; }
    if (g_model) { llama_free_model(g_model); g_model = nullptr; }
    g_vocab = nullptr;
}

} // extern "C"
