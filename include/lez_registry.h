/**
 * lez_registry.h — C FFI interface for the LEZ Program Registry
 *
 * Enables Logos Core Qt plugins to interact with the LEZ registry
 * and Logos Storage (Codex) without depending on Rust directly.
 *
 * All functions take/return JSON strings (UTF-8, null-terminated).
 * Caller must free returned strings with lez_registry_free_string().
 *
 * JSON error response format:
 *   { "success": false, "error": "<message>" }
 *
 * JSON success response format varies by function (documented inline).
 */

#ifndef LEZ_REGISTRY_H
#define LEZ_REGISTRY_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/* ── Registry Operations ─────────────────────────────────────────────────── */

/**
 * Register a program in the LEZ registry.
 *
 * args_json: {
 *   "sequencer_url": "http://...",
 *   "wallet_path": "...",
 *   "program_id": "hex_or_comma_u32s",
 *   "name": "my-program",
 *   "version": "0.1.0",
 *   "idl_cid": "bafy...",
 *   "description": "...",
 *   "tags": ["governance", "token"]
 * }
 *
 * Returns: { "success": true, "tx_hash": "0x..." }
 */
char* lez_registry_register(const char* args_json);

/**
 * Update metadata for an existing registry entry (original author only).
 *
 * args_json: {
 *   "sequencer_url": "...",
 *   "wallet_path": "...",
 *   "program_id": "...",
 *   "version": "0.2.0",        // optional: "" to keep unchanged
 *   "idl_cid": "bafy...",      // optional: "" to keep unchanged
 *   "description": "...",      // optional: "" to keep unchanged
 *   "tags": []                 // optional: [] to keep unchanged
 * }
 *
 * Returns: { "success": true, "tx_hash": "0x..." }
 */
char* lez_registry_update(const char* args_json);

/**
 * List all registered programs.
 *
 * args_json: { "sequencer_url": "http://..." }
 *
 * Returns: {
 *   "success": true,
 *   "programs": [
 *     {
 *       "program_id": "...",
 *       "name": "lez-multisig",
 *       "version": "0.1.0",
 *       "author": "0x...",
 *       "idl_cid": "bafy...",
 *       "description": "...",
 *       "tags": ["governance"]
 *     },
 *     ...
 *   ]
 * }
 */
char* lez_registry_list(const char* args_json);

/**
 * Get a single program entry by name.
 *
 * args_json: { "sequencer_url": "...", "name": "lez-multisig" }
 *
 * Returns: { "success": true, "program": { ... } }
 */
char* lez_registry_get_by_name(const char* args_json);

/**
 * Get a single program entry by program_id.
 *
 * args_json: { "sequencer_url": "...", "program_id": "..." }
 *
 * Returns: { "success": true, "program": { ... } }
 */
char* lez_registry_get_by_id(const char* args_json);

/* ── Logos Storage (Codex) Operations ───────────────────────────────────── */

/**
 * Upload a file to Logos Storage, returns CID.
 *
 * args_json: {
 *   "logos_storage_url": "http://localhost:8080",
 *   "file_path": "/path/to/idl.json"
 * }
 *
 * Returns: { "success": true, "cid": "bafy..." }
 */
char* lez_storage_upload(const char* args_json);

/**
 * Download content from Logos Storage by CID.
 *
 * args_json: {
 *   "logos_storage_url": "http://localhost:8080",
 *   "cid": "bafy..."
 * }
 *
 * Returns: { "success": true, "content": "<base64-encoded bytes>" }
 */
char* lez_storage_download(const char* args_json);

/**
 * Fetch and parse IDL JSON from Logos Storage.
 * Convenience wrapper over lez_storage_download that decodes base64 and validates JSON.
 *
 * args_json: {
 *   "logos_storage_url": "http://localhost:8080",
 *   "cid": "bafy..."
 * }
 *
 * Returns: { "success": true, "idl": { ... } }  (IDL JSON object)
 */
char* lez_storage_fetch_idl(const char* args_json);

/* ── Memory Management ───────────────────────────────────────────────────── */

/**
 * Free a string returned by any lez_registry_* or lez_storage_* function.
 * Must be called for every non-NULL return value to avoid memory leaks.
 */
void lez_registry_free_string(char* s);

/* ── Version Info ────────────────────────────────────────────────────────── */

/**
 * Returns the version string of this FFI library.
 * Caller must free with lez_registry_free_string().
 */
char* lez_registry_version(void);


/* ── IDL ─────────────────────────────────────────────────────────────────── */

/**
 * Returns the IDL JSON for the lez-registry program.
 * Caller must free with lez_registry_free_string().
 *
 * Returns: IDL JSON string (UTF-8, null-terminated).
 */
char* lez_registry_get_idl(void);

#ifdef __cplusplus
}
#endif

#endif /* LEZ_REGISTRY_H */
