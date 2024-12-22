# find libuv
message(STATUS "fetching libuv from https://github.com/libuv/libuv")
FetchContent_Declare(libuv
    URL https://github.com/libuv/libuv/archive/refs/tags/v1.49.2.zip
)

# libuv build options
set(LIBUV_BUILD_SHARED OFF CACHE INTERNAL "")
set(LIBUV_BUILD_TESTS OFF CACHE INTERNAL "")
set(LIBUV_BUILD_BENCH OFF CACHE INTERNAL "")

FetchContent_MakeAvailable(libuv)
