find_package(tomlplusplus QUIET)
if(NOT tomlplusplus_FOUND)
    include(FetchContent)

    message(STATUS "tomlplusplus not found, fetching from https://github.com/marzer/tomlplusplus")
    FetchContent_Declare(tomlplusplus
        GIT_REPOSITORY https://github.com/marzer/tomlplusplus.git
        GIT_TAG v3.4.0
    )

    # FIXME: The shared library flag for LLVM may be passed here. Shall we build toml++ as shared
    #        libraries for Linux and macOS?
    set(BUILD_SHARED_LIBS OFF CACHE INTERNAL "")

    FetchContent_MakeAvailable(tomlplusplus)
endif()
