#pragma once

#include "i_lez_multisig_module.h"

#ifdef __cplusplus
extern "C" {
#endif
#include <lez_multisig.h>
#ifdef __cplusplus
}
#endif

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QQmlEngine>
#include <QFutureWatcher>

class ProposalListModel;

/**
 * LezMultisigModule — Qt6 plugin implementation of ILezMultisigModule.
 *
 * Wraps the lez-multisig-ffi C library (liblez_multisig_ffi.so) and
 * exposes on-chain multisig operations as Q_INVOKABLE methods.
 */
class LezMultisigModule final : public QObject, public PluginInterface, public ILezMultisigModule {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID ILezMultisigModule_iid FILE LEZ_MULTISIG_MODULE_METADATA_FILE)
    Q_INTERFACES(PluginInterface)

public:
    LezMultisigModule();
    ~LezMultisigModule() override;

    // ── PluginInterface ──────────────────────────────────────────────────────

    [[nodiscard]] QString name() const override { return QStringLiteral("liblez_multisig_module"); }
    [[nodiscard]] QString version() const override;

    // ── ILezMultisigModule lifecycle ─────────────────────────────────────────

    Q_INVOKABLE void initLogos(LogosAPI* logosAPIInstance) override;

    // ── Multisig Operations ──────────────────────────────────────────────────

    Q_INVOKABLE QString createMultisig(const QString& argsJson) override;
    Q_INVOKABLE QString propose(const QString& argsJson) override;
    Q_INVOKABLE QString approve(const QString& argsJson) override;
    Q_INVOKABLE QString reject(const QString& argsJson) override;
    Q_INVOKABLE QString execute(const QString& argsJson) override;
    Q_INVOKABLE QString listProposals(const QString& argsJson) override;
    Q_INVOKABLE QString getState(const QString& argsJson) override;

    // ── QML-facing async helpers ──────────────────────────────────────────────

    Q_INVOKABLE void refreshProposalsAsync(const QString& argsJson);
    Q_INVOKABLE void approveAsync(const QString& argsJson);
    Q_INVOKABLE void rejectAsync(const QString& argsJson);
    Q_INVOKABLE void executeAsync(const QString& argsJson);
    Q_INVOKABLE void createMultisigAsync(const QString& argsJson);
    Q_INVOKABLE void proposeAsync(const QString& argsJson);

signals:
    void eventResponse(const QString& eventName, const QVariantList& data);
    void proposalsRefreshed(const QString& resultJson);
    void actionCompleted(const QString& resultJson);
    void actionFailed(const QString& error);
    void multisigCreated(const QString& resultJson);
    void proposalCreated(const QString& resultJson);

private:
    LogosAPIClient* m_client = nullptr;
    ProposalListModel* m_model = nullptr;
    QQmlEngine* m_qmlEngine = nullptr;

    QFutureWatcher<QString>* m_refreshWatcher  = nullptr;
    QFutureWatcher<QString>* m_actionWatcher   = nullptr;
    QFutureWatcher<QString>* m_createWatcher   = nullptr;
    QFutureWatcher<QString>* m_proposeWatcher  = nullptr;

    QString m_defaultSequencerUrl;
    QString m_defaultWalletPath;

    using FfiJsonFn = char* (*)(const char*);
    static QString callFfi(FfiJsonFn fn, const QString& argsJson);

    QString mergeWithDefaults(const QString& argsJson) const;
    void emitEvent(const QString& eventName, const QVariantList& data);
};
