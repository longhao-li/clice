# FIXME: find libclang.
find_package(LLVM QUIET CONFIG)
if(NOT LLVM_FOUND)
    message(STATUS "LLVM not found, fetching from https://github.com/llvm/llvm-project")
    FetchContent_Declare(LLVM
        URL https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-19.1.6.zip
    )

    set(LLVM_BUILD_TOOLS OFF CACHE INTERNAL "")
    set(LLVM_ENABLE_PROJECTS "clang;openmp" CACHE INTERNAL "")
    set(LLVM_ENABLE_ZLIB OFF CACHE INTERNAL "")
    set(LLVM_ENABLE_ZSTD OFF CACHE INTERNAL "")

    FetchContent_MakeAvailable(LLVM)
endif()

llvm_map_components_to_libnames(LLVM_LIBS Core Support FrontendOpenMP)

list(APPEND LLVM_LIBS
    clangAST
    clangASTMatchers
    clangBasic
    clangDependencyScanning
    clangDriver
    clangFormat
    clangFrontend
    clangIndex
    clangLex
    clangSema
    clangSerialization
    clangTooling
    clangToolingCore
    clangToolingInclusions
    clangToolingInclusionsStdlib
    clangToolingSyntax
)
