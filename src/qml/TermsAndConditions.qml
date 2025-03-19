import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import org.qfield
import Theme

/**
 * \ingroup qml
 */
Popup {
  id: termsAndConditionsPopup
  
  property bool accepted: false
  
  signal termsAccepted
  
  modal: true
  closePolicy: Popup.NoAutoClose
  
  width: Math.min(parent.width - 40, 600)
  height: Math.min(parent.height - 40, 800)
  x: (parent.width - width) / 2
  y: (parent.height - height) / 2
  padding: 20
  
  // Settings to store whether terms have been accepted
  Settings {
    id: termsSettings
    category: 'SIGPACGO'
    
    property bool termsAccepted: false
  }
  
  // Check if terms have been accepted before, but use a timer to delay opening
  Component.onCompleted: {
    accepted = termsSettings.termsAccepted
    // Use a timer to delay opening the popup to prevent UI blocking
    if (!accepted) {
      openTimer.start()
      console.log("Terms and conditions will open after a short delay")
    }
  }
  
  // Timer to delay opening the popup
  Timer {
    id: openTimer
    interval: 500 // Half second delay to avoid black screen
    running: false
    repeat: false
    onTriggered: {
      if (!termsAndConditionsPopup.accepted) {
        termsAndConditionsPopup.open()
        console.log("Terms and conditions opened after delay")
      }
    }
  }
  
  background: Rectangle {
    color: Theme.mainBackgroundColor
    border.color: Theme.mainColor
    border.width: 2
    radius: 8
  }
  
  contentItem: ColumnLayout {
    spacing: 20
    
    Text {
      Layout.fillWidth: true
      text: qsTr("Terms and Conditions")
      font.pixelSize: 24
      font.bold: true
      color: Theme.mainColor
      horizontalAlignment: Text.AlignHCenter
    }
    
    ScrollView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical: QfScrollBar {}
      
      TextArea {
        readOnly: true
        wrapMode: TextEdit.Wrap
        textFormat: TextEdit.RichText
        font: Theme.defaultFont
        color: Theme.mainTextColor
        
        text: qsTr("<h3>SIGPACGO Terms and Conditions</h3>
<p>Welcome to SIGPACGO, a mobile application for agricultural field data collection and management.</p>

<h4>1. Acceptance of Terms</h4>
<p>By using SIGPACGO, you agree to these Terms and Conditions. If you do not agree, please do not use the application.</p>

<h4>2. Use of the Application</h4>
<p>SIGPACGO is designed for professional use in agricultural field data collection. You agree to use the application only for its intended purposes.</p>

<h4>3. Data Collection and Privacy</h4>
<p>SIGPACGO may collect location data and other information necessary for its functionality. This data is stored locally on your device unless you explicitly choose to share it.</p>

<h4>4. User Responsibilities</h4>
<p>You are responsible for maintaining the confidentiality of any data you collect using SIGPACGO and for complying with all applicable laws and regulations regarding data collection and use.</p>

<h4>5. Limitations of Liability</h4>
<p>SIGPACGO is provided 'as is' without warranties of any kind. The developers are not liable for any damages arising from the use of the application.</p>

<h4>6. Updates and Changes</h4>
<p>These terms may be updated from time to time. Continued use of SIGPACGO after changes constitutes acceptance of the new terms.</p>

<h4>7. Termination</h4>
<p>We reserve the right to terminate access to SIGPACGO for users who violate these terms.</p>

<h4>8. Contact</h4>
<p>For questions about these terms, please contact support@sigpacgo.com.</p>")
      }
    }
    
    CheckBox {
      id: acceptCheckbox
      text: qsTr("I have read and accept the Terms and Conditions")
      font: Theme.defaultFont
      Layout.fillWidth: true
    }
    
    RowLayout {
      Layout.fillWidth: true
      spacing: 10
      
      Button {
        Layout.fillWidth: true
        text: qsTr("Decline")
        font: Theme.defaultFont
        
        onClicked: {
          // Close the application if terms are declined
          Qt.quit()
        }
      }
      
      Button {
        Layout.fillWidth: true
        text: qsTr("Accept")
        font: Theme.defaultFont
        enabled: acceptCheckbox.checked
        highlighted: true
        
        onClicked: {
          // Save that terms have been accepted
          termsSettings.termsAccepted = true
          accepted = true
          termsAccepted()
          close()
        }
      }
    }
  }
} 