#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

class QQuickWidget;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private:
    void setupUi();
    QQuickWidget *m_quickWidget = nullptr;
};

#endif // MAINWINDOW_H
