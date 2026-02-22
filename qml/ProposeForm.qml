import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * ProposeForm — form to create a new proposal in a multisig.
 * Supports manual IDL JSON pasting for the instruction data.
 */
Item {
    id: root

    property string createKey:          ""
    property string multisigProgramId:  ""
    property bool   submitting:         false
    property string submitError:        ""
    property string submitResult:       ""

    signal submitRequested(string argsJson)
    signal cancelled()

    function reset() {
        targetProgIdField.text      = ""
        instructionDataField.text   = ""
        accountCountField.text      = "0"
        pdaSeedsField.text          = ""
        authorizedIdxField.text     = ""
        idlJsonField.text           = ""
        walletPathField.text        = ""
        accountField.text           = ""
        submitError                 = ""
        submitResult                = ""
    }

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacing.large }
        spacing: 10

        // ── Toolbar ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Create Proposal"
                color: Theme.palette.text
                font { pixelSize: 18; bold: true }
                Layout.fillWidth: true
            }

            Button {
                text: "✕ Cancel"
                flat: true
                onClicked: root.cancelled()
                contentItem: Text {
                    text: parent.text
                    color: Theme.palette.textSecondary
                    font.pixelSize: 13
                }
                background: Rectangle { color: "transparent" }
            }
        }

        Rectangle { height: 1; color: Theme.palette.borderSecondary; Layout.fillWidth: true }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 10

                Text { text: "Your Account (proposer) *"; color: Theme.palette.textSecondary; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundSecondary
                    border { color: accountField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                    TextField {
                        id: accountField
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        background: Item {}
                        color: Theme.palette.text
                        placeholderText: "Your AccountId"
                        placeholderTextColor: Theme.palette.textTertiary
                        font { pixelSize: 13; family: "monospace" }
                    }
                }

                Text { text: "Target Program ID *"; color: Theme.palette.textSecondary; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundSecondary
                    border { color: targetProgIdField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                    TextField {
                        id: targetProgIdField
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        background: Item {}
                        color: Theme.palette.text
                        placeholderText: "64 hex chars"
                        placeholderTextColor: Theme.palette.textTertiary
                        font { pixelSize: 13; family: "monospace" }
                    }
                }

                Text { text: "Target Instruction Data (hex) *"; color: Theme.palette.textSecondary; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundSecondary
                    border { color: instructionDataField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                    TextField {
                        id: instructionDataField
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        background: Item {}
                        color: Theme.palette.text
                        placeholderText: "hex-encoded instruction bytes"
                        placeholderTextColor: Theme.palette.textTertiary
                        font { pixelSize: 13; family: "monospace" }
                    }
                }

                Text { text: "Target Account Count"; color: Theme.palette.textSecondary; font.pixelSize: 12 }
                Rectangle {
                    width: 120; height: 36; radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundSecondary
                    border { color: accountCountField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                    TextField {
                        id: accountCountField
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        background: Item {}
                        color: Theme.palette.text
                        placeholderText: "0"
                        text: "0"
                        placeholderTextColor: Theme.palette.textTertiary
                        font.pixelSize: 13
                        validator: IntValidator { bottom: 0; top: 255 }
                        inputMethodHints: Qt.ImhDigitsOnly
                    }
                }

                Text { text: "PDA Seeds (one hex64 per line)"; color: Theme.palette.textSecondary; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 80; radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundSecondary
                    border { color: pdaSeedsField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                    TextArea {
                        id: pdaSeedsField
                        anchors { fill: parent; margins: 8 }
                        background: Item {}
                        color: Theme.palette.text
                        placeholderText: "One seed per line (hex64)"
                        placeholderTextColor: Theme.palette.textTertiary
                        font { pixelSize: 12; family: "monospace" }
                        wrapMode: TextArea.WrapAnywhere
                    }
                }

                Text { text: "Authorized Indices (comma-separated, e.g. 0,1)"; color: Theme.palette.textSecondary; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundSecondary
                    border { color: authorizedIdxField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                    TextField {
                        id: authorizedIdxField
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        background: Item {}
                        color: Theme.palette.text
                        placeholderText: "0,1"
                        placeholderTextColor: Theme.palette.textTertiary
                        font.pixelSize: 13
                    }
                }

                // IDL JSON textarea
                Rectangle {
                    Layout.fillWidth: true
                    height: idlHeader.height + 12
                    radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundTertiary
                    border { color: Theme.palette.borderSecondary; width: 1 }

                    ColumnLayout {
                        id: idlHeader
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                        spacing: 6

                        Text {
                            text: "IDL JSON (optional — paste to assist instruction encoding)"
                            color: Theme.palette.textSecondary
                            font.pixelSize: 12
                        }
                        Rectangle {
                            Layout.fillWidth: true; height: 100; radius: Theme.spacing.tiny
                            color: Theme.palette.backgroundSecondary
                            border { color: idlJsonField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                            TextArea {
                                id: idlJsonField
                                anchors { fill: parent; margins: 8 }
                                background: Item {}
                                color: Theme.palette.text
                                placeholderText: "Paste IDL JSON here..."
                                placeholderTextColor: Theme.palette.textTertiary
                                font { pixelSize: 11; family: "monospace" }
                                wrapMode: TextArea.WrapAnywhere
                            }
                        }
                        Text {
                            text: "ℹ IDL is stored locally only — used to help you encode the instruction data above"
                            color: Theme.palette.textTertiary
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                Text { text: "Wallet Path (optional)"; color: Theme.palette.textSecondary; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundSecondary
                    border { color: walletPathField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                    TextField {
                        id: walletPathField
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        background: Item {}
                        color: Theme.palette.text
                        placeholderText: "/path/to/wallet"
                        placeholderTextColor: Theme.palette.textTertiary
                        font.pixelSize: 13
                    }
                }

                // Error / result
                Rectangle {
                    visible: root.submitError.length > 0
                    Layout.fillWidth: true
                    height: errLabel.implicitHeight + 16
                    color: "#2a1111"; radius: Theme.spacing.tiny
                    border { color: Theme.palette.error; width: 1 }
                    Text {
                        id: errLabel
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                        text: "⚠ " + root.submitError
                        color: Theme.palette.error; font.pixelSize: 12; wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    visible: root.submitResult.length > 0
                    Layout.fillWidth: true
                    height: okLabel.implicitHeight + 16
                    color: "#1a2e1a"; radius: Theme.spacing.tiny
                    border { color: Theme.palette.success; width: 1 }
                    Text {
                        id: okLabel
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                        text: "✓ " + root.submitResult
                        color: Theme.palette.success; font.pixelSize: 12; wrapMode: Text.WordWrap
                    }
                }

                Button {
                    Layout.fillWidth: true
                    height: 40
                    text: root.submitting ? "Proposing…" : "Create Proposal"
                    enabled: !root.submitting && accountField.text.length > 0 && targetProgIdField.text.length > 0

                    onClicked: {
                        root.submitError  = ""
                        root.submitResult = ""

                        var pdaLines = pdaSeedsField.text.split("\n")
                            .map(function(l){ return l.trim() })
                            .filter(function(l){ return l.length > 0 })

                        var authIndices = authorizedIdxField.text.split(",")
                            .map(function(s){ return parseInt(s.trim()) })
                            .filter(function(n){ return !isNaN(n) })

                        var args = {
                            "multisig_program_id":     root.multisigProgramId,
                            "create_key":              root.createKey,
                            "account":                 accountField.text.trim(),
                            "target_program_id":       targetProgIdField.text.trim(),
                            "target_instruction_data": instructionDataField.text.trim(),
                            "target_account_count":    parseInt(accountCountField.text) || 0,
                            "pda_seeds":               pdaLines,
                            "authorized_indices":      authIndices
                        }
                        if (walletPathField.text.length > 0) {
                            args["wallet_path"] = walletPathField.text.trim()
                        }

                        root.submitting = true
                        root.submitRequested(JSON.stringify(args))
                    }

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
