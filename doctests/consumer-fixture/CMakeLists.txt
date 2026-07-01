cmake_minimum_required(VERSION 3.14)
project(ZoneSeqConsumerProbe LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(DEFINED ENV{LOGOS_MODULE_BUILDER_ROOT})
    include($ENV{LOGOS_MODULE_BUILDER_ROOT}/cmake/LogosModule.cmake)
else()
    message(FATAL_ERROR "LogosModule.cmake not found")
endif()
logos_module(
    NAME zone_seq_consumer_probe
    SOURCES src/consumer_probe_impl.h src/consumer_probe_impl.cpp
)
