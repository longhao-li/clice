find_package(GTest QUIET)
if(NOT GTest_FOUND)
    message(STATUS "GoogleTest not found, fetching from https://github.com/google/googletest")

    # Google suggests using main branch for the latest version
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
