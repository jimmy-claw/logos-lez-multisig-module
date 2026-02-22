#pragma once

#include <QAbstractListModel>
#include <QFuture>
#include <QFutureWatcher>
#include <QJsonArray>
#include <QString>
#include <QList>

#ifdef __cplusplus
extern "C" {
#endif
#include <lez_multisig.h>
#ifdef __cplusplus
}
#endif

/**
 * ProposalListModel — QAbstractListModel backed by the lez_multisig_list_proposals() FFI.
 *
 * Exposes on-chain multisig proposals to QML via standard list model roles.
 * FFI calls are made asynchronously via QtConcurrent to avoid blocking the UI thread.
 */
class ProposalListModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        IndexRole = Qt::UserRole + 1,
        ProposerRole,
        TargetProgramIdRole,
        TargetAccountCountRole,
        ApprovedCountRole,
        RejectedCountRole,
        StatusRole,
        ProposalPdaRole,
        MultisigCreateKeyRole,
    };
    Q_ENUM(Roles)

    explicit ProposalListModel(QObject* parent = nullptr);
    ~ProposalListModel() override = default;

    // ── QAbstractListModel ───────────────────────────────────────────────────
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // ── Properties ──────────────────────────────────────────────────────────
    bool loading() const { return m_loading; }
    QString error() const { return m_error; }

    // ── Configuration ────────────────────────────────────────────────────────
    Q_INVOKABLE void setSequencerUrl(const QString& url);
    Q_INVOKABLE void setCreateKey(const QString& createKey);
    Q_INVOKABLE void setMultisigProgramId(const QString& programId);
    Q_INVOKABLE void setWalletPath(const QString& walletPath);
    Q_INVOKABLE QString sequencerUrl() const { return m_sequencerUrl; }

public slots:
    void refresh();

signals:
    void loadingChanged();
    void errorChanged();
    void countChanged();
    void refreshed();

private:
    struct Proposal {
        quint64 index;
        QString proposer;
        QString targetProgramId;
        quint8  targetAccountCount;
        int     approvedCount;
        int     rejectedCount;
        QString status;
        QString proposalPda;
        QString multisigCreateKey;
    };

    void setLoading(bool v);
    void setError(const QString& e);
    void applyProposals(const QList<Proposal>& proposals);

    QList<Proposal> m_proposals;
    bool m_loading = false;
    QString m_error;
    QString m_sequencerUrl    = QStringLiteral("http://localhost:9000");
    QString m_createKey;
    QString m_multisigProgramId;
    QString m_walletPath;

    QFutureWatcher<QString>* m_watcher = nullptr;
};
