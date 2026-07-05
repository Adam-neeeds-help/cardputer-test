import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.impl 2.15
import Qt5Compat.GraphicalEffects

import Theme 1.0

AbstractButton {
    id: control

    property string iconPath
    property string iconName

    // When true, the (purple-baked) normal icon is hue-rotated to follow the
    // theme accent, like ThemedImage. The hover/down states are left untouched
    // so intentional highlights (e.g. the red close-button danger cue) survive.
    // Off by default so callers that manage their own coloring (e.g. the d-pad)
    // are unaffected.
    property bool themed: false

    icon.width: 20
    icon.height: 20

    implicitWidth: icon.width + padding * 2
    implicitHeight: icon.height + padding * 2

    opacity: enabled ? 1.0 : 0.5

    padding: 0

    background: Item {}

    contentItem: Item {
        width: control.icon.width
        height: control.icon.height

        // --- Normal state: themed (hue-shifted to the accent) when requested ---
        IconImage {
            id: normalIcon
            source: "%1/%2.svg".arg(iconPath).arg(iconName)
            sourceSize: Qt.size(control.icon.width, control.icon.height)
            visible: !control.themed
        }

        HueSaturation {
            anchors.fill: normalIcon
            visible: control.themed
            source: normalIcon
            hue: Theme.svgHueShift
            saturation: Theme.accentSat - 1 // gray accent -> grayscale icon
            lightness: Theme.svgLightShift
        }

        // --- Hover / down highlights: kept as baked (unshifted) ---
        IconImage {
            source: "%1/%2_hover.svg".arg(iconPath).arg(iconName)
            sourceSize: Qt.size(control.icon.width, control.icon.height)

            opacity: control.hovered ? 1 : 0

            Behavior on opacity {
                PropertyAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }
        }

        IconImage {
            source: "%1/%2_down.svg".arg(iconPath).arg(iconName)
            sourceSize: Qt.size(control.icon.width, control.icon.height)

            opacity: control.down ? 1 : 0
        }
    }
}
