cmake_minimum_required(VERSION 3.14)
project(ZoneSeqUiProbe LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(DEFINED ENV{LOGOS_MODULE_BUILDER_ROOT})
    include($ENV{LOGOS_MODULE_BUILDER_ROOT}/cmake/LogosModule.cmake)
else()
    message(FATAL_ERROR "LogosModule.cmake not found")
endif()

# Universal UI module: REP_FILE runs repc on probe.rep; the generated *Plugin
# glue + logos_sdk.h (from metadata.json#dependencies) are compiled in.
logos_module(
    NAME zone_seq_ui_probe
    REP_FILE src/probe.rep
    SOURCES
        src/zone_seq_ui_probe_backend.h
        src/zone_seq_ui_probe_backend.cpp
    INCLUDE_DIRS
        src
)
