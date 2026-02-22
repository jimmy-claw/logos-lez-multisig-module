import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * ProposalCard — delegate component for a single multisig proposal.
 * Shows index, status badge, approval counts, and target program snippet.
 */
Rectangle {
    id: root

    // ── Data ─────────────────────────────────────────────────────────────────
    property int    proposalIndex:      0
    property string proposer:           ""
    property string targetProgramId:    ""
    property int    approvedCount:      0
    property int    rejectedCount:      0
    property string status:             "Active"
    property string proposalPda:        ""
    property int    threshold:          0

    // ── Signals ───────────────────────────────────────────────────────────────
    signal clicked()

    // ── Status color helper ────────────────────────────────────────────────────
    function statusColor(s) {
        switch(s) {
            case "Active":    return Theme.palette.warning;
            case "Executed":  return Theme.palette.info;
            case "Rejected":  return Theme.palette.error;
            case "Cancelled": return Theme.palette.textTertiary;
            default:          return Theme.palette.textTertiary;
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    height:  cardColumn.implicitHeight + 24
    radius:  Theme.spacing.radiusLarge
    color:   mouseArea.containsMouse ? Theme.palette.backgroundSecondary : Theme.palette.backgroundTertiary

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
            margins: Theme.spacing.medium
        }
        spacing: Theme.spacing.tiny

        // Index + Status row
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small

            Text {
                text: "#" + root.proposalIndex
                color: Theme.palette.text
                font { pixelSize: 15; bold: true; family: "monospace" }
            }

            // Status badge
            Rectangle {
                width:  statusLabel.implicitWidth + Theme.spacing.medium
                height: 20
                radius: 10
                color: Qt.rgba(root.statusColor(root.status).r,
                               root.statusColor(root.status).g,
                               root.statusColor(root.status).b, 0.15)
                border { color: root.statusColor(root.status); width: 1 }

                Text {
                    id: statusLabel
                    anchors.centerIn: parent
                    text: root.status
                    color: root.statusColor(root.status)
                    font.pixelSize: 10
                }
            }

            Item { Layout.fillWidth: true }

            // Approval count
            Text {
                text: "✓ " + root.approvedCount + (root.threshold > 0 ? "/" + root.threshold : "")
                color: Theme.palette.success
                font.pixelSize: 12
            }
            Text {
                text: "✗ " + root.rejectedCount
                color: Theme.palette.error
                font.pixelSize: 12
                visible: root.rejectedCount > 0
            }
        }

        // Target program
        Text {
            visible: root.targetProgramId.length > 0
            text: "→ " + (root.targetProgramId.length > 20
                          ? root.targetProgramId.substring(0, 10) + "…" + root.targetProgramId.slice(-8)
                          : root.targetProgramId)
            color: Theme.palette.textSecondary
            font { pixelSize: 11; family: "monospace" }
        }

        // Proposer
        Text {
            visible: root.proposer.length > 0
            text: "by " + (root.proposer.length > 20
                          ? root.proposer.substring(0, 8) + "…" + root.proposer.slice(-6)
                          : root.proposer)
            color: Theme.palette.textTertiary
            font.pixelSize: 11
        }
    }
}
