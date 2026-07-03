import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

import QFlipper 1.0
import Theme 1.0

Item {
    id: control

    signal screenStreamRequested

    readonly property var deviceState: Backend.deviceState

    width: 306
    height: 280

    visible: opacity > 0

    Behavior on x {
        PropertyAnimation {
            easing.type: Easing.InOutQuad
            duration: 350
        }
    }

    Behavior on opacity {
        PropertyAnimation {
            easing.type: Easing.InOutQuad
            duration: 350
        }
    }

    Image {
        id: flipperImage
        anchors.fill: parent
        source: "qrc:/assets/gfx/images/flipper.png"
        sourceSize: Qt.size(1312, 1199) // full native resolution to stay sharp when upscaled
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    // Hue-rotate the baked illustration so it follows the theme accent.
    HueSaturation {
        anchors.fill: flipperImage
        source: flipperImage
        hue: Theme.svgHueShift
        saturation: Theme.accentSat - 1 // gray accent -> grayscale illustration
        lightness: Theme.svgLightShift
    }

    AbstractButton {
        id: clickArea
        width: control.width
        height: control.height
        visible: screenCanvas.visible
        onClicked: control.screenStreamRequested()
    }

    Rectangle {
        id: blueLed
        visible: !!deviceState && deviceState.isRecoveryMode

        x: 199
        y: 162

        width: 9
        height: width

        radius: Math.round(width / 2)
        color: Theme.color.lightblue
    }

    // The Cardputer illustration already draws its own screen content, so
    // only overlay something here when there's an actual status to report
    // (recovery/success) - not for the plain idle/default state.
    Image {
        id: defaultScreen

        x: 85
        y: 52

        visible: (deviceState && deviceState.isRecoveryMode) ||
                 Backend.backendState === ApplicationBackend.Finished

        source: deviceState && deviceState.isRecoveryMode ? "qrc:/assets/gfx/images/recovery.svg" :
                Backend.backendState === ApplicationBackend.Finished ? "qrc:/assets/gfx/images/success.svg" :
                                                                       ""
        sourceSize: Qt.size(82, 55)
    }

    ScreenCanvas {
        id: screenCanvas
        anchors.fill: defaultScreen
        visible: Backend.screenStreamer.isEnabled &&
                 Backend.backendState > ApplicationBackend.WaitingForDevices &&
                 Backend.backendState < ApplicationBackend.ScreenStreaming

        foregroundColor: Theme.color.darkorange1
        backgroundColor: Theme.color.lightorange2

        frame: Backend.screenStreamer.screenFrame
    }

    ExpandWidget {
        id: expandWidget

        x: 85
        y: 52

        width: 82
        height: 55

        visible: screenCanvas.visible
        opacity: clickArea.hovered ? clickArea.down ? 0.9 : 1 : 0
    }
}
