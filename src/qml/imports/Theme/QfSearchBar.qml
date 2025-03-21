import QtQuick
import QtQuick.Controls
import org.qfield
import Theme

Item {
  id: searchBar
  z: 99999  // Very high z-index to ensure it's above other elements
  
  // Default height
  height: 40
  
  // No default anchors - let parent components position this
  
  property alias searchTerm: searchField.displayText
  property string placeHolderText: qsTr("Search")

  signal returnPressed

  Rectangle {
    id: searchBarBackground
    anchors.fill: parent
    radius: 6
    border.width: 1
    z: 99999  // Very high z-index
    color: Theme.mainBackgroundColor
    border.color: searchField.activeFocus ? Theme.mainColor : Theme.controlBorderColor  // Make border always visible

    QfToolButton {
      id: clearButton
      anchors.right: parent.right
      anchors.rightMargin: 0
      anchors.verticalCenter: parent.verticalCenter
      width: 40
      height: 40
      z: 100000  // Even higher z-index
      iconSource: Theme.getThemeVectorIcon('ic_clear_white_24dp')
      iconColor: Theme.mainTextColor
      bgcolor: "transparent"
      visible: searchField.text !== ""
      onClicked: {
        clear();
      }
    }

    QfToolButton {
      id: searchButton
      width: 40
      height: 40
      anchors.left: parent.left
      anchors.leftMargin: 0
      anchors.verticalCenter: parent.verticalCenter
      z: 100000  // Even higher z-index
      bgcolor: "transparent"
      iconSource: Theme.getThemeVectorIcon("ic_baseline_search_white")
      iconColor: Theme.mainTextColor
      onClicked: {
        searchField.focus = true;
      }
    }

    TextField {
      id: searchField
      rightPadding: 7
      anchors.left: searchButton.right
      anchors.right: clearButton.left
      anchors.leftMargin: -16
      anchors.rightMargin: 4
      anchors.verticalCenter: parent.verticalCenter
      height: 40
      z: 99999  // Very high z-index
      selectByMouse: true
      inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhSensitiveData
      placeholderText: (!searchField.activeFocus && text === "" && displayText === "") ? searchBar.placeHolderText : ""
      background: Item {
      }

      Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          searchBar.returnPressed();
        }
      }
    }
  }

  function focusOnTextField() {
    searchField.forceActiveFocus();
  }

  function setSearchTerm(term) {
    searchField.text = term;
  }

  function clear() {
    searchField.text = '';
  }
}
