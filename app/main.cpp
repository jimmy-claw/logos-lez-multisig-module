#include <QApplication>
#include <QDir>
#include <QDebug>
#include <iostream>

extern "C" {
    void logos_core_set_plugins_dir(const char* plugins_dir);
    void logos_core_start();
    void logos_core_cleanup();
    char** logos_core_get_loaded_plugins();
    int logos_core_load_plugin(const char* plugin_name);
}

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    // Set the plugins directory
    QString pluginsDir = QDir::cleanPath(QCoreApplication::applicationDirPath() + "/../modules");
    std::cout << "Setting plugins directory to: " << pluginsDir.toStdString() << std::endl;
    logos_core_set_plugins_dir(pluginsDir.toUtf8().constData());

    // Start the core
    logos_core_start();
    std::cout << "Logos Core started successfully!" << std::endl;

    // Load capability_module first
    std::cout << "Loading plugins in specified order..." << std::endl;
    if (logos_core_load_plugin("capability_module")) {
        std::cout << "Successfully loaded capability_module plugin" << std::endl;
    } else {
        std::cerr << "Failed to load capability_module plugin" << std::endl;
    }

    // Then load lez_multisig_module
    if (logos_core_load_plugin("lez_multisig_module")) {
        std::cout << "Successfully loaded lez_multisig_module plugin" << std::endl;
    } else {
        std::cerr << "Failed to load lez_multisig_module plugin" << std::endl;
    }

    // Print loaded plugins
    char** loadedPlugins = logos_core_get_loaded_plugins();
    if (loadedPlugins) {
        qInfo() << "Currently loaded plugins:";
        for (int i = 0; loadedPlugins[i] != nullptr; i++) {
            qInfo() << "  -" << loadedPlugins[i];
        }
    }

    std::cout << "LEZ Multisig App running — close window to exit." << std::endl;

    int result = app.exec();
    logos_core_cleanup();
    return result;
}
