import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property int currentView: 0

    Rectangle {
        anchors.fill: parent
        color: Theme.palette.background
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Lock icon as styled text instead of emoji
            Rectangle {
                width: 36; height: 36; radius: 8
                color: Qt.rgba(Theme.palette.primary.r, Theme.palette.primary.g, Theme.palette.primary.b, 0.15)
                border { color: Theme.palette.primary; width: 1 }
                Text {
                    anchors.centerIn: parent
                    text: "\uD83D\uDD10"
                    font.pixelSize: 18
                }
            }

            Text {
                text: "LEZ Multisig"
                font { pixelSize: 24; bold: true }
                color: Theme.palette.text
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: createBtn.width + 24; height: 36; radius: 8
                color: Theme.palette.primary
                Text {
                    id: createBtn; anchors.centerIn: parent
                    text: "+ New Multisig"; color: "#ffffff"; font { pixelSize: 14; bold: true }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onContainsMouseChanged: parent.color = containsMouse ? Theme.palette.primaryHover : Theme.palette.primary
                }
            }
        }

        // Info bar
        Rectangle {
            Layout.fillWidth: true; height: 44; radius: 8
            color: Theme.palette.backgroundSecondary
            border { color: Theme.palette.borderSecondary; width: 1 }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                Text { text: "Threshold: 2 of 3"; color: Theme.palette.textSecondary; font.pixelSize: 13 }
                Item { Layout.fillWidth: true }
                Text { text: "Members: 3"; color: Theme.palette.textSecondary; font.pixelSize: 13 }
                Item { width: 20 }
                Text { text: "Proposals: 3"; color: Theme.palette.success; font { pixelSize: 13; bold: true } }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.palette.borderSecondary }

        // Proposal list
        Repeater {
            model: proposalModel
            delegate: ProposalCard {
                Layout.fillWidth: true
                proposalIndex: model.index
                proposer: model.proposer
                targetProgramId: model.targetProgram
                approvedCount: model.approved
                rejectedCount: model.rejected
                status: model.status
                threshold: 2
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Powered by Logos \u00b7 LEZ Multisig v0.1.0"
            color: Theme.palette.textTertiary; font.pixelSize: 11
        }
    }

    ListModel {
        id: proposalModel
        ListElement { proposer: "jimmy-claw"; targetProgram: "lez-registry: register(...)"; approved: 2; rejected: 0; status: "Approved" }
        ListElement { proposer: "logos-team"; targetProgram: "token-factory: mint(1000)"; approved: 1; rejected: 0; status: "Active" }
        ListElement { proposer: "defi-dev"; targetProgram: "amm-swap: addLiquidity(...)"; approved: 0; rejected: 2; status: "Rejected" }
    }
}
