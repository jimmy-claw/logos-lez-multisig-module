#include <QQmlContext>
#include "lez_multisig_module.h"
#include "proposal_list_model.h"

#include <logos_api_provider.h>
#include <logos_api_client.h>

#include <QDebug>
#include "registry_bridge.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QByteArray>
#include <QtConcurrent/QtConcurrent>

// ── Constructor / Destructor ──────────────────────────────────────────────────

LezMultisigModule::LezMultisigModule()
    : m_defaultSequencerUrl(QStringLiteral("http://localhost:9000"))
    , m_defaultWalletPath(QString())
    , m_refreshWatcher(new QFutureWatcher<QString>(this))
    , m_actionWatcher(new QFutureWatcher<QString>(this))
    , m_createWatcher(new QFutureWatcher<QString>(this))
    , m_proposeWatcher(new QFutureWatcher<QString>(this))
{
    // Proposals refresh completion
    connect(m_refreshWatcher, &QFutureWatcher<QString>::finished, this, [this]() {
        const QString result = m_refreshWatcher->result();
        emit proposalsRefreshed(result);
    });

    // Approve/reject/execute completion
    connect(m_actionWatcher, &QFutureWatcher<QString>::finished, this, [this]() {
        const QString resultJson = m_actionWatcher->result();
        QJsonParseError err;
        const QJsonDocument doc = QJsonDocument::fromJson(resultJson.toUtf8(), &err);
        if (err.error != QJsonParseError::NoError) {
            emit actionFailed(QStringLiteral("JSON parse error: ") + err.errorString());
            return;
        }
        const QJsonObject root = doc.object();
        if (!root.value(QLatin1String("success")).toBool()) {
            emit actionFailed(root.value(QLatin1String("error")).toString(QStringLiteral("Unknown error")));
            return;
        }
        QVariantList eventData;
        eventData.append(resultJson);
        emitEvent(QStringLiteral("actionCompleted"), eventData);
        emit actionCompleted(resultJson);
    });

    // Create multisig completion
    connect(m_createWatcher, &QFutureWatcher<QString>::finished, this, [this]() {
        const QString resultJson = m_createWatcher->result();
        QJsonParseError err;
        const QJsonDocument doc = QJsonDocument::fromJson(resultJson.toUtf8(), &err);
        if (err.error != QJsonParseError::NoError) {
            emit actionFailed(QStringLiteral("JSON parse error: ") + err.errorString());
            return;
        }
        const QJsonObject root = doc.object();
        if (!root.value(QLatin1String("success")).toBool()) {
            emit actionFailed(root.value(QLatin1String("error")).toString(QStringLiteral("Unknown error")));
            return;
        }
        emit multisigCreated(resultJson);
    });

    // Create proposal completion
    connect(m_proposeWatcher, &QFutureWatcher<QString>::finished, this, [this]() {
        const QString resultJson = m_proposeWatcher->result();
        QJsonParseError err;
        const QJsonDocument doc = QJsonDocument::fromJson(resultJson.toUtf8(), &err);
        if (err.error != QJsonParseError::NoError) {
            emit actionFailed(QStringLiteral("JSON parse error: ") + err.errorString());
            return;
        }
        const QJsonObject root = doc.object();
        if (!root.value(QLatin1String("success")).toBool()) {
            emit actionFailed(root.value(QLatin1String("error")).toString(QStringLiteral("Unknown error")));
            return;
        }
        emit proposalCreated(resultJson);
    });
}

LezMultisigModule::~LezMultisigModule() = default;

// ── PluginInterface ───────────────────────────────────────────────────────────

QString LezMultisigModule::version() const {
    char* raw = lez_multisig_version();
    if (!raw) {
        return QStringLiteral("unknown");
    }
    QString v = QString::fromUtf8(raw);
    lez_multisig_free_string(raw);
    return v;
}

// ── Logos Core lifecycle ──────────────────────────────────────────────────────

