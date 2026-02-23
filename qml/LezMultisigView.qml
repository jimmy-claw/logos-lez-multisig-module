import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import LezMultisig 1.0

Item {
    id: root

    // View stack: 0=list, 1=detail, 2=createMultisig, 3=propose
    property int currentView: 0

    // Currently selected proposal (for detail view)
    property int    selectedIndex:       0
    property string selectedProposer:    ""
    property string selectedTarget:      ""
    property int    selectedApproved:    0
    property int    selectedRejected:    0
    property string selectedStatus:      ""
    property string selectedPda:         ""
    property int    selectedThreshold:   2

    // Multisig config — populated from getState or user input
    property string multisigCreateKey:     ""
    property string multisigProgramId:     ""
    property int    multisigThreshold:     0
    property int    multisigMemberCount:   0

    // Use the real model exposed from C++ via context property, fallback to demo
    property bool hasRealModel: typeof lezMultisigModel !== "undefined" && lezMultisigModel !== null
    property bool hasModule:    typeof lezMultisigModule !== "undefined" && lezMultisigModule !== null

    Rectangle {
        anchors.fill: parent
        color: Theme.palette.background
    }

    // ── Helper: build common args JSON ───────────────────────────────────────
    function commonArgs() {
        var args = {}
        if (multisigProgramId.length > 0)
            args["multisig_program_id"] = multisigProgramId
        if (multisigCreateKey.length > 0)
            args["create_key"] = multisigCreateKey
        return args
    }

    function proposalArgs(proposalIndex) {
        var args = commonArgs()
        args["proposal_index"] = proposalIndex
        return JSON.stringify(args)
    }

    // ── Refresh proposals via real model ──────────────────────────────────────
    function refreshProposals() {
        if (hasRealModel && multisigCreateKey.length > 0 && multisigProgramId.length > 0) {
            lezMultisigModel.setCreateKey(multisigCreateKey)
            lezMultisigModel.setMultisigProgramId(multisigProgramId)
            if (sequencerUrlField.text.length > 0)
                lezMultisigModel.setSequencerUrl(sequencerUrlField.text)
            lezMultisigModel.refresh()
        }
    }

    // ── Fetch multisig state ─────────────────────────────────────────────────
    function refreshState() {
        if (!hasModule) return
        var args = commonArgs()
        var resultJson = lezMultisigModule.getState(JSON.stringify(args))
        try {
            var result = JSON.parse(resultJson)
            if (result.success && result.state) {
                multisigThreshold   = result.state.threshold   || 0
                multisigMemberCount = result.state.member_count || 0
            }
        } catch(e) {
            console.warn("getState parse error:", e)
        }
    }

    // ── Signal connections to module ─────────────────────────────────────────
    Connections {
        target: hasModule ? lezMultisigModule : null
        enabled: hasModule

        function onActionCompleted(resultJson) {
            detailView.actioning    = false
            detailView.actionResult = "Action completed successfully"
            refreshProposals()
        }
        function onActionFailed(error) {
            detailView.actioning   = false
            detailView.actionError = error
        }
        function onMultisigCreated(resultJson) {
            createForm.submitting = false
            try {
                var r = JSON.parse(resultJson)
                if (r.create_key) multisigCreateKey = r.create_key
                createForm.submitResult = "Multisig created! TX: " + (r.tx_hash || "OK")
            } catch(e) {
                createForm.submitResult = "Multisig created!"
            }
            refreshState()
            refreshProposals()
        }
        function onProposalCreated(resultJson) {
            proposeForm.submitting = false
            try {
                var r = JSON.parse(resultJson)
                proposeForm.submitResult = "Proposal #" + (r.proposal_index || "?") + " created!"
            } catch(e) {
                proposeForm.submitResult = "Proposal created!"
            }
            refreshProposals()
        }
    }

    Connections {
        target: hasRealModel ? lezMultisigModel : null
        enabled: hasRealModel

        function onRefreshed() {
            // Update proposal count display
        }
        function onErrorChanged() {
            if (lezMultisigModel.error.length > 0)
                console.warn("Model error:", lezMultisigModel.error)
        }
    }

    // ── View: Proposal List ──────────────────────────────────────────────────
    ColumnLayout {
        id: listView
        visible: root.currentView === 0
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

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

            // Refresh button
            Rectangle {
                width: refreshBtn.width + 24; height: 36; radius: 8
                color: refreshArea.containsMouse ? Theme.palette.backgroundTertiary : Theme.palette.backgroundSecondary
                border { color: Theme.palette.borderSecondary; width: 1 }
                Text {
                    id: refreshBtn; anchors.centerIn: parent
                    text: hasRealModel && lezMultisigModel.loading ? "⏳" : "↻ Refresh"
                    color: Theme.palette.textSecondary; font { pixelSize: 14 }
                }
                MouseArea {
                    id: refreshArea
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: { refreshState(); refreshProposals() }
                }
            }

            // New Proposal button
            Rectangle {
                width: proposeBtn.width + 24; height: 36; radius: 8
                color: Theme.palette.backgroundTertiary
                border { color: Theme.palette.primary; width: 1 }
                Text {
                    id: proposeBtn; anchors.centerIn: parent
                    text: "+ Proposal"; color: Theme.palette.primary; font { pixelSize: 14; bold: true }
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onContainsMouseChanged: parent.color = containsMouse ? Qt.lighter(Theme.palette.backgroundTertiary, 1.2) : Theme.palette.backgroundTertiary
                    onClicked: {
                        proposeForm.reset()
                        proposeForm.createKey         = root.multisigCreateKey
                        proposeForm.multisigProgramId = root.multisigProgramId
                        proposeForm.sequencerUrl      = sequencerUrlField.text
                        root.currentView = 3
                    }
                }
            }

            // New Multisig button
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
                    onClicked: { createForm.reset(); root.currentView = 2 }
                }
            }
        }

        // Config bar: sequencer URL + multisig keys
        Rectangle {
            Layout.fillWidth: true; height: configCol.implicitHeight + 16; radius: 8
            color: Theme.palette.backgroundSecondary
            border { color: Theme.palette.borderSecondary; width: 1 }

            ColumnLayout {
                id: configCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Text { text: "Sequencer:"; color: Theme.palette.textTertiary; font.pixelSize: 12 }
                    Rectangle {
                        Layout.fillWidth: true; height: 28; radius: 4
                        color: Theme.palette.backgroundTertiary
                        border { color: sequencerUrlField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                        TextField {
                            id: sequencerUrlField
                            anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                            background: Item {}
                            color: Theme.palette.text
                            text: hasRealModel ? lezMultisigModel.sequencerUrl() : "http://localhost:9000"
                            font { pixelSize: 12; family: "monospace" }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Text { text: "Program ID:"; color: Theme.palette.textTertiary; font.pixelSize: 12 }
                    Rectangle {
                        Layout.fillWidth: true; height: 28; radius: 4
                        color: Theme.palette.backgroundTertiary
                        border { color: progIdField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                        TextField {
                            id: progIdField
                            anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                            background: Item {}
                            color: Theme.palette.text
                            placeholderText: "multisig program id (hex64)"
                            placeholderTextColor: Theme.palette.textTertiary
                            font { pixelSize: 12; family: "monospace" }
                            onTextChanged: root.multisigProgramId = text.trim()
                        }
                    }
                    Text { text: "Create Key:"; color: Theme.palette.textTertiary; font.pixelSize: 12 }
                    Rectangle {
                        Layout.fillWidth: true; height: 28; radius: 4
                        color: Theme.palette.backgroundTertiary
                        border { color: createKeyField.activeFocus ? Theme.palette.primary : Theme.palette.borderSecondary; width: 1 }
                        TextField {
                            id: createKeyField
                            anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                            background: Item {}
                            color: Theme.palette.text
                            placeholderText: "create key (hex64)"
                            placeholderTextColor: Theme.palette.textTertiary
                            font { pixelSize: 12; family: "monospace" }
                            onTextChanged: root.multisigCreateKey = text.trim()
                        }
                    }
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
                Text {
                    text: "Threshold: " + (root.multisigThreshold > 0 ? root.multisigThreshold + " of " + root.multisigMemberCount : "—")
                    color: Theme.palette.textSecondary; font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Members: " + (root.multisigMemberCount > 0 ? root.multisigMemberCount : "—")
                    color: Theme.palette.textSecondary; font.pixelSize: 13
                }
                Item { width: 20 }
                Text {
                    text: "Proposals: " + (hasRealModel ? lezMultisigModel.count : demoModel.count)
                    color: Theme.palette.success; font { pixelSize: 13; bold: true }
                }
                Item { width: 12 }
                // Loading indicator
                Text {
                    visible: hasRealModel && lezMultisigModel.loading
                    text: "⏳ Loading…"
                    color: Theme.palette.warning; font.pixelSize: 12
                }
                // Error indicator
                Text {
                    visible: hasRealModel && lezMultisigModel.error.length > 0
                    text: "⚠ " + (hasRealModel ? lezMultisigModel.error : "")
                    color: Theme.palette.error; font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.maximumWidth: 300
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.palette.borderSecondary }

        // Proposal list — use real model if available, else demo
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 8

                Repeater {
                    model: hasRealModel ? lezMultisigModel : demoModel
                    delegate: ProposalCard {
                        Layout.fillWidth: true
                        proposalIndex:     model.proposalIndex !== undefined ? model.proposalIndex : model.index
                        proposer:          model.proposer || ""
                        targetProgramId:   model.targetProgramId || model.targetProgram || ""
                        approvedCount:     model.approvedCount !== undefined ? model.approvedCount : (model.approved || 0)
                        rejectedCount:     model.rejectedCount !== undefined ? model.rejectedCount : (model.rejected || 0)
                        status:            model.status || "Active"
                        proposalPda:       model.proposalPda || ""
                        threshold:         root.multisigThreshold > 0 ? root.multisigThreshold : 2

                        onClicked: {
                            root.selectedIndex    = proposalIndex
                            root.selectedProposer = proposer
                            root.selectedTarget   = targetProgramId
                            root.selectedApproved = approvedCount
                            root.selectedRejected = rejectedCount
                            root.selectedStatus   = status
                            root.selectedPda      = proposalPda
                            root.selectedThreshold = threshold
                            detailView.actionError  = ""
                            detailView.actionResult = ""
                            detailView.actioning    = false
                            root.currentView = 1
                        }
                    }
                }

                // Empty state
                Text {
                    visible: (hasRealModel ? lezMultisigModel.count : demoModel.count) === 0
                    text: hasRealModel ? "No proposals yet. Create a multisig or refresh." : "Configure sequencer and keys above, then click Refresh."
                    color: Theme.palette.textTertiary
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 40
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Powered by Logos · LEZ Multisig" + (hasModule ? " v" + lezMultisigModule.version() : " v0.1.0")
            color: Theme.palette.textTertiary; font.pixelSize: 11
        }
    }

    // ── Demo fallback model ──────────────────────────────────────────────────
    ListModel {
        id: demoModel
        ListElement { proposalIndex: 0; proposer: "jimmy-claw"; targetProgram: "lez-registry: register(...)"; approved: 2; rejected: 0; status: "Approved" }
        ListElement { proposalIndex: 1; proposer: "logos-team"; targetProgram: "token-factory: mint(1000)"; approved: 1; rejected: 0; status: "Active" }
        ListElement { proposalIndex: 2; proposer: "defi-dev"; targetProgram: "amm-swap: addLiquidity(...)"; approved: 0; rejected: 2; status: "Rejected" }
    }

    // ── View: Proposal Detail ────────────────────────────────────────────────
    ProposalDetail {
        id: detailView
        visible: root.currentView === 1
        anchors.fill: parent

        proposalIndex:   root.selectedIndex
        proposer:        root.selectedProposer
        targetProgramId: root.selectedTarget
        approvedCount:   root.selectedApproved
        rejectedCount:   root.selectedRejected
        status:          root.selectedStatus
        proposalPda:     root.selectedPda
        threshold:       root.selectedThreshold

        onBackRequested: root.currentView = 0

        onApproveRequested: {
            if (!hasModule) { actionError = "Module not loaded"; return }
            actioning = true; actionError = ""; actionResult = ""
            lezMultisigModule.approveAsync(root.proposalArgs(root.selectedIndex))
        }
        onRejectRequested: {
            if (!hasModule) { actionError = "Module not loaded"; return }
            actioning = true; actionError = ""; actionResult = ""
            lezMultisigModule.rejectAsync(root.proposalArgs(root.selectedIndex))
        }
        onExecuteRequested: {
            if (!hasModule) { actionError = "Module not loaded"; return }
            actioning = true; actionError = ""; actionResult = ""
            lezMultisigModule.executeAsync(root.proposalArgs(root.selectedIndex))
        }
    }

    // ── View: Create Multisig ────────────────────────────────────────────────
    CreateMultisigForm {
        id: createForm
        visible: root.currentView === 2
        anchors.fill: parent

        onCancelled: root.currentView = 0
        onSubmitRequested: function(argsJson) {
            if (!hasModule) { submitError = "Module not loaded"; submitting = false; return }
            lezMultisigModule.createMultisigAsync(argsJson)
        }
    }

    // ── View: Propose ────────────────────────────────────────────────────────
    ProposeForm {
        id: proposeForm
        visible: root.currentView === 3
        anchors.fill: parent

        onCancelled: root.currentView = 0
        onSubmitRequested: function(argsJson) {
            if (!hasModule) { submitError = "Module not loaded"; submitting = false; return }
            lezMultisigModule.proposeAsync(argsJson)
        }
    }
}
