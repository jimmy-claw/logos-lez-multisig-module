import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import LezMultisig 1.0

/**
 * ProposalDetail — full detail view for a multisig proposal.
 * Shows all fields, member approvals, and approve/reject/execute buttons.
 */
Item {
    id: root

    // ── Data ─────────────────────────────────────────────────────────────────
    property int    proposalIndex:      0
    property string proposer:           ""
    property string targetProgramId:    ""
    property int    approvedCount:      0
    property int    rejectedCount:      0
    property string status:             "Active"
    property string proposalPda:        ""
    property int    threshold:          2
    property bool   actioning:          false
    property string actionError:        ""
    property string actionResult:       ""

    // ── Signals ───────────────────────────────────────────────────────────────
    signal backRequested()
    signal approveRequested()
    signal rejectRequested()
    signal executeRequested()

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
    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacing.large }
        spacing: Theme.spacing.medium

        // ── Toolbar ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Button {
                text: "← Back"
                flat: true
                onClicked: root.backRequested()
                contentItem: Text {
                    text: parent.text
                    color: Theme.palette.primary
                    font.pixelSize: 13
                }
                background: Rectangle { color: "transparent" }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Proposal Detail"
                color: Theme.palette.textSecondary
                font.pixelSize: 13
            }
        }

        Rectangle { height: 1; color: Theme.palette.borderSecondary; Layout.fillWidth: true }

        // ── Scroll area ───────────────────────────────────────────────────────
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: Theme.spacing.medium

                // Proposal # + status
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.medium

                    Text {
                        text: "Proposal #" + root.proposalIndex
                        color: Theme.palette.text
                        font { pixelSize: 22; bold: true; family: "monospace" }
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width:  badge.implicitWidth + Theme.spacing.large
                        height: 26
                        radius: Theme.spacing.tiny
                        color: Qt.rgba(root.statusColor(root.status).r,
                                       root.statusColor(root.status).g,
                                       root.statusColor(root.status).b, 0.15)
                        border { color: root.statusColor(root.status); width: 1 }
                        Text {
                            id: badge
                            anchors.centerIn: parent
                            text: root.status
                            color: root.statusColor(root.status)
                            font.pixelSize: 13
                        }
                    }
                }

                // Vote progress bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: Theme.palette.borderSecondary

                    Rectangle {
                        width: root.threshold > 0
                               ? Math.min(parent.width * root.approvedCount / root.threshold, parent.width)
                               : 0
                        height: parent.height
                        radius: parent.radius
                        color: root.approvedCount >= root.threshold ? Theme.palette.success : Theme.palette.warning
                        Behavior on width { NumberAnimation { duration: 200 } }
                    }
                }

                Text {
                    text: root.approvedCount + " of " + root.threshold + " approvals — " + root.rejectedCount + " rejected"
                    color: Theme.palette.textSecondary
                    font.pixelSize: 12
                }

                Rectangle { height: 1; color: Theme.palette.borderSecondary; Layout.fillWidth: true }

                // ── Meta fields ───────────────────────────────────────────────
                component MetaField : ColumnLayout {
                    property alias label: labelText.text
                    property alias value: valueText.text
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        id: labelText
                        color: Theme.palette.textTertiary
                        font.pixelSize: 11
                        text: ""
                    }
                    Text {
                        id: valueText
                        color: Theme.palette.text
                        font { pixelSize: 13; family: "monospace" }
                        wrapMode: Text.WrapAnywhere
                        Layout.fillWidth: true
                        text: ""
                    }
                }

                MetaField {
                    label: "Target Program"
                    value: root.targetProgramId || "(none)"
                }

                MetaField {
                    label: "Proposer"
                    value: root.proposer || "(unknown)"
                }

                MetaField {
                    label: "Proposal PDA"
                    value: root.proposalPda || "(unknown)"
                }

                // ── Action error/result ────────────────────────────────────────
                Rectangle {
                    visible: root.actionError.length > 0
                    Layout.fillWidth: true
                    height: errText.implicitHeight + Theme.spacing.large
                    color: "#2a1111"
                    radius: Theme.spacing.tiny
                    border { color: Theme.palette.error; width: 1 }

                    Text {
                        id: errText
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                        text: "⚠ " + root.actionError
                        color: Theme.palette.error
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    visible: root.actionResult.length > 0
                    Layout.fillWidth: true
                    height: okText.implicitHeight + Theme.spacing.large
                    color: "#1a2e1a"
                    radius: Theme.spacing.tiny
                    border { color: Theme.palette.success; width: 1 }

                    Text {
                        id: okText
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                        text: "✓ " + root.actionResult
                        color: Theme.palette.success
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }

                // ── Action buttons ─────────────────────────────────────────────
                RowLayout {
                    visible: root.status === "Active"
                    Layout.fillWidth: true
                    spacing: Theme.spacing.medium

                    Button {
                        text: root.actioning ? "…" : "✓ Approve"
                        enabled: !root.actioning
                        onClicked: root.approveRequested()
                        contentItem: Text {
                            text: parent.text
                            color: parent.enabled ? Theme.palette.success : Theme.palette.textTertiary
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#1a2e1a" : "transparent"
                            radius: Theme.spacing.tiny
                            border { color: Theme.palette.success; width: 1 }
                        }
                        Layout.fillWidth: true
                        height: 36
                    }

                    Button {
                        text: root.actioning ? "…" : "✗ Reject"
                        enabled: !root.actioning
                        onClicked: root.rejectRequested()
                        contentItem: Text {
                            text: parent.text
                            color: parent.enabled ? Theme.palette.error : Theme.palette.textTertiary
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#2a1111" : "transparent"
                            radius: Theme.spacing.tiny
                            border { color: Theme.palette.error; width: 1 }
                        }
                        Layout.fillWidth: true
                        height: 36
                    }
                }

                Button {
                    text: root.actioning ? "Executing…" : "⚡ Execute"
                    visible: root.status === "Active" && root.approvedCount >= root.threshold
                    enabled: !root.actioning
                    Layout.fillWidth: true
                    height: 40
                    onClicked: root.executeRequested()
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? Theme.palette.backgroundTertiary : Theme.palette.textTertiary
                        font { pixelSize: 14; bold: true }
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        color: parent.enabled ? (parent.hovered ? Theme.palette.primaryHover : Theme.palette.primary) : Theme.palette.borderSecondary
                        radius: Theme.spacing.tiny
                    }
                }

                Item { height: Theme.spacing.large }
            }
        }
    }
}
