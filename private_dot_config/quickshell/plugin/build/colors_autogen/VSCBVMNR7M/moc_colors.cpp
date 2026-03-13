/****************************************************************************
** Meta object code from reading C++ file 'colors.hpp'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../src/utils/colors.hpp"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'colors.hpp' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.10.2. It"
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
struct qt_meta_tag_ZN6ColorsE_t {};
} // unnamed namespace

template <> constexpr inline auto Colors::qt_create_metaobjectdata<qt_meta_tag_ZN6ColorsE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "Colors",
        "QML.Element",
        "auto",
        "QML.Singleton",
        "true",
        "mix",
        "QColor",
        "",
        "color1",
        "color2",
        "ratio",
        "transparentize",
        "color",
        "amount",
        "applyAlpha",
        "alpha",
        "colorWithHueOf",
        "colorWithSaturationOf",
        "colorWithLightness",
        "lightness",
        "colorWithLightnessOf",
        "adaptToAccent",
        "luminance",
        "isDark"
    };

    QtMocHelpers::UintData qt_methods {
        // Method 'mix'
        QtMocHelpers::MethodData<QColor(const QColor &, const QColor &, qreal)>(5, 7, QMC::AccessPublic, 0x80000000 | 6, {{
            { 0x80000000 | 6, 8 }, { 0x80000000 | 6, 9 }, { QMetaType::QReal, 10 },
        }}),
        // Method 'mix'
        QtMocHelpers::MethodData<QColor(const QColor &, const QColor &)>(5, 7, QMC::AccessPublic | QMC::MethodCloned, 0x80000000 | 6, {{
            { 0x80000000 | 6, 8 }, { 0x80000000 | 6, 9 },
        }}),
        // Method 'transparentize'
        QtMocHelpers::MethodData<QColor(const QColor &, qreal)>(11, 7, QMC::AccessPublic, 0x80000000 | 6, {{
            { 0x80000000 | 6, 12 }, { QMetaType::QReal, 13 },
        }}),
        // Method 'transparentize'
        QtMocHelpers::MethodData<QColor(const QColor &)>(11, 7, QMC::AccessPublic | QMC::MethodCloned, 0x80000000 | 6, {{
            { 0x80000000 | 6, 12 },
        }}),
        // Method 'applyAlpha'
        QtMocHelpers::MethodData<QColor(const QColor &, qreal)>(14, 7, QMC::AccessPublic, 0x80000000 | 6, {{
            { 0x80000000 | 6, 12 }, { QMetaType::QReal, 15 },
        }}),
        // Method 'colorWithHueOf'
        QtMocHelpers::MethodData<QColor(const QColor &, const QColor &)>(16, 7, QMC::AccessPublic, 0x80000000 | 6, {{
            { 0x80000000 | 6, 8 }, { 0x80000000 | 6, 9 },
        }}),
        // Method 'colorWithSaturationOf'
        QtMocHelpers::MethodData<QColor(const QColor &, const QColor &)>(17, 7, QMC::AccessPublic, 0x80000000 | 6, {{
            { 0x80000000 | 6, 8 }, { 0x80000000 | 6, 9 },
        }}),
        // Method 'colorWithLightness'
        QtMocHelpers::MethodData<QColor(const QColor &, qreal)>(18, 7, QMC::AccessPublic, 0x80000000 | 6, {{
            { 0x80000000 | 6, 12 }, { QMetaType::QReal, 19 },
        }}),
        // Method 'colorWithLightnessOf'
        QtMocHelpers::MethodData<QColor(const QColor &, const QColor &)>(20, 7, QMC::AccessPublic, 0x80000000 | 6, {{
            { 0x80000000 | 6, 8 }, { 0x80000000 | 6, 9 },
        }}),
        // Method 'adaptToAccent'
        QtMocHelpers::MethodData<QColor(const QColor &, const QColor &)>(21, 7, QMC::AccessPublic, 0x80000000 | 6, {{
            { 0x80000000 | 6, 8 }, { 0x80000000 | 6, 9 },
        }}),
        // Method 'luminance'
        QtMocHelpers::MethodData<qreal(const QColor &)>(22, 7, QMC::AccessPublic, QMetaType::QReal, {{
            { 0x80000000 | 6, 12 },
        }}),
        // Method 'isDark'
        QtMocHelpers::MethodData<bool(const QColor &)>(23, 7, QMC::AccessPublic, QMetaType::Bool, {{
            { 0x80000000 | 6, 12 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
    };
    QtMocHelpers::UintData qt_enums {
    };
    QtMocHelpers::UintData qt_constructors {};
    QtMocHelpers::ClassInfos qt_classinfo({
            {    1,    2 },
            {    3,    4 },
    });
    return QtMocHelpers::metaObjectData<Colors, void>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums, qt_constructors, qt_classinfo);
}
Q_CONSTINIT const QMetaObject Colors::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN6ColorsE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN6ColorsE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN6ColorsE_t>.metaTypes,
    nullptr
} };

void Colors::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<Colors *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: { QColor _r = _t->mix((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QColor>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[3])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        case 1: { QColor _r = _t->mix((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QColor>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        case 2: { QColor _r = _t->transparentize((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        case 3: { QColor _r = _t->transparentize((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        case 4: { QColor _r = _t->applyAlpha((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        case 5: { QColor _r = _t->colorWithHueOf((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QColor>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        case 6: { QColor _r = _t->colorWithSaturationOf((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QColor>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        case 7: { QColor _r = _t->colorWithLightness((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        case 8: { QColor _r = _t->colorWithLightnessOf((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QColor>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        case 9: { QColor _r = _t->adaptToAccent((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QColor>>(_a[2])));
            if (_a[0]) *reinterpret_cast<QColor*>(_a[0]) = std::move(_r); }  break;
        case 10: { qreal _r = _t->luminance((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])));
            if (_a[0]) *reinterpret_cast<qreal*>(_a[0]) = std::move(_r); }  break;
        case 11: { bool _r = _t->isDark((*reinterpret_cast<std::add_pointer_t<QColor>>(_a[1])));
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        default: ;
        }
    }
}

const QMetaObject *Colors::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *Colors::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN6ColorsE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int Colors::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 12)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 12;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 12)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 12;
    }
    return _id;
}
QT_WARNING_POP
