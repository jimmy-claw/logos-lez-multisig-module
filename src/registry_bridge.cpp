#include "registry_bridge.h"

#include <QDebug>
#include <QJsonArray>
#include <QProcessEnvironment>

// ── Constructor / Destructor ──────────────────────────────────────────────────

RegistryBridge::RegistryBridge(QObject* parent)
    : QObject(parent)
{
}

RegistryBridge::~RegistryBridge() {
    if (m_lib) {
        m_lib->unload();
        delete m_lib;
    }
}

// ── Library loading ───────────────────────────────────────────────────────────

bool RegistryBridge::loadLibrary(const QString& soPath) {
    if (m_loaded) return true;

    // Determine path: explicit arg → env var → default relative path
    QString path = soPath;
    if (path.isEmpty()) {
        path = QProcessEnvironment::systemEnvironment()
                   .value(QStringLiteral("LEZ_REGISTRY_FFI_PATH"),
                          QStringLiteral("liblez_registry_ffi.so"));
    }

    m_lib = new QLibrary(path, this);
    if (!m_lib->load()) {
        setError(QStringLiteral("Failed to load registry FFI library '%1': %2")
                     .arg(path, m_lib->errorString()));
        qWarning() << "RegistryBridge:" << m_lastError;
        return false;
    }

    // Resolve symbols
    m_fnList       = reinterpret_cast<FfiFn1>(m_lib->resolve("lez_registry_list"));
    m_fnGetById    = reinterpret_cast<FfiFn1>(m_lib->resolve("lez_registry_get_by_id"));
    m_fnGetByName  = reinterpret_cast<FfiFn1>(m_lib->resolve("lez_registry_get_by_name"));
    m_fnGetIdl     = reinterpret_cast<FfiFn0>(m_lib->resolve("lez_registry_get_idl"));
    m_fnFreeString = reinterpret_cast<FfiFreeStr>(m_lib->resolve("lez_registry_free_string"));

    if (!m_fnList || !m_fnGetById || !m_fnGetByName || !m_fnGetIdl || !m_fnFreeString) {
        setError(QStringLiteral("Registry FFI library missing required symbols"));
        qWarning() << "RegistryBridge:" << m_lastError;
        m_lib->unload();
        return false;
    }

    m_loaded = true;
    qInfo() << "RegistryBridge: loaded registry FFI from" << path;
    return true;
}

// ── Private helpers ───────────────────────────────────────────────────────────

QString RegistryBridge::callFfi1(FfiFn1 fn, const QString& argsJson) {
    if (!m_loaded || !fn || !m_fnFreeString) {
        return QStringLiteral(R"({"success":false,"error":"Registry FFI not loaded"})");
    }
    const QByteArray utf8 = argsJson.toUtf8();
    char* raw = fn(utf8.constData());
    if (!raw) {
        return QStringLiteral(R"({"success":false,"error":"FFI returned null"})");
    }
    QString result = QString::fromUtf8(raw);
    m_fnFreeString(raw);
    return result;
}

QString RegistryBridge::callFfi0(FfiFn0 fn) {
    if (!m_loaded || !fn || !m_fnFreeString) {
        return QStringLiteral(R"({"success":false,"error":"Registry FFI not loaded"})");
    }
    char* raw = fn();
    if (!raw) {
        return QStringLiteral(R"({"success":false,"error":"FFI returned null"})");
    }
    QString result = QString::fromUtf8(raw);
    m_fnFreeString(raw);
    return result;
}

// ── Public methods ────────────────────────────────────────────────────────────

QVariantList RegistryBridge::listPrograms(const QString& sequencerUrl) {
    m_lastError.clear();
    const QString argsJson = QStringLiteral(R"({"sequencer_url":"%1"})").arg(sequencerUrl);
    const QString result = callFfi1(m_fnList, argsJson);

    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(result.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError) {
        setError(QStringLiteral("JSON parse error: ") + err.errorString());
        return {};
    }
    const QJsonObject root = doc.object();
    if (!root.value(QLatin1String("success")).toBool()) {
        setError(root.value(QLatin1String("error")).toString(QStringLiteral("Unknown error")));
        return {};
    }

    QVariantList programs;
    const QJsonArray arr = root.value(QLatin1String("programs")).toArray();
    for (const QJsonValue& v : arr) {
        programs.append(v.toObject().toVariantMap());
    }
    emit programsLoaded(programs);
    return programs;
}

