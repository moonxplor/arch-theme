pragma Singleton
import QtQuick

QtObject {
    // Tokyo Night palette
    readonly property color bg:             "#1a1b26"
    readonly property color bgDark:         "#16161e"
    readonly property color bgLight:        "#24283b"
    readonly property color surface:        "#2f3549"
    readonly property color surfaceVariant: "#3b4261"
    readonly property color fg:             "#c0caf5"
    readonly property color fgDim:          "#9aa5ce"
    readonly property color fgMuted:        "#565f89"

    // Primary accents (Tokyo Night Purple)
    readonly property color accent:         "#bb9af7"
    readonly property color accentGlow:     "#c0caf5"
    readonly property color accentDark:     "#9d7cd8"
    readonly property color mikuPink:       "#f7768e"

    // Semantic colors
    readonly property color blue:           "#7aa2f7"
    readonly property color purple:         "#bb9af7"
    readonly property color red:            "#f7768e"
    readonly property color orange:         "#ff9e64"
    readonly property color yellow:         "#e0af68"
    readonly property color green:          "#73daca"

    // Typography
    readonly property string fontFamily:     "FiraCode Nerd Font"
    readonly property string fontFamilySans: "IBM Plex Sans"
    readonly property int    fontSizeSmall:  14
    readonly property int    fontSize:       18
    readonly property int    fontSizeLarge:  22
    readonly property int    fontWeight:     Font.DemiBold
    readonly property int    fontWeightBold: Font.Bold

    // Geometry
    readonly property bool   showClipboardOnBar: false
    readonly property int    barHeight:          38
    readonly property int    radius:             11
    readonly property int    radiusSmall:        7
    readonly property int    radiusLarge:        14
    readonly property int    borderWidth:        2
    readonly property int    outerGap:           0
    readonly property int    moduleSpacing:      6
    readonly property int    compactPillSize:    34
    readonly property int    pillPaddingHoriz:   14
    readonly property int    compactPaddingLeft: 4
    readonly property int    compactPaddingRight: 8
    readonly property real   pillAlpha:          1.0

    // Standardized Motion & Transition Tokens (Minimal & lightweight for Intel Haswell iGPU)
    readonly property int    durationFast:       0
    readonly property int    durationMedium:     60
    readonly property int    durationSlow:       90
    readonly property int    easingDecelerate:   Easing.OutQuad
    readonly property int    easingEmphasized:   Easing.OutQuad
}
