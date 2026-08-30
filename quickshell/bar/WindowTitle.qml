import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components" as Components

Components.Pill {
    id: root

    collapseWhenEmpty: true

    // Bind to the active Wayland toplevel (supported natively in Sway)
    property string activeTitle: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : ""

    isEmpty: activeTitle === ""
    
    // Match max-length: 40 character approx width for monospace
    // Also use Waybar's 14px horizontal padding (Theme.pillPaddingHoriz)
    implicitWidth: Math.min(titleText.implicitWidth + Theme.pillPaddingHoriz * 2, 400)
    
    Text {
        id: titleText
        anchors.centerIn: parent
        width: Math.min(implicitWidth, parent.width - Theme.pillPaddingHoriz * 2)
        
        text: root.activeTitle
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Theme.fontWeight
        
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
