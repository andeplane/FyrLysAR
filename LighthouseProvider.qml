import QtQuick
import QtPositioning
import HeightReader 1.0

Item {
    id: root
    property var lighthouses: []
    property var nearbyLighthouses: []
    property var selfCoord
    property var lastUpdatedCoordScan
    property var lastUpdatedCoordUpdateVisbility
    property real numLighthousesAboveHorizon: 0
    property real numLighthousesNotHiddenByLand: 0
    property real numLighthousesInNearbyList: 0
    property var lighthouseComponent

    property real earthRadius: 6371009 // meters

    onSelfCoordChanged: {
        runLighthouseUpdate()
    }

    Component.onCompleted: {
        lighthouseComponent = Qt.createComponent("qrc:/Lighthouse.qml");
    }

    function runLighthouseUpdate() {
        if (!root.selfCoord || root.lighthouses.length == 0) {
            // We are not ready yet, need to get coordinates and read JSON file
            return
        }


        let shouldScanForNewNearbyLighthouses = lastUpdatedCoordScan===undefined || calculateDistance(root.selfCoord.latitude, root.selfCoord.longitude, lastUpdatedCoordScan.latitude, lastUpdatedCoordScan.longitude) > 1852

        const hasChangedHeightSinceVisibilityUpdate = lastUpdatedCoordUpdateVisbility && (root.selfCoord.altitude !== lastUpdatedCoordUpdateVisbility.altitude)
        let shouldUpdateVisibilityBasedOnLand = lastUpdatedCoordUpdateVisbility===undefined || calculateDistance(root.selfCoord.latitude, root.selfCoord.longitude, lastUpdatedCoordUpdateVisbility.latitude, lastUpdatedCoordUpdateVisbility.longitude) > 20 || hasChangedHeightSinceVisibilityUpdate


        if (shouldScanForNewNearbyLighthouses) {
            root.lighthouses.forEach(lighthouse => {
                if (root.selfCoord.distanceTo(lighthouse.coordinates) < visibilityRange(root.selfCoord.altitude) + visibilityRange(lighthouse.heightOverSea)) {
                    if (nearbyLighthouses.indexOf(lighthouse) < 0) {
                        nearbyLighthouses.push(lighthouse)
                    }
                }
            })
            nearbyLighthouses = [...nearbyLighthouses]
            lastUpdatedCoordScan = QtPositioning.coordinate(root.selfCoord.latitude, root.selfCoord.longitude, root.selfCoord.altitude)
        }
        if (spritesDirty || shouldUpdateVisibilityBasedOnLand) {
            updateVisibilityBasedOnLand(root.selfCoord, nearbyLighthouses)
            lastUpdatedCoordUpdateVisbility = root.selfCoord
            root.spritesDirty = false
        }
    }

    function deg2rad(deg) {
        return deg / 180 * Math.PI
    }

    function visibilityRange(height) {
        return Math.sqrt(2*earthRadius * height)
    }

    function calculateDistance(lat1, lon1, lat2, lon2) {
      lat1 = deg2rad(lat1)
      lat2 = deg2rad(lat2)
      lon1 = deg2rad(lon1)
      lon2 = deg2rad(lon2)

      const dLat = lat2 - lat1
      const dLon = lon2 - lon1
      const a = (Math.pow(Math.sin(dLat / 2), 2) +
        Math.pow(Math.sin(dLon / 2), 2) *
        Math.cos(lat1) * Math.cos(lat2));
      return earthRadius * 2 * Math.asin(Math.sqrt(a))
    }

    function calculateAngle(lat1, lon1, lat2, lon2) {
      lat1 = deg2rad(lat1)
      lat2 = deg2rad(lat2)
      lon1 = deg2rad(lon1)
      lon2 = deg2rad(lon2)

      const dLon = (lon2 - lon1);

      const y = Math.sin(dLon) * Math.cos(lat2);
      const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1)
        * Math.cos(lat2) * Math.cos(dLon);

      return Math.atan2(y, x)
    }

    function updateVisibilityBasedOnLand(selfCoord, lighthouses) {
        numLighthousesNotHiddenByLand = 0
        numLighthousesAboveHorizon = 0
        numLighthousesInNearbyList = nearbyLighthouses.length
        lighthouses.forEach(lighthouse => {
            lighthouse.isHiddenByLand = !heightReader.lineIsAboveLand(selfCoord, lighthouse.coordinates)
            lighthouse.isAboveHorizon = selfCoord.distanceTo(lighthouse.coordinates) < visibilityRange(selfCoord.altitude) + visibilityRange(lighthouse.height)
            if (lighthouse.arSprite) {
                const isVisible = !lighthouse.isHiddenByLand && lighthouse.isAboveHorizon
                lighthouse.arSprite.visible = isVisible
            }

            numLighthousesNotHiddenByLand += !lighthouse.isHiddenByLand ? 1 : 0
            numLighthousesAboveHorizon += lighthouse.isAboveHorizon ? 1 : 0
        })
    }

    function createLighthouse(lighthouseData) {
        const lighthouse_object = lighthouseComponent.createObject(lighthouseContainer, {
            coordinates: QtPositioning.coordinate(lighthouseData.latitude, lighthouseData.longitude, lighthouseData.height),
            heightOverSea: lighthouseData.height,
            pattern: lighthouseData.pattern,
            name: lighthouseData.name,
            maxRange: lighthouseData.maxRange,
            sectors: lighthouseData.sectors
        });
        lighthouse_object.update(selfCoord)
        return lighthouse_object
    }

    Item {
        id: lighthouseContainer
    }

    LighthouseList {
        id: lighthousesSource
        Component.onCompleted: {
            const parsedLighthouses = JSON.parse(jsonString)
            root.lighthouses = []

            // Some lighthouses don't have height from source.
            // Assume 1 meter for calculations
            parsedLighthouses.forEach(lighthouse => {
                if (lighthouse.height === undefined) {
                    lighthouse.height = 1.0
                }

                root.lighthouses.push(createLighthouse(lighthouse))
            })
            runLighthouseUpdate()
        }
    }

    HeightReader {
        id: heightReader
    }
}