void LezMultisigModule::initLogos(LogosAPI* logosAPIInstance) {
    logosAPI = logosAPIInstance;

    // Create the proposal list model (parented to this module)
    m_model = new ProposalListModel(this);
    m_model->setSequencerUrl(m_defaultSequencerUrl);

    if (!logosAPI) {
        qWarning() << "LezMultisigModule: initLogos called with null LogosAPI";
        qInfo() << "LezMultisigModule: initialized (headless). FFI version:" << version();
        return;
    }

    // NOTE: Do NOT call logosAPI->getProvider()->registerObject() here.
    // In logos_host subprocess mode, the SDK wraps us in a ModuleProxy
    // that handles registration automatically. Calling registerObject()
    // directly causes a segfault in the QHash destructor.

    m_client = logosAPI->getClient(name());
    if (!m_client) {
        qWarning() << "LezMultisigModule: failed to get client handle for" << name();
    }

    const QString seqProp = logosAPI->property("sequencerUrl").toString();
    if (!seqProp.isEmpty()) {
        m_defaultSequencerUrl = seqProp;
        m_model->setSequencerUrl(m_defaultSequencerUrl);
    }

    const QString walletProp = logosAPI->property("walletPath").toString();
    if (!walletProp.isEmpty()) {
        m_defaultWalletPath = walletProp;
    }

    // Expose model and module to QML engine if available
    m_qmlEngine = logosAPI->property("qmlEngine").value<QQmlEngine*>();
    if (m_qmlEngine) {
        m_qmlEngine->rootContext()->setContextProperty(
            QStringLiteral("lezMultisigModel"), m_model);
        m_qmlEngine->rootContext()->setContextProperty(
            QStringLiteral("lezMultisigModule"), this);

        // Create and register registry bridge
        m_registryBridge = new RegistryBridge(this);
        m_registryBridge->loadLibrary(); // uses LEZ_REGISTRY_FFI_PATH env var or default
        m_qmlEngine->rootContext()->setContextProperty(
            QStringLiteral("lezRegistryBridge"), m_registryBridge);

        qInfo() << "LezMultisigModule: QML context properties registered";
    }

    qInfo() << "LezMultisigModule: initialized. FFI version:" << version();
}

// ── Private helpers ───────────────────────────────────────────────────────────

/*static*/
QString LezMultisigModule::callFfi(FfiJsonFn fn, const QString& argsJson) {
    const QByteArray utf8 = argsJson.toUtf8();
    char* raw = fn(utf8.constData());
    if (!raw) {
        return QStringLiteral(R"({"success":false,"error":"FFI returned null"})");
    }
    QString result = QString::fromUtf8(raw);
    lez_multisig_free_string(raw);
    return result;
}

QString LezMultisigModule::mergeWithDefaults(const QString& argsJson) const {
    QJsonObject obj;
    if (!argsJson.isEmpty()) {
        QJsonParseError err;
        const QJsonDocument doc = QJsonDocument::fromJson(argsJson.toUtf8(), &err);
        if (err.error == QJsonParseError::NoError && doc.isObject()) {
            obj = doc.object();
        }
    }
    if (!obj.contains(QLatin1String("sequencer_url"))) {
        obj[QLatin1String("sequencer_url")] = m_defaultSequencerUrl;
    }
    if (!m_defaultWalletPath.isEmpty() && !obj.contains(QLatin1String("wallet_path"))) {
        obj[QLatin1String("wallet_path")] = m_defaultWalletPath;
    }
    return QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Compact));
}

void LezMultisigModule::emitEvent(const QString& eventName, const QVariantList& data) {
    emit eventResponse(eventName, data);
}

// ── Multisig Operations ───────────────────────────────────────────────────────

QString LezMultisigModule::createMultisig(const QString& argsJson) {
    return callFfi(lez_multisig_create, mergeWithDefaults(argsJson));
}

QString LezMultisigModule::propose(const QString& argsJson) {
    return callFfi(lez_multisig_propose, mergeWithDefaults(argsJson));
}

QString LezMultisigModule::approve(const QString& argsJson) {
    return callFfi(lez_multisig_approve, mergeWithDefaults(argsJson));
}

QString LezMultisigModule::reject(const QString& argsJson) {
    return callFfi(lez_multisig_reject, mergeWithDefaults(argsJson));
}

