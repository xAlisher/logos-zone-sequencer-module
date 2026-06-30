#!/usr/bin/env bash
# Headless in-process test: build the module (for headers + rust .so), then compile+run.
set -euo pipefail
cd "$(dirname "$0")/.."
nix build .#default -o result
SDK=$(find /nix/store -maxdepth 3 -name logos_module_context.h 2>/dev/null | head -1 | xargs dirname)
NJ=$(find /nix/store -maxdepth 4 -path '*nlohmann_json*/include/nlohmann/json.hpp' 2>/dev/null | head -1 | sed 's#/nlohmann/json.hpp##')
RSLIB=$(dirname "$(find -L result -name libzone_sequencer_rs.so | head -1)")
g++ -std=c++20 -I"$SDK" -I"$NJ" -Isrc tests/inproc_test.cpp src/zone_sequencer_impl.cpp \
    -L"$RSLIB" -lzone_sequencer_rs -Wl,-rpath,"$RSLIB" -o /tmp/zs_inproc
/tmp/zs_inproc
