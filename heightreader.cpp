#include "heightreader.h"
#include <QDir>
#include <QStandardPaths>

QPointF latlonToUtm33(const QGeoCoordinate& coordinate) {
    // Constants for WGS84 ellipsoid
    double a = 6378137.0;  // semi-major axis in meters
    double f = 1 / 298.257223563;  // flattening
    double e_sq = 2 * f - std::pow(f, 2);  // square of eccentricity
    double k0 = 0.9996;  // scale factor
    int lon_origin = 15;  // central meridian for UTM Zone 33

    // Convert latitude and longitude from degrees to radians
    double lat_rad = qDegreesToRadians(coordinate.latitude());
    double lon_rad = qDegreesToRadians(coordinate.longitude());

    double N = a / std::sqrt(1 - e_sq * std::pow(std::sin(lat_rad), 2));
    double T = std::pow(std::tan(lat_rad), 2);
    double C = e_sq / (1 - e_sq) * std::pow(std::cos(lat_rad), 2);
    double A = std::cos(lat_rad) * (lon_rad - qDegreesToRadians(lon_origin));

    double M = a * ((1 - e_sq / 4 - 3 * std::pow(e_sq, 2) / 64 - 5 * std::pow(e_sq, 3) / 256) * lat_rad -
                    (3 * e_sq / 8 + 3 * std::pow(e_sq, 2) / 32 + 45 * std::pow(e_sq, 3) / 1024) * std::sin(2 * lat_rad) +
                    (15 * std::pow(e_sq, 2) / 256 + 45 * std::pow(e_sq, 3) / 1024) * std::sin(4 * lat_rad) -
                    (35 * std::pow(e_sq, 3) / 3072) * std::sin(6 * lat_rad));

    double x = k0 * N * (A + (1 - T + C) * std::pow(A, 3) / 6 +
                         (5 - 18 * T + std::pow(T, 2) + 72 * C - 58 * e_sq) * std::pow(A, 5) / 120);

    double y = k0 * (M + N * std::tan(lat_rad) * (std::pow(A, 2) / 2 + (5 - T + 9 * C + 4 * std::pow(C, 2)) * std::pow(A, 4) / 24 +
                                                  (61 - 58 * T + std::pow(T, 2) + 600 * C - 330 * e_sq) * std::pow(A, 6) / 720));

    // Adjust for northern and southern hemispheres
    if (coordinate.latitude() < 0) {
        y += 10000000;  // 10 million meter offset for southern hemisphere
    }

    x += 500000;  // 500,000 meter offset for all UTM zones

    return QPointF(x, y);
}

HeightReader::HeightReader() {
    parseTfwMetadataFiles();
}

void HeightReader::parseTfwMetadataFile(QString fileName, QImage image) {
    QFile file(fileName);

    // Check if the file opens successfully
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "Failed to open" << fileName;
        return;
    }

    QTextStream in(&file);
    QVector<double> values;
    while (!in.atEnd()) {
        QString line = in.readLine();
        bool ok;
        double value = line.toDouble(&ok);
        if (ok) {
            values.append(value);
        } else {
            qDebug() << "Failed to convert line to double:" << line;
            return;
        }
    }

    if (values.size() < 6) {
        qDebug() << "Not enough data in file";
        return;
    }

    double delta_x = values[0];
    double delta_y = values[3];
    double x0 = values[4] - delta_x * 0.5;
    double y0 = values[5] - delta_y * 0.5;

    double x1 = x0 + delta_x * image.width();
    double y1 = y0 + delta_y * image.height();

    file.close();

    ImageMetadata metadata = {
        fileName,
        QSizeF(delta_x, delta_y),
        QPointF(x0, y0),
        QPointF(x1, y1),
        image
    };

    imageMetadata.push_back(metadata);
}

void HeightReader::parseTfwMetadataFiles() {
    QDir directory(":/heightdata");
    QStringList files = directory.entryList(QStringList() << "*", QDir::Files);
    foreach (const QString &fileName, files) {
        if (fileName.endsWith("tfw")) {
            QString imageFilename = fileName;
            imageFilename.replace("tfw", "png");

            QImage image(directory.filePath(imageFilename));
            if (image.isNull()) {
                qDebug() << "Whops could not open this file";
            }

            parseTfwMetadataFile(directory.filePath(fileName), image);
        }
    }
}

const ImageMetadata* HeightReader::findFile(double x, double y) const {
    for (const auto& file : imageMetadata) {
        if (file.lower.x() <= x && x <= file.upper.x() &&
            file.upper.y() <= y && y <= file.lower.y()) {
            return &file;
        }
    }

    return nullptr;
}

double HeightReader::findHeight(const QGeoCoordinate& coordinate) {
    QPointF utmCoords = latlonToUtm33(coordinate);

    const ImageMetadata* file = findFile(utmCoords.x(), utmCoords.y());

    if (file) {
        double x0 = file->lower.x();
        double y0 = file->lower.y();
        QSizeF pixelSize = file->pixelSize;

        int xIndex = static_cast<int>((utmCoords.x() - x0) / pixelSize.width());
        int yIndex = static_cast<int>((y0 - utmCoords.y()) / std::abs(pixelSize.height()));
        return file->image.pixelColor(xIndex, yIndex).value() / 255.0 * 60;
    }

    return -1; // Or some other error indication
}

bool HeightReader::lineIsAboveLand(const QGeoCoordinate& source, const QGeoCoordinate& target) {
    const double EarthRadius = 6371000.0; // Average radius of Earth in meters
    double distance = source.distanceTo(target);
    double bearing = source.azimuthTo(target);

    // Calculate the effective radius of curvature at the midpoint
    double midPointHeight = (source.altitude() + target.altitude()) / 2;
    double effectiveRadius = EarthRadius + midPointHeight;

    // Calculate the elevation angle
    double heightDifference = target.altitude() - source.altitude();
    double elevationAngle = std::atan2(heightDifference, distance);

    int numberOfSamples = std::ceil(distance / 50.0);
    for (int i = 1; i < numberOfSamples; ++i) { // Start from 1 to exclude the source point
        QGeoCoordinate samplePoint = source.atDistanceAndAzimuth(i * 50.0, bearing);

        // Calculate the height of the curved path above the Earth's surface at this sample point
        double arcLength = (i * 50.0);
        double curvedPathHeight = effectiveRadius - std::sqrt(std::pow(effectiveRadius, 2) - std::pow(arcLength, 2));

        // Expected height at the sample point
        double expectedHeight = source.altitude() + std::tan(elevationAngle) * arcLength;

        // Actual height from terrain data
        double actualTerrainHeight = findHeight(samplePoint);

        if (actualTerrainHeight + curvedPathHeight > expectedHeight) {
            return false; // Terrain is blocking the line of sight
        }
    }

    return true;
}