QString LezMultisigModule::execute(const QString& argsJson) {
    return callFfi(lez_multisig_execute, mergeWithDefaults(argsJson));
}

QString LezMultisigModule::listProposals(const QString& argsJson) {
    return callFfi(lez_multisig_list_proposals, mergeWithDefaults(argsJson));
}

QString LezMultisigModule::getState(const QString& argsJson) {
    return callFfi(lez_multisig_get_state, mergeWithDefaults(argsJson));
}

// ── Async wrappers ────────────────────────────────────────────────────────────

void LezMultisigModule::refreshProposalsAsync(const QString& argsJson) {
    const QString merged = mergeWithDefaults(argsJson);
    QFuture<QString> future = QtConcurrent::run([merged]() -> QString {
        const QByteArray utf8 = merged.toUtf8();
        char* raw = lez_multisig_list_proposals(utf8.constData());
        if (!raw) return QStringLiteral(R"({"success":false,"error":"FFI returned null"})");
        QString result = QString::fromUtf8(raw);
        lez_multisig_free_string(raw);
        return result;
    });
    m_refreshWatcher->setFuture(future);
}

void LezMultisigModule::approveAsync(const QString& argsJson) {
    const QString merged = mergeWithDefaults(argsJson);
    QFuture<QString> future = QtConcurrent::run([merged]() -> QString {
        const QByteArray utf8 = merged.toUtf8();
        char* raw = lez_multisig_approve(utf8.constData());
        if (!raw) return QStringLiteral(R"({"success":false,"error":"FFI returned null"})");
        QString result = QString::fromUtf8(raw);
        lez_multisig_free_string(raw);
        return result;
    });
    m_actionWatcher->setFuture(future);
}

void LezMultisigModule::rejectAsync(const QString& argsJson) {
    const QString merged = mergeWithDefaults(argsJson);
    QFuture<QString> future = QtConcurrent::run([merged]() -> QString {
        const QByteArray utf8 = merged.toUtf8();
        char* raw = lez_multisig_reject(utf8.constData());
        if (!raw) return QStringLiteral(R"({"success":false,"error":"FFI returned null"})");
        QString result = QString::fromUtf8(raw);
        lez_multisig_free_string(raw);
        return result;
    });
    m_actionWatcher->setFuture(future);
}

void LezMultisigModule::executeAsync(const QString& argsJson) {
    const QString merged = mergeWithDefaults(argsJson);
    QFuture<QString> future = QtConcurrent::run([merged]() -> QString {
        const QByteArray utf8 = merged.toUtf8();
        char* raw = lez_multisig_execute(utf8.constData());
        if (!raw) return QStringLiteral(R"({"success":false,"error":"FFI returned null"})");
        QString result = QString::fromUtf8(raw);
        lez_multisig_free_string(raw);
        return result;
    });
    m_actionWatcher->setFuture(future);
}

void LezMultisigModule::createMultisigAsync(const QString& argsJson) {
    const QString merged = mergeWithDefaults(argsJson);
    QFuture<QString> future = QtConcurrent::run([merged]() -> QString {
        const QByteArray utf8 = merged.toUtf8();
        char* raw = lez_multisig_create(utf8.constData());
        if (!raw) return QStringLiteral(R"({"success":false,"error":"FFI returned null"})");
        QString result = QString::fromUtf8(raw);
        lez_multisig_free_string(raw);
        return result;
    });
    m_createWatcher->setFuture(future);
}

void LezMultisigModule::proposeAsync(const QString& argsJson) {
    const QString merged = mergeWithDefaults(argsJson);
    QFuture<QString> future = QtConcurrent::run([merged]() -> QString {
        const QByteArray utf8 = merged.toUtf8();
        char* raw = lez_multisig_propose(utf8.constData());
        if (!raw) return QStringLiteral(R"({"success":false,"error":"FFI returned null"})");
        QString result = QString::fromUtf8(raw);
        lez_multisig_free_string(raw);
        return result;
    });
    m_proposeWatcher->setFuture(future);
}
