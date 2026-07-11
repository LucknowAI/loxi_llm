# local_packages

In-house Flutter plugins for this app, referenced by `path:` in `pubspec.yaml`.

After cloning the repo, initialize submodules (pulls in `llama.cpp`):

```bash
git submodule update --init --recursive
```

---

## llama_engine

**License:** MIT.

An in-house, MIT-licensed Flutter plugin (Android only) for on-device GGUF text
generation via [`llama.cpp`](https://github.com/ggml-org/llama.cpp) (MIT). It was
written from scratch against llama.cpp's public API — it is **not** derived from
any third-party wrapper — so the whole repository is cleanly permissive.

**What it provides**
- `LlamaEngine` — load a GGUF model, stream tokens, stop mid-generation, unload.
- Token-by-token streaming over an `EventChannel`; control over a `MethodChannel`.
- Native behaviors: batch-safe chunked prompt decode (no crash on long prompts),
  per-turn KV reset, a `penalties → top_k → top_p → temp` sampler chain, stop
  sequences with hold-back trimming, and a lock-free stop flag.

**Structure**
- `lib/llama_engine.dart` — the Dart API.
- `android/src/main/kotlin/.../LlamaEnginePlugin.kt` — Method/Event channels.
- `android/src/main/cpp/llama_engine_jni.cpp` — the JNI bridge.
- `android/src/main/cpp/CMakeLists.txt` — builds `llama.cpp` (CPU-only, arm64).
- `llama.cpp/` — git submodule, the C++ inference engine compiled by CMake/NDK.

**Update the llama.cpp submodule**
```bash
cd local_packages/llama_engine/llama.cpp
git fetch --depth=1 origin master && git checkout FETCH_HEAD
cd ../../..
git add local_packages/llama_engine/llama.cpp
git commit -m "chore: update llama.cpp submodule"
```
