#include "zone_sequencer_impl.h"
#include "zone_sequencer.h"   // zone-sequencer-rs C-FFI

#include <chrono>
#include <thread>

namespace {
// RAII for the heap strings the Rust FFI returns (freed via zone_free_string).
struct OwnedCStr {
    char* p;
    explicit OwnedCStr(char* s) : p(s) {}
    ~OwnedCStr() { if (p) zone_free_string(p); }
    bool ok() const { return p != nullptr; }
    std::string str() const { return p ? std::string(p) : std::string(); }
};
}

int64_t ZoneSequencerImpl::nowMs() {
    using namespace std::chrono;
    return duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
}

ZoneSequencerImpl::ZoneSequencerImpl() = default;

ZoneSequencerImpl::~ZoneSequencerImpl() {
    std::lock_guard<std::mutex> lk(m_mtx);
    if (m_sequencerHandle) {
        zone_sequencer_destroy(m_sequencerHandle);
        m_sequencerHandle = nullptr;
    }
}

StdLogosResult ZoneSequencerImpl::set_node_url(const std::string& url) {
    m_nodeUrl = url;
    tryCreateSequencer();
    return {true, "ok"};
}
StdLogosResult ZoneSequencerImpl::set_signing_key(const std::string& hex) {
    m_signingKey = hex;
    tryCreateSequencer();
    return {true, "ok"};
}
StdLogosResult ZoneSequencerImpl::set_checkpoint_path(const std::string& path) {
    m_checkpointPath = path;
    tryCreateSequencer();
    return {true, "ok"};
}
StdLogosResult ZoneSequencerImpl::set_channel_id(const std::string& channelIdHex) {
    m_channelId = channelIdHex;
    tryCreateSequencer();
    return {true, "ok"};
}

StdLogosResult ZoneSequencerImpl::get_channel_id() {
    if (!m_channelId.empty()) return {true, m_channelId};
    if (m_signingKey.empty()) return {false, {}, "signing key not set"};
    OwnedCStr r(zone_derive_channel_id(m_signingKey.c_str()));
    if (!r.ok()) return {false, {}, "zone_derive_channel_id returned null"};
    return {true, r.str()};
}

StdLogosResult ZoneSequencerImpl::echo_arg(const std::string& s) {
    return {true, std::string("echo:") + s};
}

StdLogosResult ZoneSequencerImpl::derive_channel_id(const std::string& signingKeyHex) {
    if (signingKeyHex.empty()) return {false, {}, "empty signing key"};
    OwnedCStr r(zone_derive_channel_id(signingKeyHex.c_str()));
    if (!r.ok()) return {false, {}, "zone_derive_channel_id returned null"};
    return {true, r.str()};
}

void ZoneSequencerImpl::tryCreateSequencer() {
    {
        std::lock_guard<std::mutex> lk(m_mtx);
        if (m_sequencerHandle) return;
    }
    if (m_creating.exchange(true)) return;  // already creating
    if (m_nodeUrl.empty() || m_signingKey.empty() || m_channelId.empty()) {
        m_creating = false;
        return;
    }
    // Bootstrap off the IPC thread: zone_sequencer_create blocks while it
    // backfills last_msg_id from the chain. Emit sequencerReady when live.
    const std::string url = m_nodeUrl, ch = m_channelId, key = m_signingKey, cp = m_checkpointPath;
    std::thread([this, url, ch, key, cp]() {
        void* handle = zone_sequencer_create(url.c_str(), ch.c_str(), key.c_str(), cp.c_str());
        {
            std::lock_guard<std::mutex> lk(m_mtx);
            m_sequencerHandle = handle;
        }
        m_creating = false;
        if (handle) sequencerReady(ch, nowMs());
    }).detach();
}

StdLogosResult ZoneSequencerImpl::publish(const std::string& data) {
    void* handle;
    { std::lock_guard<std::mutex> lk(m_mtx); handle = m_sequencerHandle; }
    if (!handle) {
        return {false, {}, m_creating ? "sequencer still initializing, try again shortly"
                                      : "sequencer not initialized (set node_url + signing_key + channel_id)"};
    }
    OwnedCStr r(zone_sequencer_publish(handle, data.c_str()));
    if (!r.ok()) return {false, {}, "zone_sequencer_publish returned null"};
    const std::string txHash = r.str();
    publishResult(m_channelId, txHash, nowMs());
    return {true, txHash};
}

StdLogosResult ZoneSequencerImpl::publish_to(const std::string& channelId,
                                             const std::string& signingKeyHex,
                                             const std::string& checkpointPath,
                                             const std::string& data) {
    if (channelId.empty() || signingKeyHex.empty())
        return {false, {}, "publish_to requires channelId and signingKeyHex"};
    OwnedCStr r(zone_publish(m_nodeUrl.c_str(), channelId.c_str(), signingKeyHex.c_str(),
                             data.c_str(), checkpointPath.c_str()));
    if (!r.ok()) return {false, {}, "zone_publish returned null"};
    const std::string txHash = r.str();
    publishResult(channelId, txHash, nowMs());
    return {true, txHash};
}

StdLogosResult ZoneSequencerImpl::query_channel(const std::string& channelId, int64_t limit) {
    OwnedCStr r(zone_query_channel(m_nodeUrl.c_str(), channelId.c_str(), static_cast<int>(limit)));
    if (!r.ok()) return {false, {}, "zone_query_channel returned null"};
    const std::string items = r.str();
    scanResult(channelId, items, nowMs());
    return {true, nlohmann::json::parse(items, nullptr, false)};
}

StdLogosResult ZoneSequencerImpl::query_channel_paged(const std::string& channelId,
                                                      const std::string& cursorJson,
                                                      int64_t limit) {
    OwnedCStr r(zone_query_channel_paged(m_nodeUrl.c_str(), channelId.c_str(),
                                         cursorJson.empty() ? nullptr : cursorJson.c_str(),
                                         static_cast<int>(limit)));
    if (!r.ok()) return {false, {}, "zone_query_channel_paged returned null"};
    return {true, nlohmann::json::parse(r.str(), nullptr, false)};
}
