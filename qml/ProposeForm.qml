import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import LezMultisig 1.0

/**
 * ProposeForm — form to create a new proposal in a multisig.
 *
 * Supports two modes for target program + IDL:
 *  1. Browse Registry — opens a popup listing registered programs;
 *     selecting one auto-fills program ID and loads its IDL.
 *  2. Manual / Advanced — type the program ID and paste IDL JSON directly.
 */
Item {
    id: root

    property string createKey:          ""
    property string multisigProgramId:  ""
    property string sequencerUrl:       "http://localhost:9000"
    property bool   submitting:         false
    property string submitError:        ""
    property string submitResult:       ""

    // Parsed IDL instructions (QVariantList from RegistryBridge.parseIdl)
    property var idlInstructions:  []
    property int selectedInstruction: -1

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
        root.idlInstructions        = []
        root.selectedInstruction    = -1
        selectedProgramLabel.text   = ""
    }

    // ── Registry browser popup ────────────────────────────────────────────────
    Popup {
        id: registryPopup
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.9, 600)
        height: Math.min(parent.height * 0.8, 520)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Theme.palette.background
            radius: Theme.spacing.small
            border { color: Theme.palette.borderSecondary; width: 1 }
        }

        property var programs: []
        property bool loading: false
        property string loadError: ""

        onOpened: {
            loadError = ""
            programs = []
            if (typeof lezRegistryBridge === "undefined" || !lezRegistryBridge.isLoaded) {
                loadError = "Registry bridge not available (liblez_registry_ffi.so not loaded)"
                return
            }
            loading = true
            var result = lezRegistryBridge.listPrograms(root.sequencerUrl)
            loading = false
            if (result.length === 0) {
                loadError = lezRegistryBridge.lastError() || "No programs registered yet"
            } else {
                programs = result
            }
        }

        ColumnLayout {
            anchors { fill: parent; margins: 16 }
            spacing: 10

            // Title bar
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "📋 Browse Program Registry"
                    color: Theme.palette.text
                    font { pixelSize: 16; bold: true }
                    Layout.fillWidth: true
                }
                Button {
                    text: "✕"
                    flat: true
                    onClicked: registryPopup.close()
                    contentItem: Text {
                        text: parent.text
                        color: Theme.palette.textSecondary
                        font.pixelSize: 14
                    }
                    background: Rectangle { color: "transparent" }
                }
            }

            Rectangle { height: 1; color: Theme.palette.borderSecondary; Layout.fillWidth: true }

            // Sequencer URL input
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Sequencer:"
                    color: Theme.palette.textSecondary
                    font.pixelSize: 12
                }
                Rectangle {
                    Layout.fillWidth: true; height: 30; radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundSecondary
                    border { color: seqUrlField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                    TextField {
                        id: seqUrlField
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        background: Item {}
                        color: Theme.palette.text
                        text: root.sequencerUrl
                        font { pixelSize: 12; family: "monospace" }
                        onTextChanged: root.sequencerUrl = text
                    }
                }
                Button {
                    text: "Refresh"
                    onClicked: registryPopup.opened()
                    contentItem: Text {
                        text: parent.text
                        color: Theme.palette.text
                        font.pixelSize: 12
                    }
                    background: Rectangle {
                        color: parent.hovered ? Theme.palette.primaryHover : Theme.palette.primary
                        radius: Theme.spacing.tiny
                    }
                }
            }

            // Loading / error state
            Item {
                Layout.fillWidth: true
                visible: registryPopup.loading || registryPopup.loadError.length > 0
                height: 32
                Text {
                    anchors.centerIn: parent
                    text: registryPopup.loading ? "⏳ Loading programs…" : ("⚠ " + registryPopup.loadError)
                    color: registryPopup.loading ? Theme.palette.textSecondary : Theme.palette.error
                    font.pixelSize: 13
                }
            }

            // Program list
            ListView {
                id: programListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: registryPopup.programs.length > 0
                clip: true
                model: registryPopup.programs
                spacing: 6

                delegate: Rectangle {
                    width: programListView.width
                    height: progCol.implicitHeight + 16
                    radius: Theme.spacing.tiny
                    color: delegateArea.containsMouse ? Theme.palette.backgroundTertiary : Theme.palette.backgroundSecondary
                    border { color: Theme.palette.borderSecondary; width: 1 }

                    ColumnLayout {
                        id: progCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: modelData.name || "(unnamed)"
                                color: Theme.palette.text
                                font { pixelSize: 14; bold: true }
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "v" + (modelData.version || "?")
                                color: Theme.palette.textSecondary
                                font.pixelSize: 12
                            }
                        }
                        Text {
                            text: modelData.program_id || ""
                            color: Theme.palette.textTertiary
                            font { pixelSize: 11; family: "monospace" }
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                        Text {
                            visible: (modelData.description || "").length > 0
                            text: modelData.description || ""
                            color: Theme.palette.textSecondary
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        // IDL CID badge
                        Rectangle {
                            visible: (modelData.idl_cid || "").length > 0
                            height: 18; radius: 9
                            color: "#1a3a2a"
                            border { color: Theme.palette.success; width: 1 }
                            width: idlBadge.implicitWidth + 12
                            Text {
                                id: idlBadge
                                anchors.centerIn: parent
                                text: "✓ IDL available"
                                color: Theme.palette.success
                                font.pixelSize: 10
                            }
                        }
                    }

                    MouseArea {
                        id: delegateArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Auto-fill program ID
                            targetProgIdField.text = modelData.program_id || ""
                            selectedProgramLabel.text = (modelData.name || "") +
                                (modelData.version ? "  v" + modelData.version : "")

                            // If IDL CID is available, note it (full fetch would need storage)
                            // For now, if the registry returned any idl_json inline, use it
                            if (modelData.idl_json && modelData.idl_json.length > 0) {
                                idlJsonField.text = modelData.idl_json
                                root.idlInstructions = lezRegistryBridge.parseIdl(modelData.idl_json)
                                advancedMode.checked = false
                            } else if ((modelData.idl_cid || "").length > 0) {
                                idlJsonField.placeholderText = "IDL CID: " + modelData.idl_cid +
                                    " — fetch from Logos Storage to decode"
                            }

                            registryPopup.close()
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {}
            }

            Text {
                visible: !registryPopup.loading && registryPopup.programs.length === 0 &&
                         registryPopup.loadError.length === 0
                text: "No programs found."
                color: Theme.palette.textTertiary
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }


    // ── Inline registry lookup timer ─────────────────────────────────────────
    Timer {
        id: registryLookupTimer
        interval: 500
        repeat: false
        onTriggered: {
            var pid = targetProgIdField.text.trim()
            if (pid.length !== 64) return
            if (typeof lezRegistryBridge === "undefined" || !lezRegistryBridge || !lezRegistryBridge.isLoaded) {
                inlineProgramNameLabel.text = ""
                inlineProgramDescLabel.text = ""
                return
            }
            var prog = lezRegistryBridge.getProgramById(root.sequencerUrl, pid)
            if (prog && prog.name) {
                inlineProgramNameLabel.text = prog.name + (prog.version ? "  v" + prog.version : "")
                inlineProgramDescLabel.text = prog.description || ""
            } else {
                inlineProgramNameLabel.text = ""
                inlineProgramDescLabel.text = lezRegistryBridge.lastError() || ""
            }
        }
    }

    // ── Main layout ───────────────────────────────────────────────────────────
    ColumnLayout {
        anchors { fill: parent; margins: Theme.spacing.large }
        spacing: 10

        // Toolbar
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

                // ── Proposer account ──────────────────────────────────────────
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

                // ── Target Program ID ─────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Target Program ID *"
                        color: Theme.palette.textSecondary
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                    Button {
                        text: "🔍 Browse Registry"
                        onClicked: registryPopup.open()
                        contentItem: Text {
                            text: parent.text
                            color: Theme.palette.text
                            font { pixelSize: 12; bold: false }
                            horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? Qt.darker(Theme.palette.primary, 1.1) : Theme.palette.primary
                            radius: Theme.spacing.tiny
                        }
                    }
                }

                // Selected program badge
                Rectangle {
                    id: selectedProgramBadge
                    visible: selectedProgramLabel.text.length > 0
                    Layout.fillWidth: true
                    height: 26
                    radius: Theme.spacing.tiny
                    color: "#1a2e3a"
                    border { color: Theme.palette.primary; width: 1 }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        Text {
                            text: "✓ Selected from registry:"
                            color: Theme.palette.primary
                            font.pixelSize: 11
                        }
                        Text {
                            id: selectedProgramLabel
                            text: ""
                            color: Theme.palette.text
                            font { pixelSize: 11; bold: true }
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "✕"
                            color: Theme.palette.textTertiary
                            font.pixelSize: 12
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    selectedProgramLabel.text = ""
                                    targetProgIdField.text = ""
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundSecondary
                    border { color: targetProgIdField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                    TextField {
                        id: targetProgIdField
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        background: Item {}
                        color: Theme.palette.text
                        placeholderText: "64 hex chars — or use Browse Registry above"
                        placeholderTextColor: Theme.palette.textTertiary
                        font { pixelSize: 13; family: "monospace" }
                        onTextChanged: {
                            inlineProgramNameLabel.text = ""
                            inlineProgramDescLabel.text = ""
                            if (text.trim().length === 64) {
                                registryLookupTimer.restart()
                            } else {
                                registryLookupTimer.stop()
                            }
                        }
                    }
                }

                // ── Inline registry lookup result ─────────────────────────────
                Rectangle {
                    id: inlineLookupResult
                    visible: inlineProgramNameLabel.text.length > 0 || inlineProgramDescLabel.text.length > 0
                    Layout.fillWidth: true
                    height: inlineLookupCol.implicitHeight + 12
                    radius: Theme.spacing.tiny
                    color: inlineProgramNameLabel.text.length > 0 ? "#1a3a1a" : "#2a1a1a"
                    border {
                        color: inlineProgramNameLabel.text.length > 0 ? Theme.palette.success : Theme.palette.error
                        width: 1
                    }
                    ColumnLayout {
                        id: inlineLookupCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                        spacing: 2
                        Text {
                            id: inlineProgramNameLabel
                            text: ""
                            color: Theme.palette.success
                            font { pixelSize: 13; bold: true }
                            visible: text.length > 0
                            Layout.fillWidth: true
                        }
                        Text {
                            id: inlineProgramDescLabel
                            text: ""
                            color: inlineProgramNameLabel.text.length > 0 ? Theme.palette.textSecondary : Theme.palette.error
                            font.pixelSize: 11
                            visible: text.length > 0
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                // ── IDL-driven instruction selector ───────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    visible: root.idlInstructions.length > 0
                    height: idlInstrCol.implicitHeight + 20
                    radius: Theme.spacing.tiny
                    color: "#1a2a1a"
                    border { color: Theme.palette.success; width: 1 }

                    ColumnLayout {
                        id: idlInstrCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 8

                        Text {
                            text: "📄 Instruction (from IDL)"
                            color: Theme.palette.success
                            font { pixelSize: 13; bold: true }
                        }

                        ComboBox {
                            id: instrCombo
                            Layout.fillWidth: true
                            model: {
                                var names = ["— select instruction —"]
                                for (var i = 0; i < root.idlInstructions.length; i++) {
                                    names.push(root.idlInstructions[i].name)
                                }
                                return names
                            }
                            onCurrentIndexChanged: {
                                root.selectedInstruction = currentIndex - 1
                            }
                            background: Rectangle {
                                color: Theme.palette.backgroundSecondary
                                radius: Theme.spacing.tiny
                                border { color: Theme.palette.borderSecondary; width: 1 }
                            }
                            contentItem: Text {
                                text: instrCombo.displayText
                                color: Theme.palette.text
                                font.pixelSize: 13
                                leftPadding: 8
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // Show args for selected instruction
                        Repeater {
                            model: root.selectedInstruction >= 0
                                   ? root.idlInstructions[root.selectedInstruction].args
                                   : []
                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: modelData.name + " (" + modelData.type + ")"
                                    color: Theme.palette.textSecondary
                                    font.pixelSize: 11
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 32; radius: Theme.spacing.tiny
                                    color: Theme.palette.backgroundSecondary
                                    border { color: argField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                                    TextField {
                                        id: argField
                                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                        background: Item {}
                                        color: Theme.palette.text
                                        placeholderText: modelData.description || modelData.type
                                        placeholderTextColor: Theme.palette.textTertiary
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }

                        // Accounts hint
                        Text {
                            visible: root.selectedInstruction >= 0
                            text: {
                                if (root.selectedInstruction < 0) return ""
                                var accs = root.idlInstructions[root.selectedInstruction].accounts
                                if (!accs || accs.length === 0) return ""
                                var parts = []
                                for (var i = 0; i < accs.length; i++) {
                                    var a = accs[i]
                                    var flags = []
                                    if (a.writable) flags.push("writable")
                                    if (a.signer) flags.push("signer")
                                    if (a.pda) flags.push("PDA")
                                    parts.push(a.name + (flags.length > 0 ? " [" + flags.join(", ") + "]" : ""))
                                }
                                return "Accounts: " + parts.join(" · ")
                            }
                            color: Theme.palette.textTertiary
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                // ── Instruction data (hex) ────────────────────────────────────
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

                // ── IDL JSON (Advanced / fallback) ────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: idlAdvancedCol.implicitHeight + 20
                    radius: Theme.spacing.tiny
                    color: Theme.palette.backgroundTertiary
                    border { color: Theme.palette.borderSecondary; width: 1 }

                    ColumnLayout {
                        id: idlAdvancedCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "IDL JSON"
                                color: Theme.palette.textSecondary
                                font { pixelSize: 12; bold: true }
                                Layout.fillWidth: true
                            }
                            CheckBox {
                                id: advancedMode
                                text: "Advanced"
                                checked: true
                                contentItem: Text {
                                    text: parent.text
                                    color: Theme.palette.textSecondary
                                    font.pixelSize: 11
                                    leftPadding: parent.indicator.width + parent.spacing
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        Text {
                            visible: !advancedMode.checked
                            text: "IDL loaded from registry — switch to Advanced to edit manually"
                            color: Theme.palette.textTertiary
                            font.pixelSize: 11
                        }

                        Rectangle {
                            visible: advancedMode.checked
                            Layout.fillWidth: true; height: 100; radius: Theme.spacing.tiny
                            color: Theme.palette.backgroundSecondary
                            border { color: idlJsonField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                            TextArea {
                                id: idlJsonField
                                anchors { fill: parent; margins: 8 }
                                background: Item {}
                                color: Theme.palette.text
                                placeholderText: "Paste IDL JSON here, or use Browse Registry above…"
                                placeholderTextColor: Theme.palette.textTertiary
                                font { pixelSize: 11; family: "monospace" }
                                wrapMode: TextArea.WrapAnywhere
                                onTextChanged: {
                                    if (text.length > 10) {
                                        var parsed = lezRegistryBridge ?
                                            lezRegistryBridge.parseIdl(text) : []
                                        if (parsed.length > 0) {
                                            root.idlInstructions = parsed
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            text: "ℹ IDL is used locally to show instruction fields and assist encoding"
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
                        if (idlJsonField.text.length > 0) {
                            args["idl_json"] = idlJsonField.text.trim()
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
