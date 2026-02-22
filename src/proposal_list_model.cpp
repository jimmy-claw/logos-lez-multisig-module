#include "proposal_list_model.h"

#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QtConcurrent/QtConcurrent>

ProposalListModel::ProposalListModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_watcher(new QFutureWatcher<QString>(this))
{
    connect(m_watcher, &QFutureWatcher<QString>::finished, this, [this]() {
        const QString resultJson = m_watcher->result();
        setLoading(false);

        QJsonParseError err;
        const QJsonDocument doc = QJsonDocument::fromJson(resultJson.toUtf8(), &err);
        if (err.error != QJsonParseError::NoError) {
            setError(QStringLiteral("JSON parse error: ") + err.errorString());
            return;
        }

        const QJsonObject root = doc.object();
        if (!root.value(QLatin1String("success")).toBool()) {
            setError(root.value(QLatin1String("error")).toString(QStringLiteral("Unknown FFI error")));
            return;
        }

        setError(QString());

        const QJsonArray proposals = root.value(QLatin1String("proposals")).toArray();
        QList<Proposal> parsed;
        parsed.reserve(proposals.size());
        for (const QJsonValue& v : proposals) {
            if (!v.isObject()) continue;
            const QJsonObject p = v.toObject();
            Proposal prop;
            prop.index              = static_cast<quint64>(p.value(QLatin1String("index")).toDouble(0));
            prop.proposer           = p.value(QLatin1String("proposer")).toString();
            prop.targetProgramId    = p.value(QLatin1String("target_program_id")).toString();
            prop.targetAccountCount = static_cast<quint8>(p.value(QLatin1String("target_account_count")).toInt(0));
            prop.approvedCount      = p.value(QLatin1String("approved_count")).toInt(0);
            prop.rejectedCount      = p.value(QLatin1String("rejected_count")).toInt(0);
            prop.status             = p.value(QLatin1String("status")).toString(QStringLiteral("Active"));
            prop.proposalPda        = p.value(QLatin1String("proposal_pda")).toString();
            prop.multisigCreateKey  = p.value(QLatin1String("multisig_create_key")).toString();
            parsed.append(prop);
        }
        applyProposals(parsed);
        emit refreshed();
    });
}

// ── QAbstractListModel ────────────────────────────────────────────────────────

int ProposalListModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid()) return 0;
    return m_proposals.size();
}

QVariant ProposalListModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_proposals.size()) {
        return {};
    }
    const Proposal& p = m_proposals.at(index.row());
    switch (static_cast<Roles>(role)) {
        case IndexRole:             return static_cast<qulonglong>(p.index);
        case ProposerRole:          return p.proposer;
        case TargetProgramIdRole:   return p.targetProgramId;
        case TargetAccountCountRole:return p.targetAccountCount;
        case ApprovedCountRole:     return p.approvedCount;
        case RejectedCountRole:     return p.rejectedCount;
        case StatusRole:            return p.status;
        case ProposalPdaRole:       return p.proposalPda;
        case MultisigCreateKeyRole: return p.multisigCreateKey;
        default:                    return {};
    }
}

QHash<int, QByteArray> ProposalListModel::roleNames() const {
    return {
        { IndexRole,              "proposalIndex"      },
        { ProposerRole,           "proposer"           },
        { TargetProgramIdRole,    "targetProgramId"    },
        { TargetAccountCountRole, "targetAccountCount" },
        { ApprovedCountRole,      "approvedCount"      },
        { RejectedCountRole,      "rejectedCount"      },
        { StatusRole,             "status"             },
        { ProposalPdaRole,        "proposalPda"        },
        { MultisigCreateKeyRole,  "multisigCreateKey"  },
    };
}

// ── Public slots ──────────────────────────────────────────────────────────────

void ProposalListModel::refresh() {
    if (m_loading) return;
    if (m_createKey.isEmpty() || m_multisigProgramId.isEmpty()) {
        setError(QStringLiteral("create_key and multisig_program_id must be set before refreshing"));
        return;
    }
    setLoading(true);
    setError(QString());

    const QString seqUrl    = m_sequencerUrl;
    const QString createKey = m_createKey;
    const QString progId    = m_multisigProgramId;
    const QString wallet    = m_walletPath;

    QFuture<QString> future = QtConcurrent::run([seqUrl, createKey, progId, wallet]() -> QString {
        QJsonObject obj;
        obj[QLatin1String("sequencer_url")]       = seqUrl;
        obj[QLatin1String("multisig_program_id")] = progId;
        obj[QLatin1String("create_key")]           = createKey;
        if (!wallet.isEmpty()) {
            obj[QLatin1String("wallet_path")] = wallet;
        }
        const QByteArray argsUtf8 = QJsonDocument(obj).toJson(QJsonDocument::Compact);

        char* raw = lez_multisig_list_proposals(argsUtf8.constData());
        if (!raw) {
            return QStringLiteral(R"({"success":false,"error":"FFI returned null"})");
        }
        QString result = QString::fromUtf8(raw);
        lez_multisig_free_string(raw);
        return result;
    });

    m_watcher->setFuture(future);
}

void ProposalListModel::setSequencerUrl(const QString& url) {
    if (m_sequencerUrl != url) {
        m_sequencerUrl = url;
    }
}

void ProposalListModel::setCreateKey(const QString& createKey) {
    if (m_createKey != createKey) {
        m_createKey = createKey;
    }
}

void ProposalListModel::setMultisigProgramId(const QString& programId) {
    if (m_multisigProgramId != programId) {
        m_multisigProgramId = programId;
    }
}

void ProposalListModel::setWalletPath(const QString& walletPath) {
    if (m_walletPath != walletPath) {
        m_walletPath = walletPath;
    }
}

// ── Private helpers ───────────────────────────────────────────────────────────

void ProposalListModel::setLoading(bool v) {
    if (m_loading != v) {
        m_loading = v;
        emit loadingChanged();
    }
}

void ProposalListModel::setError(const QString& e) {
    if (m_error != e) {
        m_error = e;
        emit errorChanged();
    }
}

void ProposalListModel::applyProposals(const QList<Proposal>& proposals) {
    beginResetModel();
    m_proposals = proposals;
    endResetModel();
    emit countChanged();
}
