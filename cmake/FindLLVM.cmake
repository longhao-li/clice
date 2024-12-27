# FIXME: find_package(Clang) is not used here. Because there is a problem with ClangConfig.cmake.
#        It requires LLVM with find_package which causes fatal error when LLVM is not found, but
#        I hope that cmake could fetch the required libraries if not found.
find_package(LLVM QUIET CONFIG)
if(NOT LLVM_FOUND)
    include(FetchContent)

    message(STATUS "LLVM not found, fetching from https://github.com/llvm/llvm-project")
    FetchContent_Declare(LLVM
        GIT_REPOSITORY https://github.com/llvm/llvm-project.git
        GIT_TAG llvmorg-19.1.6
        SOURCE_SUBDIR llvm
    )

    # NOTE: There are some non-ASCII UTF-8 characters in LLVM source files, so this flag is
    #       required for MSVC. But this flag adds /utf-8 flag to all targets. Seems like that it is
    #       OK to add this flag to all targets for now.
    if(MSVC)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /utf-8" CACHE INTERNAL "")
    endif()

    # Build LLVM as shared libraries for Linux and macOS. MSVC toolchain does not support shared
    # libraries, so we need to build static libraries for Windows.
    if(CMAKE_SYSTEM_NAME MATCHES "Linux|Darwin")
        set(BUILD_SHARED_LIBS ON CACHE INTERNAL "")
    endif()

    set(LLVM_BUILD_TOOLS OFF CACHE INTERNAL "")
    set(LLVM_BUILD_TESTS OFF CACHE INTERNAL "")
    set(LLVM_ENABLE_PROJECTS "clang" CACHE INTERNAL "")
    set(LLVM_ENABLE_ZLIB OFF CACHE INTERNAL "")
    set(LLVM_ENABLE_ZSTD OFF CACHE INTERNAL "")
    set(LLVM_INCLUDE_EXAMPLES OFF CACHE INTERNAL "")

    FetchContent_MakeAvailable(LLVM)

    # LLVM and clang is using private include directories, so we need to add them manually
    # FIXME: Maybe we should use LLVMConfig.cmake to create executable targets instead?
    #        Is there a better way to do this?
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
