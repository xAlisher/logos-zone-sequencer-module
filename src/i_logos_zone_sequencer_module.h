#pragma once
#include <QtPlugin>
#include <QString>
#include <QVariantList>

class LogosAPI;

class PluginInterface {
public:
    virtual ~PluginInterface() {}
    virtual QString name() const = 0;
    virtual QString version() const = 0;
    LogosAPI* logosAPI = nullptr;
};
#define PluginInterface_iid "com.example.PluginInterface"
Q_DECLARE_INTERFACE(PluginInterface, PluginInterface_iid)

class ILogosZoneSequencerModule : public PluginInterface {
public:
    virtual ~ILogosZoneSequencerModule() {}
    Q_INVOKABLE virtual void initLogos(LogosAPI* api) = 0;
    Q_INVOKABLE virtual void set_node_url(const QString& url) = 0;
    Q_INVOKABLE virtual void set_signing_key(const QString& hex) = 0;
    Q_INVOKABLE virtual void set_checkpoint_path(const QString& path) = 0;
    Q_INVOKABLE virtual void set_channel_id(const QString& channelIdHex) = 0;
    Q_INVOKABLE virtual QString get_channel_id() = 0;
    Q_INVOKABLE virtual QString publish(const QString& data) = 0;
    // Publish to any channel via a cached persistent handle — returns mantle_tx.hash directly.
    // First call per channel creates the handle (blocks ~5s); subsequent calls are instant.
    Q_INVOKABLE virtual QString publish_to(const QString& channelId,
                                            const QString& signingKeyHex,
                                            const QString& checkpointPath,
                                            const QString& data) = 0;
    Q_INVOKABLE virtual QString query_channel(const QString& channelId, int limit) = 0;
    Q_INVOKABLE virtual QString query_channel_paged(const QString& channelId,
                                                     const QString& cursorJson,
                                                     int limit) = 0;
};
#define ILogosZoneSequencerModule_iid "org.logos.ilogoszonesquencermodule"
Q_DECLARE_INTERFACE(ILogosZoneSequencerModule, ILogosZoneSequencerModule_iid)
