import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import LezMultisig 1.0

/**
 * CreateMultisigForm — form to create a new M-of-N multisig.
 */
Item {
    id: root

    property bool   submitting:   false
    property string submitError:  ""
    property string submitResult: ""

    signal submitRequested(string argsJson)
    signal cancelled()

    function reset() {
        createKeyField.text    = ""
        thresholdField.text    = "2"
        membersField.text      = ""
        walletPathField.text   = ""
        programIdField.text    = ""
        submitError            = ""
        submitResult           = ""
    }

    // Generate random create_key (hex)
    function randomHex32() {
        var result = "";
        for (var i = 0; i < 64; i++) {
            result += Math.floor(Math.random() * 16).toString(16);
        }
        return result;
    }

    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacing.large }
        spacing: 10

        // ── Toolbar ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Create Multisig"
                color: Theme.palette.text
                font { pixelSize: 18; bold: true }
                Layout.fillWidth: true
            }

            Button {
                text: "✕ Cancel"
                flat: true
                onClicked: { root.submitting = false; root.cancelled() }
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

                // ── Field helper ─────────────────────────────────────────────
                component FormField : ColumnLayout {
                    property alias  label:       fieldLabel.text
                    property alias  placeholder: inputField.placeholderText
                    property alias  text:        inputField.text
                    property bool   required:    false

                    spacing: 2
                    Layout.fillWidth: true

                    RowLayout {
                        Text {
                            id: fieldLabel
                            color: Theme.palette.textSecondary
                            font.pixelSize: 12
                        }
                        Text {
                            text: "*"
                            color: Theme.palette.error
                            font.pixelSize: 12
                            visible: parent.parent.required
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: Theme.spacing.tiny
                        color: Theme.palette.backgroundSecondary
                        border { color: inputField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }

                        TextField {
                            id: inputField
                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                            background: Item {}
                            color: Theme.palette.text
                            placeholderTextColor: Theme.palette.textTertiary
                            font.pixelSize: 13
                        }
                    }
                }


                // Actual fields using property aliases trick — use direct TextFields
                Text { text: "Multisig Program ID *"; color: Theme.palette.textSecondary; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundSecondary
                    border { color: programIdField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                    TextField {
                        id: programIdField
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        background: Item {}
                        color: Theme.palette.text
                        text: "7f92d57b20a63264d90119c6322f7d8058ecf2b14f462d29d1ae6cf42e684006"; placeholderText: "64 hex chars"
                        placeholderTextColor: Theme.palette.textTertiary
                        font { pixelSize: 13; family: "monospace" }
                    }
                }

                Text { text: "Create Key (unique identifier) *"; color: Theme.palette.textSecondary; font.pixelSize: 12 }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle {
                        Layout.fillWidth: true; height: 36; radius: Theme.spacing.tiny
                        color: Theme.palette.backgroundSecondary
                        border { color: createKeyField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                        TextField {
                            id: createKeyField
                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                            background: Item {}
                            color: Theme.palette.text
                            placeholderText: "64 hex chars (or generate random)"
                            placeholderTextColor: Theme.palette.textTertiary
                            font { pixelSize: 13; family: "monospace" }
                        }
                    }
                    Button {
                        text: "Random"
                        height: 36
                        onClicked: createKeyField.text = root.randomHex32()
                        contentItem: Text {
                            text: parent.text
                            color: Theme.palette.primary
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? Theme.palette.backgroundSecondary : "transparent"
                            radius: Theme.spacing.tiny
                            border { color: Theme.palette.primary; width: 1 }
                        }
                    }
                }

                Text { text: "Threshold (M of N) *"; color: Theme.palette.textSecondary; font.pixelSize: 12 }
                Rectangle {
                    width: 120; height: 36; radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundSecondary
                    border { color: thresholdField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                    TextField {
                        id: thresholdField
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        background: Item {}
                        color: Theme.palette.text
                        placeholderText: "2"
                        text: "2"
                        placeholderTextColor: Theme.palette.textTertiary
                        font.pixelSize: 13
                        validator: IntValidator { bottom: 1; top: 255 }
                        inputMethodHints: Qt.ImhDigitsOnly
                    }
                }

                Text { text: "Members (one hex64 AccountId per line) *"; color: Theme.palette.textSecondary; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 120; radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundSecondary
                    border { color: membersField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                    TextArea {
                        id: membersField
                        anchors { fill: parent; margins: 8 }
                        background: Item {}
                        color: Theme.palette.text
                        placeholderText: "Paste one member AccountId hex per line..."
                        placeholderTextColor: Theme.palette.textTertiary
                        font { pixelSize: 12; family: "monospace" }
                        wrapMode: TextArea.WrapAnywhere
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

                // Submit button
                Button {
                    Layout.fillWidth: true
                    height: 40
                    text: root.submitting ? "Creating…" : "Create Multisig"
                    enabled: !root.submitting && programIdField.text.length > 0 && createKeyField.text.length > 0

                    onClicked: {
                        root.submitError  = ""
                        root.submitResult = ""

                        // Parse members list
                        var lines = membersField.text.split("\n").map(function(l){ return l.trim() }).filter(function(l){ return l.length > 0 })
                        if (lines.length === 0) {
                            root.submitError = "Please enter at least one member AccountId"
                            return
                        }

                        var args = {
                            "multisig_program_id": programIdField.text.trim(),
                            "create_key":          createKeyField.text.trim(),
                            "threshold":           parseInt(thresholdField.text) || 2,
                            "members":             lines
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
