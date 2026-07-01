#pragma once

#include "rep_probe_source.h"        // generated from src/probe.rep (repc)
#include "logos_ui_plugin_context.h" // modules() + onContextReady()

/**
 * @brief zone_seq_ui_probe UI backend (universal authoring model, mirrors shop).
 *
 * Derives:
 *   - ZoneSeqUiProbeSimpleSource — generated from probe.rep; implement its SLOTs
 *     and feed its PROPs (setStatus/setReady), auto-synced to every QML replica.
 *   - LogosUiPluginContext — modules() typed callers for declared dependencies
 *     (here: zone_sequencer) + onContextReady() lifecycle.
 *
 * Purpose: prove headlessly that a Qt/UI backend can reach the Qt-free universal
 * zone_sequencer via modules().zone_sequencer.* — the pattern beacon must adopt.
 */
class ZoneSeqUiProbeBackend : public ZoneSeqUiProbeSimpleSource,
                              public LogosUiPluginContext
{
public:
    QString deriveChannelId(QString signingKeyHex) override;
    QString echoArg(QString s) override;
    QString ping() override;

protected:
    void onContextReady() override { setReady(true); }
};
