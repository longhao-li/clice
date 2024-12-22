cmake_minimum_required(VERSION 3.22)

project(CLICE_PROJECT VERSION 0.1.0 LANGUAGES CXX)

include(FetchContent)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(CheckCXXCompilerFlag)

# CMake policy CMP0135 controls extraction behavior of the FetchContent module.
if(POLICY CMP0135)
	cmake_policy(SET CMP0135 NEW)
	set(CMAKE_POLICY_DEFAULT_CMP0135 NEW)
endif()

# build options
option(CLICE_BUILD_SHARED_LIBS "Build clice core library as shared library" ON)
option(CLICE_ENABLE_ASAN "Enable address sanitizer for clice core library" OFF)
option(CLICE_ENABLE_TEST "Build clice unit tests" OFF)

# find LLVM and clang
include(cmake/FindLLVM.cmake)
message(STATUS "Found LLVM: ${LLVM_DIR}, Version: ${LLVM_PACKAGE_VERSION}")

# build clice core part as library
file(GLOB_RECURSE CLICE_CORE_SOURCES
    "${CMAKE_SOURCE_DIR}/src/Basic/*.cpp" 
    "${CMAKE_SOURCE_DIR}/src/Compiler/*.cpp" 
    "${CMAKE_SOURCE_DIR}/src/Index/*.cpp" 
    "${CMAKE_SOURCE_DIR}/src/Feature/*.cpp" 
    "${CMAKE_SOURCE_DIR}/src/Support/*.cpp"
)

if(CLICE_BUILD_SHARED_LIBS)
    add_library(clice-core SHARED ${CLICE_LIB_TYPE} ${CLICE_CORE_SOURCES})
else()
    add_library(clice-core STATIC ${CLICE_LIB_TYPE} ${CLICE_CORE_SOURCES})
endif()
add_library(clice::core ALIAS clice-core)

# enable c++23 features for clice-core
target_compile_features(clice-core PUBLIC cxx_std_23)

# use pre-compiled headers to speed up compilation
target_precompile_headers(clice-core PRIVATE 
    "${CMAKE_SOURCE_DIR}/include/Compiler/Clang.h"
)

# include directories for clice-core
target_include_directories(clice-core PUBLIC
    ${LLVM_INCLUDE_DIRS}
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# compile options for clice-core
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
    # disable RTTI and exceptions
    target_compile_options(clice-core PUBLIC "-fno-rtti" "-fno-exceptions")

    # enable address sanitizer if supported
    if(CLICE_ENABLE_ASAN)
        check_cxx_compiler_flag("-fsanitize=address" HAS_ASAN)
        if(NOT HAS_ASAN)
            message(WARNING "Address sanitizer is required but not supported by the compiler")
        endif()

        target_compile_options(clice-core PRIVATE "-fsanitize=address")
    endif()
endif()

target_link_libraries(clice-core PUBLIC
    ${LLVM_LIBS}
)

# clice executable
set(CLICE_SERVER_SOURCES ${CMAKE_SOURCE_DIR}/src/main.cpp)
file(GLOB_RECURSE SRC_FILES "${CMAKE_SOURCE_DIR}/src/Server/*.cpp")
list(APPEND CLICE_SERVER_SOURCES ${SRC_FILES})
add_executable(clice ${CLICE_SERVER_SOURCES})

# include directories for clice executable
target_include_directories(clice PRIVATE
    "${CMAKE_SOURCE_DIR}/include"
)

include(cmake/FindLibUV.cmake)
include(cmake/FindTomlPlusPlus.cmake)

# link external libraries
# c++23 is automatically enabled due to clice-core feature requirements
target_link_libraries(clice PRIVATE
    clice-core
    libuv::libuv
    tomlplusplus::tomlplusplus
)

# clice tests
if(CLICE_ENABLE_TEST)
    enable_testing()

    # build unit tests
    set(CLICE_TEST_SOURCES ${CMAKE_SOURCE_DIR}/unittests/main.cpp)
    file(GLOB_RECURSE TEST_SRC_FILES "${CMAKE_SOURCE_DIR}/unittests/*/*.cpp")
    list(APPEND CLICE_TEST_SOURCES ${TEST_SRC_FILES})

    add_executable(clice-tests ${CLICE_TEST_SOURCES} ${SRC_FILES})

    # find googletest
    find_package(GTest QUIET)
    if(NOT GTest_FOUND)
        message(STATUS "GoogleTest not found, fetching from https://github.com/google/googletest")

        # Google suggests using main branch for the latest version
        FetchContent_Declare(
            googletest
            URL https://github.com/google/googletest/archive/refs/heads/main.zip
        )

        set(BUILD_GMOCK OFF CACHE INTERNAL "")
        set(INSTALL_GTEST OFF CACHE INTERNAL "")
        set(GTEST_HAS_ABSL OFF CACHE INTERNAL "")

        FetchContent_MakeAvailable(googletest)
    endif()

    target_link_libraries(clice-tests PRIVATE 
        clice-core
        GTest::gtest_main
        libuv::libuv
    )

    # enable gtest discovery
    include(GoogleTest)
    gtest_discover_tests(clice-tests)
endif()

# config clice package
install(TARGETS clice
    EXPORT clice-targets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(EXPORT clice-targets
    FILE clice-targets.cmake
    NAMESPACE clice::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/clice
)

# generate clice-config.cmake
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/clice-config.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/clice-config.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/clice
)

write_basic_package_version_file(
    clice-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

# install clice-config.cmake and clice-config-version.cmake
install(FILES
    ${CMAKE_SOURCE_DIR}/clice-config.cmake
    ${CMAKE_BINARY_DIR}/clice-config-version.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/clice
)

# install header files
install(
    DIRECTORY ${CMAKE_SOURCE_DIR}/include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/clice
)
