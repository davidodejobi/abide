cmake_minimum_required(VERSION 3.18)
project(lumway_whisper C CXX)

# whisper.cpp v1.7.6 (commit a8d002c, MIT, see whisper.cpp/LICENSE), CPU only.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_LLAMAFILE OFF CACHE BOOL "" FORCE)
add_subdirectory(whisper.cpp)

add_library(lumway_whisper SHARED whisper_jni.cpp)
target_include_directories(lumway_whisper PRIVATE whisper.cpp/include whisper.cpp/ggml/include)
target_link_libraries(lumway_whisper whisper log)
# 16 KB page-size devices.
target_link_options(lumway_whisper PRIVATE -Wl,-z,max-page-size=16384)
