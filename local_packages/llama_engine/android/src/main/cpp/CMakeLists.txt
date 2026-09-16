cmake_minimum_required(VERSION 3.22.1)
project(llama_engine)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Vendored llama.cpp (MIT) submodule. This file lives at
# android/src/main/cpp, so the plugin root (with llama.cpp/) is four levels up.
set(LLAMA_CPP_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../../llama.cpp)

# Build only the libraries we need, cross-compile safe, CPU-only.
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
set(LLAMA_CURL OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)        # NDK cannot link OpenMP
set(GGML_LLAMAFILE OFF CACHE BOOL "" FORCE)     # x86 asm incompatible with ARM
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)         # no host-CPU probing when cross-compiling
set(GGML_AMX OFF CACHE BOOL "" FORCE)
set(GGML_VULKAN OFF CACHE BOOL "" FORCE)
set(GGML_OPENCL OFF CACHE BOOL "" FORCE)

add_subdirectory(${LLAMA_CPP_DIR} build-llama)

# tools/mtmd is added directly (not via LLAMA_BUILD_TOOLS, which would pull in
# llama.cpp's entire tools/ directory — benchmarks, quantize CLI, etc. — none
# of which we want in a mobile build). It expects LLAMA_INSTALL_VERSION from
# the root CMakeLists.txt's own scope, which a sibling add_subdirectory call
# doesn't inherit, so it's set here as a harmless placeholder (we never run
# install() targets in an Android Gradle/CMake build).
set(LLAMA_INSTALL_VERSION 0.0.0)
add_subdirectory(${LLAMA_CPP_DIR}/tools/mtmd build-mtmd)

add_library(llama_engine_jni SHARED llama_engine_jni.cpp)

target_include_directories(llama_engine_jni PRIVATE
    ${LLAMA_CPP_DIR}/include
    ${LLAMA_CPP_DIR}/ggml/include
    ${LLAMA_CPP_DIR}/tools/mtmd
)

find_library(log-lib log)

target_link_libraries(llama_engine_jni
    llama
    mtmd
    ${log-lib}
)

# Android 15 / 16 KB page size support (required for API 35 targets).
target_link_options(llama_engine_jni PRIVATE "-Wl,-z,max-page-size=16384")
