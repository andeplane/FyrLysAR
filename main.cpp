#include <QGuiApplication>
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include "heightreader.h"
#include <iostream>
#include <QPermission>
#include <QPixmap>
#include <QSplashScreen>

int main(int argc, char *argv[])
{
    qmlRegisterType<HeightReader>("HeightReader", 1, 0, "HeightReader");
    QApplication app(argc, argv);

    app.setOrganizationName("FyrLysARCompany");
    app.setOrganizationDomain("fyrlysarcompany.com");
    app.setApplicationName("FyrLysAR");

    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/FyrLysAR/main.qml"_qs);

    QPixmap pixmap(":/images/splash.png");
    QSplashScreen splash(pixmap);
    splash.show();

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    QCameraPermission cameraPermission;
    QLocationPermission locationPermission;

    qApp->requestPermission(cameraPermission, [&engine, &url, &splash](const QPermission &grantedCameraPermission) {
        if (grantedCameraPermission.status() != Qt::PermissionStatus::Granted)
            qWarning("Camera permission is not granted!");
        engine.load(url);
        splash.hide();
    });

    qApp->requestPermission(locationPermission, [&engine, &url](const QPermission &grantedLocationPermission) {
        if (grantedLocationPermission.status() != Qt::PermissionStatus::Granted)
            qWarning("Camera permission is not granted!");

    });

    return app.exec();
}
