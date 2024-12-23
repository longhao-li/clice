# find libuv
find_path(LIBUV_INCLUDE_DIR NAMES uv.h)
find_library(LIBUV_LIBRARIES NAMES uv libuv)

find_package_handle_standard_args(LIBUV
    REQUIRED_VARS LIBUV_LIBRARIES LIBUV_INCLUDE_DIR
)

# hide internal variables
mark_as_advanced(LIBUV_INCLUDE_DIR LIBUV_LIBRARIES)

if(LIBUV_FOUND)
    # add a dummy target to make it easier to link against libuv
    add_library(libuv INTERFACE IMPORTED GLOBAL)
    add_library(libuv::libuv ALIAS libuv)

    target_include_directories(libuv INTERFACE ${LIBUV_INCLUDE_DIR})
    target_link_libraries(libuv INTERFACE ${LIBUV_LIBRARIES})
else()
    message(STATUS "libuv not found, fetching from https://github.com/libuv/libuv")
    FetchContent_Declare(libuv
        GIT_REPOSITORY https://github.com/libuv/libuv.git
        GIT_TAG v1.49.2
    )

    # libuv build options
    set(LIBUV_BUILD_SHARED OFF CACHE INTERNAL "")
    set(LIBUV_BUILD_TESTS OFF CACHE INTERNAL "")
    set(LIBUV_BUILD_BENCH OFF CACHE INTERNAL "")

    FetchContent_MakeAvailable(libuv)
endif()
