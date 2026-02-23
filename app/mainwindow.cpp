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

    QString pluginPath = QCoreApplication::applicationDirPath() + "/../modules/liblez_multisig_module" + pluginExtension;
    QPluginLoader loader(pluginPath);

    if (loader.load()) {
        QObject* plugin = loader.instance();
        if (plugin) {
            qInfo() << "LEZ Multisig module plugin loaded successfully";
        }
    } else {
        qWarning() << "Failed to load LEZ Multisig module from:" << pluginPath;
        qWarning() << "Error:" << loader.errorString();
    }

    m_quickWidget = new QQuickWidget(this);
    m_quickWidget->setResizeMode(QQuickWidget::SizeRootObjectToView);

    QString qmlDir = QCoreApplication::applicationDirPath() + "/../qml";
    m_quickWidget->engine()->addImportPath(qmlDir);

    QUrl qmlUrl;
    QString localQml = qmlDir + "/LezMultisigView.qml";
    if (QFile::exists(localQml)) {
        qmlUrl = QUrl::fromLocalFile(localQml);
    } else {
        qmlUrl = QUrl("qrc:/qml/LezMultisigView.qml");
    }

    m_quickWidget->setSource(qmlUrl);

    if (m_quickWidget->status() == QQuickWidget::Error) {
        qWarning() << "QML loading errors:";
        for (const auto &error : m_quickWidget->errors()) {
            qWarning() << "  " << error.toString();
        }
        QWidget* fallbackWidget = new QWidget(this);
        QVBoxLayout* layout = new QVBoxLayout(fallbackWidget);
        QLabel* messageLabel = new QLabel("LEZ Multisig QML view failed to load", fallbackWidget);
        QFont font = messageLabel->font();
        font.setPointSize(14);
        messageLabel->setFont(font);
        messageLabel->setAlignment(Qt::AlignCenter);
        layout->addWidget(messageLabel);
        setCentralWidget(fallbackWidget);
    } else {
        setCentralWidget(m_quickWidget);
    }

    setWindowTitle("LEZ Multisig");
    resize(800, 600);
}
