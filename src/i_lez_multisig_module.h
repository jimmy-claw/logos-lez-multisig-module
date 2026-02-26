#ifndef I_LEZ_MULTISIG_MODULE_H
#define I_LEZ_MULTISIG_MODULE_H

#include <QString>
#include <interface.h>

/**
 * ILezMultisigModule — Public interface for the LEZ Multisig Logos Core module.
 *
 * Exposes on-chain multisig operations (create, propose, approve, reject, execute,
 * list_proposals, get_state) as Q_INVOKABLE Qt methods.
 *
 * All methods accept and return JSON strings for maximum interoperability with
 * the Logos Core inter-module RPC system (LogosAPIClient::invokeRemoteMethod).
 */
class ILezMultisigModule {
public:
    virtual ~ILezMultisigModule() = default;

    // ── Logos Core lifecycle ─────────────────────────────────────────────────

    /**
     * Called by Logos Core after the module is loaded.
     */
    virtual void initLogos(LogosAPI* logosAPIInstance) = 0;

    // ── Multisig Operations ──────────────────────────────────────────────────

    /**
     * Create a new M-of-N multisig.
     * argsJson: { sequencer_url, wallet_path, program_id_hex, account, create_key, threshold, members[] }
     * Returns: { "success": true, "tx_hash": "0x...", "multisig_state_pda": "...", "create_key": "..." }
     */
    virtual QString createMultisig(const QString& argsJson) = 0;

    /**
     * Create a new proposal in a multisig.
     * argsJson: { sequencer_url, wallet_path, program_id_hex, account, create_key,
     *             target_program_id, target_instruction_data, target_account_count,
     *             pda_seeds[], authorized_indices[] }
     * Returns: { "success": true, "tx_hash": "0x...", "proposal_index": N, "proposal_pda": "..." }
     */
    virtual QString propose(const QString& argsJson) = 0;

    /**
     * Approve an existing proposal.
     * argsJson: { sequencer_url, wallet_path, program_id_hex, account, create_key, proposal_index }
     * Returns: { "success": true, "tx_hash": "0x...", "proposal_index": N, "action": "approved" }
     */
    virtual QString approve(const QString& argsJson) = 0;

    /**
     * Reject an existing proposal.
     * argsJson: { sequencer_url, wallet_path, program_id_hex, account, create_key, proposal_index }
     * Returns: { "success": true, "tx_hash": "0x...", "proposal_index": N, "action": "rejected" }
     */
    virtual QString reject(const QString& argsJson) = 0;

    /**
     * Execute a fully-approved proposal.
     * argsJson: { sequencer_url, wallet_path, program_id_hex, account, create_key, proposal_index }
     * Returns: { "success": true, "tx_hash": "0x..." }
     */
    virtual QString execute(const QString& argsJson) = 0;

    /**
     * List proposals for a multisig.
     * argsJson: { sequencer_url, wallet_path, program_id_hex, create_key }
     * Returns: { "success": true, "proposals": [ {...}, ... ] }
     */
    virtual QString listProposals(const QString& argsJson) = 0;

    /**
     * Get the state of a multisig.
     * argsJson: { sequencer_url, wallet_path, program_id_hex, create_key }
     * Returns: { "success": true, "state": { threshold, member_count, members[], ... } }
     */
    virtual QString getState(const QString& argsJson) = 0;

    // ── Version ──────────────────────────────────────────────────────────────

    virtual QString version() const = 0;
};

#define ILezMultisigModule_iid "org.logos.ilezmultisigmodule"
Q_DECLARE_INTERFACE(ILezMultisigModule, ILezMultisigModule_iid)

#endif // I_LEZ_MULTISIG_MODULE_H
