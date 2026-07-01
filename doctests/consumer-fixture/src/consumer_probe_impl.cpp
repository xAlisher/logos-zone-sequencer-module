#include "consumer_probe_impl.h"
#include "logos_sdk.h"   // generated: defines modules().zone_sequencer

StdLogosResult ZoneSeqConsumerProbeImpl::probe_channel_id(const std::string& signingKeyHex) {
    // Single typed cross-module call — NO getClient, no cross-call state.
    return modules().zone_sequencer.derive_channel_id(signingKeyHex);
}

StdLogosResult ZoneSeqConsumerProbeImpl::probe_echo(const std::string& s) {
    // Single typed cross-module call, no FFI, no getClient — proves modules() IPC.
    return modules().zone_sequencer.echo_arg(s);
}
