#include "mainwindow.h"

#include <QApplication>
#include <QCoreApplication>
#include <QPluginLoader>
#include <QDebug>
#include <QLabel>
#include <QVBoxLayout>
#include <QDir>
#include <QQuickWidget>
#include <QQmlEngine>
#include <QQmlContext>
#include <QUrl>
#include <QFile>
#include <iostream>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
    setupUi();
}

MainWindow::~MainWindow()
{
}

void MainWindow::setupUi()
{
    QString pluginExtension;
    #if defined(Q_OS_WIN)
        pluginExtension = ".dll";
    #elif defined(Q_OS_MAC)
        pluginExtension = ".dylib";
    #else
        pluginExtension = ".so";
    #endif

    // ── Load multisig plugin ─────────────────────────────────────────────────
    QString multisigPluginPath = QCoreApplication::applicationDirPath() + "/../modules/liblez_multisig_module" + pluginExtension;
    QPluginLoader multisigLoader(multisigPluginPath);

    QObject* multisigPluginObj = nullptr;
    if (multisigLoader.load()) {
        multisigPluginObj = multisigLoader.instance();
        if (multisigPluginObj) {
            std::cout << "[QPluginLoader] LEZ Multisig module loaded successfully" << std::endl;
        }
    } else {
        std::cerr << "[QPluginLoader] Failed to load LEZ Multisig module: "
                  << multisigLoader.errorString().toStdString() << std::endl;
    }

    // ── Load registry plugin ─────────────────────────────────────────────────
    QString registryPluginPath = QCoreApplication::applicationDirPath() + "/../modules/liblez_registry_module" + pluginExtension;
    QPluginLoader registryLoader(registryPluginPath);

    QObject* registryPluginObj = nullptr;
    if (registryLoader.load()) {
        registryPluginObj = registryLoader.instance();
        if (registryPluginObj) {
            std::cout << "[QPluginLoader] LEZ Registry module loaded successfully" << std::endl;
        }
    } else {
        std::cerr << "[QPluginLoader] Failed to load LEZ Registry module: "
                  << registryLoader.errorString().toStdString() << std::endl;
    }

    // ── Create QML widget ────────────────────────────────────────────────────
    m_quickWidget = new QQuickWidget(this);
    m_quickWidget->setResizeMode(QQuickWidget::SizeRootObjectToView);

    QString qmlDir = QCoreApplication::applicationDirPath() + "/../qml";
    m_quickWidget->engine()->addImportPath(qmlDir);

    // ── Expose multisig context properties ───────────────────────────────────
    if (multisigPluginObj) {
        m_quickWidget->engine()->rootContext()->setContextProperty(
            QStringLiteral("lezMultisigModule"), multisigPluginObj);
        QObject* model = multisigPluginObj->findChild<QObject*>(QStringLiteral("proposalListModel"));
        if (model) {
            m_quickWidget->engine()->rootContext()->setContextProperty(
                QStringLiteral("lezMultisigModel"), model);
            std::cout << "[Context] lezMultisigModel exposed to QML" << std::endl;
        } else {
            std::cout << "[Context] ProposalListModel not found — QML will use demo data" << std::endl;
        }
    }

    // ── Expose registry context properties ───────────────────────────────────
    if (registryPluginObj) {
        m_quickWidget->engine()->rootContext()->setContextProperty(
            QStringLiteral("lezRegistryModule"), registryPluginObj);
        QObject* registryModel = registryPluginObj->findChild<QObject*>(QStringLiteral("programListModel"));
        if (registryModel) {
            m_quickWidget->engine()->rootContext()->setContextProperty(
                QStringLiteral("lezRegistryModel"), registryModel);
            std::cout << "[Context] lezRegistryModel exposed to QML" << std::endl;
        } else {
            std::cout << "[Context] ProgramListModel not found — Registry QML will use fallback" << std::endl;
        }
    }

    std::cout << "[Context] All context properties set for QML" << std::endl;

    // ── Load unified QML view ────────────────────────────────────────────────
    QUrl qmlUrl;
    QString localQml = qmlDir + "/UnifiedView.qml";
    if (QFile::exists(localQml)) {
        qmlUrl = QUrl::fromLocalFile(localQml);
    } else {
        qmlUrl = QUrl("qrc:/qml/UnifiedView.qml");
    }

    m_quickWidget->setSource(qmlUrl);

    if (m_quickWidget->status() == QQuickWidget::Error) {
        qWarning() << "QML loading errors:";
        for (const auto &error : m_quickWidget->errors()) {
            qWarning() << "  " << error.toString();
        }
        QWidget* fallbackWidget = new QWidget(this);
        QVBoxLayout* layout = new QVBoxLayout(fallbackWidget);
        QLabel* messageLabel = new QLabel("LEZ Unified QML view failed to load", fallbackWidget);
        QFont font = messageLabel->font();
        font.setPointSize(14);
        messageLabel->setFont(font);
        messageLabel->setAlignment(Qt::AlignCenter);
        layout->addWidget(messageLabel);
        setCentralWidget(fallbackWidget);
    } else {
        setCentralWidget(m_quickWidget);
    }

    setWindowTitle("LEZ Unified App");
    resize(900, 700);
}
