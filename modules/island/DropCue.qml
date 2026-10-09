import QtQuick
import "../../components"
import "../../services"
import "../../theme"

Item {
    Row {
        anchors.centerIn: parent; spacing: 9; height: Preferences.barHeight
        Icon {anchors.verticalCenter:parent.verticalCenter;icon:"attach_file";size:16;color:Theme.accent}
        PanelText {anchors.verticalCenter:parent.verticalCenter;text:"Drop a file";font.pixelSize:Tokens.pillTextSize;font.weight:Tokens.pillTextWeight}
    }
}
