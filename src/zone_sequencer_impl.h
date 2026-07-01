#pragma once

#include <atomic>
#include <cstdint>
#include <mutex>
#include <string>

#include <logos_module_context.h>
#include <logos_result.h>

/**
 * @brief Universal (Qt-free) zone-sequencer module — modern LogosModuleContext form.
 *
 * Adapts the zone-sequencer-rs C-FFI (see zone_sequencer.h) to the universal
 * module API so consumers call us via the typed `modules().zone_sequencer.*`
 * wrapper (logos-cpp-generator) — no hand-written getClient anywhere. This is a
 * pure FFI *provider*: it never calls another module, so it holds no LogosAPI
 * client and is unaffected by the getClient ABI fragility.
 *
 * Persistent path: set_node_url/set_signing_key/set_channel_id bootstrap a
 * background sequencer (zone_sequencer_create, async); `sequencerReady` fires
 * when it is live; `publish()` then routes through it. Stateless path:
 * `publish_to()` is one-shot (zone_publish). Reads: query_channel[_paged].
 */
class ZoneSequencerImpl : public LogosModuleContext
{
public:
    ZoneSequencerImpl();
    ~ZoneSequencerImpl();

    // ── config (persistent path) ─────────────────────────────────────────────
    StdLogosResult set_node_url(const std::string& url);
    StdLogosResult set_signing_key(const std::string& hex);
    StdLogosResult set_checkpoint_path(const std::string& path);
    StdLogosResult set_channel_id(const std::string& channelIdHex);

    /// Derive the 64-hex channel id from the configured signing key (no node).
    StdLogosResult get_channel_id();

    /// Diagnostic: echo a string arg (no FFI) to isolate dispatch from the Rust FFI.
    StdLogosResult echo_arg(const std::string& s);

    /// Stateless derive: 64-hex channel id from the given key in one call (no node,
    /// no prior config). Robust under logoscore's per-call instance model.
    StdLogosResult derive_channel_id(const std::string& signingKeyHex);

    // ── publish ──────────────────────────────────────────────────────────────
    /// Publish via the persistent sequencer. Emits `publishResult` on success.
    StdLogosResult publish(const std::string& data);
    /// One-shot publish to an arbitrary channel (stateless).
    StdLogosResult publish_to(const std::string& channelId,
                              const std::string& signingKeyHex,
                              const std::string& checkpointPath,
                              const std::string& data);

    // ── read ─────────────────────────────────────────────────────────────────
    StdLogosResult query_channel(const std::string& channelId, int64_t limit);
    StdLogosResult query_channel_paged(const std::string& channelId,
                                       const std::string& cursorJson,
                                       int64_t limit);

    std::string name() const { return "zone_sequencer"; }
    std::string version() const { return "0.2.0"; }

logos_events:
    /// Persistent sequencer finished cold-start and is ready to publish.
    void sequencerReady(const std::string& channelId, int64_t timestamp);
    /// An inscription was accepted. txHash is the 64-hex inscription id.
    void publishResult(const std::string& channelId, const std::string& txHash, int64_t timestamp);
    /// A channel scan completed. items is a JSON array string.
    void scanResult(const std::string& channelId, const std::string& items, int64_t timestamp);

private:
    void tryCreateSequencer();
    static int64_t nowMs();

    std::string m_nodeUrl = "http://localhost:8080";
    std::string m_signingKey;
    std::string m_checkpointPath;
    std::string m_channelId;

    std::mutex  m_mtx;
    void*       m_sequencerHandle = nullptr;
    std::atomic<bool> m_creating{false};
};