QVariantMap RegistryBridge::getProgramById(const QString& sequencerUrl, const QString& programId) {
    m_lastError.clear();
    const QString argsJson = QStringLiteral(R"({"sequencer_url":"%1","program_id":"%2"})")
                                 .arg(sequencerUrl, programId);
    const QString result = callFfi1(m_fnGetById, argsJson);

    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(result.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError) {
        setError(QStringLiteral("JSON parse error: ") + err.errorString());
        return {};
    }
    const QJsonObject root = doc.object();
    if (!root.value(QLatin1String("success")).toBool()) {
        setError(root.value(QLatin1String("error")).toString(QStringLiteral("Unknown error")));
        return {};
    }
    return root.value(QLatin1String("program")).toObject().toVariantMap();
}

QVariantMap RegistryBridge::getProgramByName(const QString& sequencerUrl, const QString& name) {
    m_lastError.clear();
    const QString argsJson = QStringLiteral(R"({"sequencer_url":"%1","name":"%2"})")
                                 .arg(sequencerUrl, name);
    const QString result = callFfi1(m_fnGetByName, argsJson);

    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(result.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError) {
        setError(QStringLiteral("JSON parse error: ") + err.errorString());
        return {};
    }
    const QJsonObject root = doc.object();
    if (!root.value(QLatin1String("success")).toBool()) {
        setError(root.value(QLatin1String("error")).toString(QStringLiteral("Unknown error")));
        return {};
    }
    return root.value(QLatin1String("program")).toObject().toVariantMap();
}

QString RegistryBridge::getIdl() {
    m_lastError.clear();
    return callFfi0(m_fnGetIdl);
}

QVariantList RegistryBridge::parseIdl(const QString& idlJson) {
    m_lastError.clear();
    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(idlJson.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError) {
        setError(QStringLiteral("IDL JSON parse error: ") + err.errorString());
        return {};
    }

    QVariantList instructions;
    const QJsonObject root = doc.object();
    const QJsonArray instrArr = root.value(QLatin1String("instructions")).toArray();

    for (const QJsonValue& iv : instrArr) {
        const QJsonObject instr = iv.toObject();
        QVariantMap instrMap;
        instrMap[QStringLiteral("name")] = instr.value(QLatin1String("name")).toString();
        instrMap[QStringLiteral("description")] = instr.value(QLatin1String("description")).toString();

        // Args
        QVariantList args;
        for (const QJsonValue& av : instr.value(QLatin1String("args")).toArray()) {
            const QJsonObject a = av.toObject();
            QVariantMap argMap;
            argMap[QStringLiteral("name")] = a.value(QLatin1String("name")).toString();
            // type may be a string or an object
            const QJsonValue typeVal = a.value(QLatin1String("type"));
            if (typeVal.isString()) {
                argMap[QStringLiteral("type")] = typeVal.toString();
            } else {
                argMap[QStringLiteral("type")] = QString::fromUtf8(
                    QJsonDocument(typeVal.toObject()).toJson(QJsonDocument::Compact));
            }
            argMap[QStringLiteral("description")] = a.value(QLatin1String("description")).toString();
            args.append(argMap);
        }
        instrMap[QStringLiteral("args")] = args;

        // Accounts
        QVariantList accounts;
        for (const QJsonValue& acv : instr.value(QLatin1String("accounts")).toArray()) {
            const QJsonObject ac = acv.toObject();
            QVariantMap acMap;
            acMap[QStringLiteral("name")]     = ac.value(QLatin1String("name")).toString();
            acMap[QStringLiteral("writable")] = ac.value(QLatin1String("writable")).toBool();
            acMap[QStringLiteral("signer")]   = ac.value(QLatin1String("signer")).toBool();
            acMap[QStringLiteral("pda")]      = ac.value(QLatin1String("pda")).toBool();
            acMap[QStringLiteral("description")] = ac.value(QLatin1String("description")).toString();
            accounts.append(acMap);
        }
        instrMap[QStringLiteral("accounts")] = accounts;

        instructions.append(instrMap);
    }
    return instructions;
}
