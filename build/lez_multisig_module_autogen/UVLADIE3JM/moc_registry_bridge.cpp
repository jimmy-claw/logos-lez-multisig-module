/****************************************************************************
** Meta object code from reading C++ file 'registry_bridge.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.9.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/registry_bridge.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'registry_bridge.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.9.2. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN14RegistryBridgeE_t {};
} // unnamed namespace

template <> constexpr inline auto RegistryBridge::qt_create_metaobjectdata<qt_meta_tag_ZN14RegistryBridgeE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "RegistryBridge",
        "QML.Element",
        "auto",
        "programsLoaded",
        "",
        "QVariantList",
        "programs",
        "errorOccurred",
        "error",
        "listPrograms",
        "sequencerUrl",
        "getProgramById",
        "QVariantMap",
        "programId",
        "getProgramByName",
        "name",
        "getIdl",
        "parseIdl",
        "idlJson",
        "lastError"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'programsLoaded'
        QtMocHelpers::SignalData<void(const QVariantList &)>(3, 4, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 5, 6 },
        }}),
        // Signal 'errorOccurred'
        QtMocHelpers::SignalData<void(const QString &)>(7, 4, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 8 },
        }}),
        // Method 'listPrograms'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(9, 4, QMC::AccessPublic, 0x80000000 | 5, {{
            { QMetaType::QString, 10 },
        }}),
        // Method 'getProgramById'
        QtMocHelpers::MethodData<QVariantMap(const QString &, const QString &)>(11, 4, QMC::AccessPublic, 0x80000000 | 12, {{
            { QMetaType::QString, 10 }, { QMetaType::QString, 13 },
        }}),
        // Method 'getProgramByName'
        QtMocHelpers::MethodData<QVariantMap(const QString &, const QString &)>(14, 4, QMC::AccessPublic, 0x80000000 | 12, {{
            { QMetaType::QString, 10 }, { QMetaType::QString, 15 },
        }}),
        // Method 'getIdl'
        QtMocHelpers::MethodData<QString()>(16, 4, QMC::AccessPublic, QMetaType::QString),
        // Method 'parseIdl'
        QtMocHelpers::MethodData<QVariantList(const QString &)>(17, 4, QMC::AccessPublic, 0x80000000 | 5, {{
            { QMetaType::QString, 18 },
        }}),
        // Method 'lastError'
        QtMocHelpers::MethodData<QString() const>(19, 4, QMC::AccessPublic, QMetaType::QString),
    };
    QtMocHelpers::UintData qt_properties {
    };
    QtMocHelpers::UintData qt_enums {
    };
    QtMocHelpers::UintData qt_constructors {};
    QtMocHelpers::ClassInfos qt_classinfo({
            {    1,    2 },
    });
    return QtMocHelpers::metaObjectData<RegistryBridge, void>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums, qt_constructors, qt_classinfo);
}
Q_CONSTINIT const QMetaObject RegistryBridge::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN14RegistryBridgeE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN14RegistryBridgeE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN14RegistryBridgeE_t>.metaTypes,
    nullptr
} };

void RegistryBridge::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<RegistryBridge *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->programsLoaded((*reinterpret_cast< std::add_pointer_t<QVariantList>>(_a[1]))); break;
        case 1: _t->errorOccurred((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1]))); break;
        case 2: { QVariantList _r = _t->listPrograms((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast< QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 3: { QVariantMap _r = _t->getProgramById((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast< QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 4: { QVariantMap _r = _t->getProgramByName((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<QString>>(_a[2])));
            if (_a[0]) *reinterpret_cast< QVariantMap*>(_a[0]) = std::move(_r); }  break;
        case 5: { QString _r = _t->getIdl();
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = std::move(_r); }  break;
        case 6: { QVariantList _r = _t->parseIdl((*reinterpret_cast< std::add_pointer_t<QString>>(_a[1])));
            if (_a[0]) *reinterpret_cast< QVariantList*>(_a[0]) = std::move(_r); }  break;
        case 7: { QString _r = _t->lastError();
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = std::move(_r); }  break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (RegistryBridge::*)(const QVariantList & )>(_a, &RegistryBridge::programsLoaded, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (RegistryBridge::*)(const QString & )>(_a, &RegistryBridge::errorOccurred, 1))
            return;
    }
}

const QMetaObject *RegistryBridge::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *RegistryBridge::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN14RegistryBridgeE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int RegistryBridge::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 8)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 8;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 8)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 8;
    }
    return _id;
}

// SIGNAL 0
void RegistryBridge::programsLoaded(const QVariantList & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 0, nullptr, _t1);
}

// SIGNAL 1
void RegistryBridge::errorOccurred(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 1, nullptr, _t1);
}
QT_WARNING_POP
