import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects

import QFlipper 1.0
import Theme 1.0

Item {
    id: control

    signal screenStreamRequested

    readonly property var deviceState: Backend.deviceState

    width: 408
    height: 270

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
        sourceSize: Qt.size(1260, 834) // full native resolution to stay sharp when upscaled
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    // Hue-rotate the baked illustration so it follows the theme accent.
    HueSaturation {
        anchors.fill: flipperImage
        source: flipperImage
        hue: Theme.deviceSvgHueShift
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

        x: 265
        y: 156

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

        x: 112
        y: 15
        width: 115
        height: 78

        visible: (deviceState && deviceState.isRecoveryMode) ||
                 Backend.backendState === ApplicationBackend.Finished

        source: deviceState && deviceState.isRecoveryMode ? "qrc:/assets/gfx/images/recovery.svg" :
                Backend.backendState === ApplicationBackend.Finished ? "qrc:/assets/gfx/images/success.svg" :
                                                                       ""
        sourceSize: Qt.size(115, 78)
    }

    ScreenCanvas {
        id: screenCanvas

        // Render the 128x64 frame at an integer 4x (512x256) like the full-screen
        // view, then scale that high-res buffer down to the display size below.
        // dispWidth/dispHeight let us size the preview independently (they don't
        // have to keep the native 2:1 aspect) - tweak these to resize the screen.
        readonly property real dispWidth: 115
        readonly property real dispHeight: 62

        zoomFactor: 4
        smooth: true

        transform: Scale {
            xScale: screenCanvas.dispWidth / (screenCanvas.zoomFactor * 128)
            yScale: screenCanvas.dispHeight / (screenCanvas.zoomFactor * 64)
        }

        x: defaultScreen.x
        y: defaultScreen.y + (defaultScreen.height - dispHeight) / 2 + 4

        visible: Backend.screenStreamer.isEnabled &&
                 Backend.backendState > ApplicationBackend.WaitingForDevices &&
                 Backend.backendState < ApplicationBackend.ScreenStreaming

        foregroundColor: Theme.color.darkorange1
        backgroundColor: Theme.color.lightorange2

        frame: Backend.screenStreamer.screenFrame
    }

    ExpandWidget {
        id: expandWidget

        x: 112
        y: 15

        width: 115
        height: 78

        visible: screenCanvas.visible
        opacity: clickArea.hovered ? clickArea.down ? 0.9 : 1 : 0
    }
}
