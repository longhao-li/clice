find_package(GTest QUIET)
if(NOT GTest_FOUND)
    include(FetchContent)

    # CMake policy CMP0135 controls extraction behavior of the FetchContent module.
    if(POLICY CMP0135)
        cmake_policy(SET CMP0135 NEW)
        set(CMAKE_POLICY_DEFAULT_CMP0135 NEW)
    endif()

    # Google suggests using main branch for the latest version
    message(STATUS "GoogleTest not found, fetching from https://github.com/google/googletest")
    FetchContent_Declare(googletest
        URL https://github.com/google/googletest/archive/refs/heads/main.zip
        FIND_PACKAGE_ARGS NAMES GTest
    )

    set(INSTALL_GTEST OFF CACHE INTERNAL "")
    set(GTEST_HAS_ABSL OFF CACHE INTERNAL "")

    if(WIN32)
        set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    endif()

    FetchContent_MakeAvailable(googletest)
endif()
