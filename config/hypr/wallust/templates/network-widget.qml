pragma Singleton
import QtQuick

QtObject {
    readonly property color background: "{{background}}"
    readonly property color foreground: "{{foreground}}"
    readonly property color cursor: "{{cursor}}"
    
    // Core accent shades
    readonly property color primary: "{{color4}}"
    readonly property color secondary: "{{color5}}"
    readonly property color accent: "{{color6}}"
    readonly property color surface: "{{color0}}"
    readonly property color surfaceHover: "{{color8}}"
    
    // Status colors
    readonly property color red: "{{color1}}"
    readonly property color green: "{{color2}}"
    readonly property color yellow: "{{color3}}"
    readonly property color blue: "{{color4}}"
    readonly property color magenta: "{{color5}}"
    readonly property color cyan: "{{color6}}"
  }
