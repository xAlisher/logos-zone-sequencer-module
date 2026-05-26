#pragma once
#include "i_logos_zone_sequencer_module.h"
#include <QObject>
#include <QString>
#include <QMap>
#include <QtConcurrent/QtConcurrentRun>

class LogosAPI;

class LogosZoneSequencerModule : public QObject, public ILogosZoneSequencerModule {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID ILogosZoneSequencerModule_iid FILE LOGOS_ZONE_SEQUENCER_MODULE_METADATA_FILE)
    Q_INTERFACES(PluginInterface ILogosZoneSequencerModule)
public:
    LogosZoneSequencerModule();
    ~LogosZoneSequencerModule() override;
    QString name() const override { return "liblogos_zone_sequencer_module"; }
    QString version() const override { return "0.2.0"; }
    Q_INVOKABLE void initLogos(LogosAPI* api) override;
    Q_INVOKABLE void set_node_url(const QString& url) override;
    Q_INVOKABLE void set_signing_key(const QString& hex) override;
    Q_INVOKABLE void set_checkpoint_path(const QString& path) override;
    Q_INVOKABLE void set_channel_id(const QString& channelIdHex) override;
    Q_INVOKABLE QString get_channel_id() override;
    Q_INVOKABLE QString publish(const QString& data) override;
    Q_INVOKABLE QString publish_to(const QString& channelId,
                                   const QString& signingKeyHex,
                                   const QString& checkpointPath,
                                   const QString& data) override;
    Q_INVOKABLE QString query_channel(const QString& channelId, int limit) override;
    Q_INVOKABLE QString query_channel_paged(const QString& channelId,
                                             const QString& cursorJson,
                                             int limit) override;
signals:
    void eventResponse(const QString& eventName, const QVariantList& data);
private:
    void tryCreateSequencer();

    QString m_nodeUrl = QStringLiteral("http://localhost:8080");
    QString m_signingKey;
    QString m_checkpointPath;
    QString m_channelId;
    void*   m_sequencerHandle = nullptr;
    bool    m_creatingSequencer = false;
    QMap<QString, void*> m_channelHandles;  // per-channel handles for publish_to
};
