#include "zone_seq_ui_probe_backend.h"

#include "logos_sdk.h"   // generated: defines modules().zone_sequencer (Qt-typed)

QString ZoneSeqUiProbeBackend::deriveChannelId(QString signingKeyHex)
{
    if (!isContextReady())
        return QStringLiteral("error: context not ready");
    // Qt-typed cross-module call into the universal module — NO getClient.
    LogosResult r = modules().zone_sequencer.derive_channel_id(signingKeyHex);
    if (!r.success)
        return QStringLiteral("error: ") + r.getError();
    return r.getString();
}

QString ZoneSeqUiProbeBackend::echoArg(QString s)
{
    if (!isContextReady())
        return QStringLiteral("error: context not ready");
    LogosResult r = modules().zone_sequencer.echo_arg(s);
    if (!r.success)
        return QStringLiteral("error: ") + r.getError();
    return r.getString();
}

QString ZoneSeqUiProbeBackend::ping()
{
    return QStringLiteral("{\"ok\":true,\"module\":\"zone_seq_ui_probe\",\"ctxReady\":%1}")
        .arg(isContextReady() ? QStringLiteral("true") : QStringLiteral("false"));
}
