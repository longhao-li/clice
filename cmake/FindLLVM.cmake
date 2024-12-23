# FIXME: find libclang.
find_package(LLVM QUIET CONFIG)
if(NOT LLVM_FOUND)
    message(STATUS "LLVM not found, fetching from https://github.com/llvm/llvm-project")
    FetchContent_Declare(LLVM
        GIT_REPOSITORY https://github.com/llvm/llvm-project.git
        GIT_TAG llvmorg-19.1.6
        SOURCE_SUBDIR llvm
    )

    set(LLVM_BUILD_TOOLS OFF CACHE INTERNAL "")
    set(LLVM_BUILD_TESTS OFF CACHE INTERNAL "")
    set(LLVM_ENABLE_PROJECTS "clang" CACHE INTERNAL "")
    set(LLVM_ENABLE_ZLIB OFF CACHE INTERNAL "")
    set(LLVM_ENABLE_ZSTD OFF CACHE INTERNAL "")
    set(LLVM_INCLUDE_EXAMPLES OFF CACHE INTERNAL "")

    FetchContent_MakeAvailable(LLVM)

    message("LLVM source dir: ${LLVM_DIR}")
    message("LLVM binary dir: ${LLVM_BINARY_DIR}")

    # LLVM and clang is using private include directories, so we need to add them manually
    # FIXME: maybe we should use LLVMConfig.cmake to create executable targets instead?s
    # FIXME: is there a better way to do this?
    set(CLANG_SOURCE_DIR ${LLVM_SOURCE_DIR}/../clang)
    set(CLANG_BINARY_DIR ${LLVM_BINARY_DIR}/tools/clang)

    set(LLVM_INCLUDE_DIRS
        ${LLVM_SOURCE_DIR}/include
        ${LLVM_BINARY_DIR}/include
        ${CLANG_SOURCE_DIR}/include
        ${CLANG_BINARY_DIR}/include
    )

    set(LLVM_LIBS LLVMSupport LLVMFrontendOpenMP)
else()
    message(LLVM found: ${LLVM_DIR})
    llvm_map_components_to_libnames(LLVM_LIBS Core Support FrontendOpenMP)
endif()

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
