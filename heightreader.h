#ifndef HEIGHTREADER_H
#define HEIGHTREADER_H

#include <QObject>
#include <QQuickItem>
#include <QGeoCoordinate>
#include <QVector>
#include <QImage>

struct ImageMetadata {
    QString fileName;
    QSizeF pixelSize;
    QPointF lower;
    QPointF upper;
    QImage image;
};

class HeightReader : public QObject
{
    Q_OBJECT
private:
    QVector<ImageMetadata> imageMetadata;
    void parseTfwMetadataFiles();
    void parseTfwMetadataFile(QString fileName, QImage imageFile);

    const ImageMetadata* findFile(double x, double y) const;

public:
    HeightReader();
    Q_INVOKABLE double findHeight(const QGeoCoordinate& coordinate);
    Q_INVOKABLE bool lineIsAboveLand(const QGeoCoordinate &source, const QGeoCoordinate &target);
};

#endif // HEIGHTREADER_H
