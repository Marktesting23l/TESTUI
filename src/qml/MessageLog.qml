import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.qfield
import Theme

/**
 * \ingroup qml
 */
Page {
  id: messageLog

  property alias model: table.model
  property bool unreadMessages: false

  signal finished

  visible: false
  focus: visible

  header: QfPageHeader {
    title: qsTr('Message Logs')

    showBackButton: true
    showApplyButton: false
    showCancelButton: false

    topMargin: mainWindow.sceneTopMargin

    onFinished: messageLog.finished()
  }

  ColumnLayout {
    anchors.margins: 8
    anchors.bottomMargin: 8 + mainWindow.sceneBottomMargin
    anchors.fill: parent
    Layout.margins: 0
    spacing: 10

    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: Theme.controlBackgroundColor
      border.color: Theme.controlBorderColor
      border.width: 1

      ListView {
        id: table
        objectName: 'messagesList'
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: QfScrollBar {
        }
        clip: true
        anchors.fill: parent
        spacing: 2

        delegate: Rectangle {
          id: rectangle
          objectName: 'messageItem_' + index
          width: parent ? parent.width : undefined
          height: line.height
          color: "transparent"

          Row {
            id: line
            spacing: 5
            Text {
              id: datetext
              objectName: 'dateText'
              padding: 5
              text: MessageDateTime.replace(' ', '\n')
              font: Theme.tipFont
              color: Theme.secondaryTextColor
            }
            Rectangle {
              id: separator
              width: 0
            }
            Text {
              id: tagtext
              objectName: 'tagText'
              padding: MessageTag ? 5 : 0
              text: MessageTag
              font.pointSize: Theme.tipFont.pointSize
              font.bold: true
              color: Theme.secondaryTextColor
            }
            Text {
              id: messagetext
              objectName: 'messageText'
              padding: 5
              width: rectangle.width - datetext.width - tagtext.width - separator.width - 3 * line.spacing
              text: Message.replace(new RegExp('\n', "gi"), '<br>')
              font: Theme.tipFont
              color: Theme.mainTextColor
              wrapMode: Text.WordWrap
              textFormat: Text.RichText

              MouseArea {
                anchors.fill: parent
                onClicked: {
                  copyHelper.text = messagetext.text;
                  copyHelper.selectAll();
                  copyHelper.copy();
                  displayToast(qsTr("Message text copied"));
                }
              }
            }
          }
        }
      }
    }

    TextEdit {
      id: copyHelper
      visible: false
    }

    //QfButton {
    //  text: qsTr("Log runtime profiler")
    //  Layout.fillWidth: true

    //  onClicked: {
    //    iface.logRuntimeProfiler();
    //  }
    //}

    QfButton {
      text: qsTr("Clear message log")
      Layout.fillWidth: true

      onClicked: {
        table.model.clear();
        displayToast(qsTr("Message log cleared"));
        messageLog.finished();
      }
    }

    
  }

  

    

  Connections {
    target: model

    function onRowsInserted(parent, first, last) {
      if (!visible)
        unreadMessages = true;
    }
  }

  onVisibleChanged: {
    if (visible)
      unreadMessages = false;
  }

  Keys.onReleased: event => {
    if (event.key === Qt.Key_Back || event.key === Qt.Key_Escape) {
      event.accepted = true;
      visible = false;
    }
  }
}
