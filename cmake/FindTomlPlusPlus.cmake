find_package(tomlplusplus QUIET)
if(NOT tomlplusplus_FOUND)
    message(STATUS "tomlplusplus not found, fetching from https://github.com/marzer/tomlplusplus")

    FetchContent_Declare(tomlplusplus
        GIT_REPOSITORY https://github.com/marzer/tomlplusplus.git
        GIT_TAG v3.4.0
    )

    FetchContent_MakeAvailable(tomlplusplus)
endif()
