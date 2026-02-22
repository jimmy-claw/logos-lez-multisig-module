import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root

    property int currentView: 0  // 0=proposals, 1=detail, 2=create, 3=propose

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "🔐 LEZ Multisig"
                font.pixelSize: 24
                font.bold: true
                color: "#ffffff"
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: createBtn.width + 20; height: 36; radius: 8
                color: "#FF8800"
                Text {
                    id: createBtn; anchors.centerIn: parent
                    text: "+ New Multisig"; color: "#ffffff"; font.pixelSize: 14; font.bold: true
                }
            }
        }

        // Info bar
        Rectangle {
            Layout.fillWidth: true; height: 40; radius: 8; color: "#262626"
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                Text { text: "Threshold: 2 of 3"; color: "#A4A4A4"; font.pixelSize: 13 }
                Item { Layout.fillWidth: true }
                Text { text: "Members: 3"; color: "#A4A4A4"; font.pixelSize: 13 }
                Item { width: 20 }
                Text { text: "Proposals: 3"; color: "#49F563"; font.pixelSize: 13 }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#2B303B" }

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
            text: "Powered by Logos · LEZ Multisig v0.1.0"
            color: "#555555"; font.pixelSize: 11
        }
    }

    ListModel {
        id: proposalModel
        ListElement { proposer: "jimmy-claw"; targetProgram: "lez-registry: register(...)"; approved: 2; rejected: 0; status: "Approved" }
        ListElement { proposer: "logos-team"; targetProgram: "token-factory: mint(1000)"; approved: 1; rejected: 0; status: "Active" }
        ListElement { proposer: "defi-dev"; targetProgram: "amm-swap: addLiquidity(...)"; approved: 0; rejected: 2; status: "Rejected" }
    }
}
