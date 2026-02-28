import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        color: "#1a1a2e"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Tab bar ──────────────────────────────────────────────────────────
        TabBar {
            id: tabBar
            Layout.fillWidth: true

            background: Rectangle { color: "#16213e" }

            TabButton {
                text: "Multisig"
                width: implicitWidth
                contentItem: Text {
                    text: parent.text
                    color: tabBar.currentIndex === 0 ? "#f5a623" : "#A4A4A4"
                    font.pixelSize: 14
                    font.bold: tabBar.currentIndex === 0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: tabBar.currentIndex === 0 ? "#1a1a2e" : "#16213e"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 2
                        color: "#f5a623"
                        visible: tabBar.currentIndex === 0
                    }
                }
            }

            TabButton {
                text: "Registry"
                width: implicitWidth
                contentItem: Text {
                    text: parent.text
                    color: tabBar.currentIndex === 1 ? "#f5a623" : "#A4A4A4"
                    font.pixelSize: 14
                    font.bold: tabBar.currentIndex === 1
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: tabBar.currentIndex === 1 ? "#1a1a2e" : "#16213e"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 2
                        color: "#f5a623"
                        visible: tabBar.currentIndex === 1
                    }
                }
            }
        }

        // ── Content area ─────────────────────────────────────────────────────
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            Loader {
                source: "LezMultisigView.qml"
            }

            Loader {
                source: "qrc:/lez-registry/LezRegistryView.qml"
            }
        }
    }
}
