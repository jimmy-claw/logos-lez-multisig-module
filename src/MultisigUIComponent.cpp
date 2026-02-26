#include "MultisigUIComponent.h"
#include "lez_multisig_module.h"
#include "proposal_list_model.h"

#include <QQuickWidget>
#include <QQmlContext>

QWidget* MultisigUIComponent::createWidget(LogosAPI* logosAPI) {
    auto* quickWidget = new QQuickWidget();
    quickWidget->setMinimumSize(400, 300);
    quickWidget->setResizeMode(QQuickWidget::SizeRootObjectToView);

    auto* backend = new LezMultisigModule();
    backend->setParent(quickWidget);

    if (logosAPI) {
        backend->initLogos(logosAPI);
    }

    quickWidget->rootContext()->setContextProperty("lezMultisigModule", backend);

    ProposalListModel* model = backend->proposalModel();
    if (model) {
        quickWidget->rootContext()->setContextProperty("lezMultisigModel", model);
    }

    quickWidget->setSource(QUrl("qrc:/lez-multisig/LezMultisigView.qml"));

    return quickWidget;
}

void MultisigUIComponent::destroyWidget(QWidget* widget) {
    delete widget;
}
