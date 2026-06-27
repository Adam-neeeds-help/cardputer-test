import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import Theme 1.0
import QFlipper 1.0

CustomDialog {
    id: control

    title: qsTr("THEME COLOR")
    closable: true

    readonly property string defaultAccent: "#a64dff"

    // "#rrggbb" from a color value
    function toHex(c) {
        function h(x) { return ("0" + Math.round(x * 255).toString(16)).slice(-2); }
        return "#" + h(c.r) + h(c.g) + h(c.b);
    }

    readonly property var presets: [
        "#ff8a2c", "#ff5a00", "#ffd11a", "#3bd13b", "#00e0a0",
        "#1ad1d1", "#228cff", "#a64dff", "#ff4fa3", "#e0e0e0"
    ]

    contentWidget: Item {
        id: widgetContents
        implicitWidth: 460
        implicitHeight: layout.implicitHeight + 40

        ColumnLayout {
            id: layout
            x: 24
            y: 20
            width: parent.implicitWidth - 48
            spacing: 14

            TextLabel {
                text: qsTr("Presets")
                color: Theme.color.lightorange2
            }

            Grid {
                Layout.alignment: Qt.AlignHCenter
                columns: 5
                spacing: 12

                Repeater {
                    model: control.presets

                    Rectangle {
                        width: 64
                        height: 38
                        radius: 6
                        color: modelData

                        readonly property bool selected:
                            Preferences.accentColor.toLowerCase() === modelData.toLowerCase()

                        border.width: selected ? 3 : 1
                        border.color: selected ? "white" : Qt.rgba(1, 1, 1, 0.25)

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Preferences.accentColor = modelData
                        }
                    }
                }
            }

            TextLabel {
                text: qsTr("Hue")
                color: Theme.color.lightorange2
                Layout.topMargin: 6
            }

            // Rainbow hue bar — click or drag to set the accent hue.
            Rectangle {
                id: hueBar
                Layout.fillWidth: true
                height: 28
                radius: 6

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.000; color: Qt.hsva(0.000, 1, 1, 1) }
                    GradientStop { position: 0.167; color: Qt.hsva(0.167, 1, 1, 1) }
                    GradientStop { position: 0.333; color: Qt.hsva(0.333, 1, 1, 1) }
                    GradientStop { position: 0.500; color: Qt.hsva(0.500, 1, 1, 1) }
                    GradientStop { position: 0.667; color: Qt.hsva(0.667, 1, 1, 1) }
                    GradientStop { position: 0.833; color: Qt.hsva(0.833, 1, 1, 1) }
                    GradientStop { position: 1.000; color: Qt.hsva(1.000, 1, 1, 1) }
                }

                // Knob marking current hue.
                Rectangle {
                    width: 8
                    height: parent.height + 8
                    radius: 3
                    y: -4
                    x: Math.round(Theme.accentHue * (hueBar.width - width))
                    color: "white"
                    border.width: 2
                    border.color: "black"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    function pick(mx) {
                        const hue = Math.max(0, Math.min(1, mx / width));
                        Preferences.accentColor = control.toHex(Qt.hsla(hue, 1, 0.62, 1));
                    }

                    onPressed: function(mouse) { pick(mouse.x); }
                    onPositionChanged: function(mouse) { if(pressed) pick(mouse.x); }
                }
            }

            RowLayout {
                Layout.topMargin: 8
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                spacing: 20

                SmallButton {
                    radius: 7
                    text: qsTr("Reset")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onClicked: Preferences.accentColor = control.defaultAccent
                }

                SmallButton {
                    radius: 7
                    text: qsTr("Done")
                    highlighted: true
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onClicked: control.close()
                }
            }
        }
    }
}
