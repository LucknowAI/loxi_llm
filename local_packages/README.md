# local_packages

Vendored copies of pub.dev packages that require patches not upstreamed yet.
Each package is referenced via `dependency_overrides` in `pubspec.yaml`.

After cloning the repo, initialize submodules:

```bash
git submodule update --init --recursive
```

---

## flutter_llama (v1.1.2)

**Source:** https://pub.dev/packages/flutter_llama/versions/1.1.2
**Why vendored:** The published package excludes the `llama.cpp` C++ source
(trimmed via `.pubignore` to reduce package size from 234 MB to 20 MB), which
breaks Android builds that compile llama.cpp from source via CMake/NDK.

### Patches applied

| File | Change | Reason |
|------|--------|--------|
| `android/build.gradle` | CMake `3.18.1` → `3.22.1` | NDK 27 warns CMake <3.19 is too old for compiler auto-detection; 3.22.1 is the installed version |
| `android/src/main/cpp/CMakeLists.txt` | Vulkan/OpenCL disabled → CPU+NEON | `vulkan.hpp` C++ header is not bundled in the Android NDK (only the C header `vulkan.h` is); disabling avoids a fatal compile error |

### llama.cpp submodule

`llama.cpp/` is a shallow git submodule pointing to `ggml-org/llama.cpp` master.
It is the C++ inference engine compiled by CMake during the Android build.

To update to a newer llama.cpp commit:
```bash
cd local_packages/flutter_llama/llama.cpp
git fetch --depth=1 origin master
git checkout FETCH_HEAD
cd ../../..
git add local_packages/flutter_llama/llama.cpp
git commit -m "chore: update llama.cpp submodule"
```

### Upstream status

- CMake version issue: https://github.com/nativemind/flutter_llama/issues (report pending)
- Vulkan C++ headers issue: tied to NDK shipping `vulkan.hpp` — track NDK release notes
- llama.cpp missing from pub: known limitation of the package; no upstream fix yet
