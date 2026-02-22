#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QLibrary>
#include <QQmlEngine>

/**
 * RegistryBridge — Qt6 bridge to lez-registry-ffi.
 *
 * Loads liblez_registry_ffi.so at runtime and exposes registry operations
 * as Q_INVOKABLE methods accessible from QML.
 *
 * Usage in QML:
 *   lezRegistryBridge.listPrograms(sequencerUrl)
 *   lezRegistryBridge.getProgram(sequencerUrl, programId)
 *   lezRegistryBridge.getIdl()
 */
class RegistryBridge : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit RegistryBridge(QObject* parent = nullptr);
    ~RegistryBridge() override;

    /**
     * Load the registry FFI shared library.
     * Returns true on success.
     * @param soPath  Path to liblez_registry_ffi.so (or empty to auto-detect).
     */
    bool loadLibrary(const QString& soPath = {});

    [[nodiscard]] bool isLoaded() const { return m_loaded; }

    // ── Q_INVOKABLE registry methods (QML-accessible) ────────────────────────

    /**
     * List all registered programs.
     * Returns parsed list of program maps: [{ name, program_id, version, idl_cid, description, tags }]
     * On error returns empty list; check lastError().
     */
    Q_INVOKABLE QVariantList listPrograms(const QString& sequencerUrl);

    /**
     * Get a single program entry by program ID.
     * Returns a map with program fields, or empty map on error.
     */
    Q_INVOKABLE QVariantMap getProgramById(const QString& sequencerUrl, const QString& programId);

    /**
     * Get a single program entry by name.
     * Returns a map with program fields, or empty map on error.
     */
    Q_INVOKABLE QVariantMap getProgramByName(const QString& sequencerUrl, const QString& name);

    /**
     * Get the IDL JSON for the lez-registry program itself.
     * Returns the raw IDL JSON string.
     */
    Q_INVOKABLE QString getIdl();

    /**
     * Parse an IDL JSON string and return structured instruction list for QML.
     * Returns list of instruction maps: [{ name, args: [{ name, type }], accounts: [{ name, writable, signer }] }]
     */
    Q_INVOKABLE QVariantList parseIdl(const QString& idlJson);

    /**
     * Last error message (empty if no error).
     */
    Q_INVOKABLE QString lastError() const { return m_lastError; }

signals:
    void programsLoaded(const QVariantList& programs);
    void errorOccurred(const QString& error);

private:
    using FfiFn0 = char* (*)();
    using FfiFn1 = char* (*)(const char*);
    using FfiFreeStr = void (*)(char*);

    bool         m_loaded = false;
    QString      m_lastError;

    // FFI function pointers
    FfiFn1      m_fnList       = nullptr;
    FfiFn1      m_fnGetById    = nullptr;
    FfiFn1      m_fnGetByName  = nullptr;
    FfiFn0      m_fnGetIdl     = nullptr;
    FfiFreeStr  m_fnFreeString = nullptr;

    QLibrary* m_lib = nullptr;

    QString callFfi1(FfiFn1 fn, const QString& argsJson);
    QString callFfi0(FfiFn0 fn);

    void setError(const QString& err) {
        m_lastError = err;
        emit errorOccurred(err);
    }
};
