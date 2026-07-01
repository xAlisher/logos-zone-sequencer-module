import QtQuick

// Minimal view — the pattern under test is the backend, not the UI. Binds to
// its own paired backend via logos.module(), the canonical v0.2 QtRO bridge.
Rectangle {
    id: root
    color: "#171717"

    readonly property var backend: logos.module("zone_seq_ui_probe")
    property bool ready: false

    Connections {
        target: logos
        function onViewModuleReadyChanged(moduleName, isReady) {
            if (moduleName === "zone_seq_ui_probe")
                root.ready = isReady && root.backend !== null
        }
    }
    Component.onCompleted: {
        root.ready = root.backend !== null && logos.isViewModuleReady("zone_seq_ui_probe")
    }

    Text {
        anchors.centerIn: parent
        color: "white"
        text: root.ready ? qsTr("zone_seq_ui_probe ready") : qsTr("connecting…")
    }
}
