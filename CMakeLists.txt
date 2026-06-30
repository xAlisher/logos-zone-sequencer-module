cmake_minimum_required(VERSION 3.14)
project(ZoneSequencerModulePlugin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Logos Module CMake helper (provided by logos-module-builder)
if(DEFINED ENV{LOGOS_MODULE_BUILDER_ROOT})
    include($ENV{LOGOS_MODULE_BUILDER_ROOT}/cmake/LogosModule.cmake)
elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/LogosModule.cmake")
    include(cmake/LogosModule.cmake)
else()
    message(FATAL_ERROR "LogosModule.cmake not found. Set LOGOS_MODULE_BUILDER_ROOT.")
endif()

logos_module(
    NAME zone_sequencer
    SOURCES
        src/zone_sequencer_impl.h
        src/zone_sequencer_impl.cpp
    EXTERNAL_LIBS
        zone_sequencer_rs
    INCLUDE_DIRS
        src
)
