cmake_minimum_required(VERSION 3.16)
project(my-project VERSION $ENV{SQLITE_CMAKE_VERSION})
set(CMAKE_CXX_STANDARD 11)
set(SQLITE_ROT13_VERSION "v${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")
configure_file(src/rot13.h.in rot13.h)

include(ExternalProject)

ExternalProject_Add(
    sqlite_external
    PREFIX ${CMAKE_BINARY_DIR}/vendor/sqlite
    SOURCE_DIR ${CMAKE_SOURCE_DIR}/vendor/sqlite
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E chdir <SOURCE_DIR> ./configure --enable-all
    BUILD_COMMAND ${CMAKE_COMMAND} -E chdir <SOURCE_DIR> ${CMAKE_MAKE_PROGRAM} sqlite3.c
    INSTALL_COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/src <SOURCE_DIR>/ext/wasm
)

include_directories(vendor/sqlite)
link_directories(BEFORE vendor/sqlite)

# Shared
add_library(rot13 SHARED src/rot13.c)
target_link_libraries(rot13 sqlite3)
target_include_directories(rot13 PUBLIC "${PROJECT_BINARY_DIR}")
set_target_properties(rot13 PROPERTIES PREFIX "")
set_target_properties(rot13 PROPERTIES OUTPUT_NAME "rot13")

# Static
add_library(rot13-static STATIC src/rot13.c)
target_link_libraries(rot13-static sqlite3)
target_include_directories(rot13-static PUBLIC "${PROJECT_BINARY_DIR}")
set_target_properties(rot13-static PROPERTIES OUTPUT_NAME "sqlite_rot13")

# WASM
file(COPY ${CMAKE_CURRENT_BINARY_DIR}/rot13.h
     DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/vendor/sqlite/ext/wasm)
     
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_custom_target(
        wasm
        COMMAND make release
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/vendor/sqlite/ext/wasm
    )
else()
    add_custom_target(
        wasm
        COMMAND ${CMAKE_MAKE_PROGRAM}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/vendor/sqlite/ext/wasm
    )
endif()

add_custom_command(
    TARGET wasm
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_CURRENT_SOURCE_DIR}/vendor/sqlite/ext/wasm
        ${CMAKE_CURRENT_BINARY_DIR}/wasm
    COMMENT "Copying build artifacts to ${CMAKE_CURRENT_BINARY_DIR}/wasm"
)