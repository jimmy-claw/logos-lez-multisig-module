import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import LezMultisig 1.0

/**
 * ProposalCard — delegate component for a single multisig proposal.
 */
Rectangle {
    id: root

    property int    proposalIndex:      0
    property string proposer:           ""
    property string targetProgramId:    ""
    property int    approvedCount:      0
    property int    rejectedCount:      0
    property string status:             "Active"
    property string proposalPda:        ""
    property int    threshold:          0

    signal clicked()

    function statusColor(s) {
        switch(s) {
            case "Active":    return Theme.palette.warning;
            case "Approved":  return Theme.palette.success;
            case "Executed":  return Theme.palette.info;
            case "Rejected":  return Theme.palette.error;
            case "Cancelled": return Theme.palette.textTertiary;
            default:          return Theme.palette.textTertiary;
        }
    }

    height:  cardColumn.implicitHeight + 28
    radius:  Theme.spacing.radiusLarge
    color:   mouseArea.containsMouse ? Qt.lighter(Theme.palette.backgroundTertiary, 1.15) : Theme.palette.backgroundTertiary

    border {
        color: mouseArea.containsMouse ? Theme.palette.primary : Theme.palette.borderSecondary
        width: 1
    }

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    ColumnLayout {
        id: cardColumn
        anchors {
            left:   parent.left
            right:  parent.right
            top:    parent.top
            margins: Theme.spacing.large
        }
        spacing: Theme.spacing.small

        // Row 1: Index + Status badge (left) ... Vote counts (right)
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small

            Text {
                text: "#" + root.proposalIndex
                color: Theme.palette.text
                font { pixelSize: 16; bold: true; family: "monospace" }
            }

            // Status badge
            Rectangle {
                width:  statusLabel.implicitWidth + 16
                height: 22
                radius: 11
                color: Qt.rgba(root.statusColor(root.status).r,
                               root.statusColor(root.status).g,
                               root.statusColor(root.status).b, 0.15)
                border { color: root.statusColor(root.status); width: 1 }

                Text {
                    id: statusLabel
                    anchors.centerIn: parent
                    text: root.status
                    color: root.statusColor(root.status)
                    font { pixelSize: 11; bold: true }
                }
            }

            Item { Layout.fillWidth: true }

            // Vote counts
            Text {
                text: "\u2713 " + root.approvedCount + (root.threshold > 0 ? "/" + root.threshold : "")
                color: Theme.palette.success
                font { pixelSize: 13; bold: true }
            }
            Text {
                text: "\u2717 " + root.rejectedCount
                color: Theme.palette.error
                font { pixelSize: 13; bold: true }
                visible: root.rejectedCount > 0
            }
        }

        // Row 2: Target program — wider, elide in middle
        Text {
            Layout.fillWidth: true
            visible: root.targetProgramId.length > 0
            text: "\u2192 " + root.targetProgramId
            color: Theme.palette.textSecondary
            font { pixelSize: 12; family: "monospace" }
            elide: Text.ElideMiddle
            maximumLineCount: 1
        }

        // Row 3: Proposer — subtle
        Text {
            visible: root.proposer.length > 0
            text: "by " + root.proposer
            color: Theme.palette.textTertiary
            font { pixelSize: 10; italic: true }
        }
    }
}
