// Headless in-process test for the universal ZoneSequencerImpl.
// Verifies the pure (node-free) path: deterministic 64-hex channel-id derivation.
// Event bodies are normally codegen-generated (<name>_events.cpp); stubbed here.
#include "zone_sequencer_impl.h"
#include <cassert>
#include <cstdio>
#include <string>

void ZoneSequencerImpl::sequencerReady(const std::string&, int64_t) {}
void ZoneSequencerImpl::publishResult(const std::string&, const std::string&, int64_t) {}
void ZoneSequencerImpl::scanResult(const std::string&, const std::string&, int64_t) {}

int main() {
    const std::string key = "0000000000000000000000000000000000000000000000000000000000000001";
    ZoneSequencerImpl m;
    assert(!m.get_channel_id().success && "no key -> error");
    m.set_signing_key(key);
    auto r = m.get_channel_id();
    assert(r.success && "derive ok");
    std::string ch = r.value.get<std::string>();
    assert(ch.size() == 64 && "32-byte hex");
    for (char c : ch) assert(std::isxdigit((unsigned char)c));
    ZoneSequencerImpl m2; m2.set_signing_key(key);
    assert(m2.get_channel_id().value.get<std::string>() == ch && "deterministic");
    std::printf("PASS inproc: get_channel_id deterministic 64-hex = %s\n", ch.c_str());
    return 0;
}
