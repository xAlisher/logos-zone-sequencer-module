#pragma once
#include <string>
#include <logos_module_context.h>
#include <logos_result.h>

// Proves the modernized typed contract is consumable with ZERO hand-written getClient:
// every cross-module call goes through the generated modules().zone_sequencer wrapper.
class ZoneSeqConsumerProbeImpl : public LogosModuleContext {
public:
    // Derive the sequencer's channel id for a key — purely to exercise the typed call.
    StdLogosResult probe_channel_id(const std::string& signingKeyHex);
    // FFI-free proof of the cross-module round-trip: forwards to zone_sequencer.echo_arg.
    StdLogosResult probe_echo(const std::string& s);
    std::string name() const { return "zone_seq_consumer_probe"; }
    std::string version() const { return "0.1.0"; }
};
