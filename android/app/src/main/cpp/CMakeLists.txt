cmake_minimum_required(VERSION 3.22.1)

project(sandboxy VERSION 1.0.0)

# Add source files
set(SOURCES
    sandboxy_jni.cpp
)

# Create shared library
add_library(sandboxy SHARED ${SOURCES})

# Include directories
target_include_directories(sandboxy PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../../src
)

# Link libraries
target_link_libraries(sandboxy
    android
    log
    EGL
    GLESv2
)