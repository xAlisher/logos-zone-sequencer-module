#include "zone_seq_ui_probe_backend.h"

#include <fstream>

#include "logos_sdk.h"   // generated: defines modules().zone_sequencer (Qt-typed)

void ZoneSeqUiProbeBackend::onContextReady()
{
    setReady(true);
    // RUNTIME self-test: forward to modules().zone_sequencer the moment modules()
    // is wired. 64×'a' derives to the fixed channel e734ea6c… — a match proves the
    // QtRO handshake + modules() wiring + cross-module forwarding all work at GUI
    // runtime. Written to a file since Basecamp drops QML/backend console output.
    const QString key(64, QChar('a'));
    const QString got = deriveChannelId(key);
    std::ofstream f("/tmp/probe-selftest.txt", std::ios::trunc);
    f << "zone_seq_ui_probe onContextReady()\n";
    f << "deriveChannelId(64a) = " << got.toStdString() << "\n";
    f << "expected             = e734ea6c2b6257de72355e472aa05a4c487e6b463c029ed306df2f01b5636b58\n";
    f << "PASS = " << (got.toStdString() == "e734ea6c2b6257de72355e472aa05a4c487e6b463c029ed306df2f01b5636b58" ? "yes" : "no") << "\n";
}

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
