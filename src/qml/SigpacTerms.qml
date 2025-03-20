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
  id: sigpacTermsPopup
  
  property bool accepted: false
  
  signal termsAccepted
  
  modal: true
  closePolicy: Popup.NoAutoClose
  
  width: Math.min(parent.width - 40, 600)
  height: Math.min(parent.height - 40, 800)
  x: (parent.width - width) / 2
  y: (parent.height - height) / 2
  padding: 20
  
  // Settings to store whether SIGPAC terms have been accepted
  Settings {
    id: sigpacTermsSettings
    category: 'SIGPACGO'
    
    property bool sigpacTermsAccepted: false
  }
  
  // Global settings reference
  Settings {
    id: globalSettings
  }
  
  // Check existing acceptance state, but don't automatically open
  Component.onCompleted: {
    // Check both local component setting and global setting
    if (sigpacTermsSettings.sigpacTermsAccepted || globalSettings.valueBool("SIGPACGO/sigpacTermsAccepted", false)) {
      accepted = true;
      // Make sure both settings are in sync
      sigpacTermsSettings.sigpacTermsAccepted = true;
      globalSettings.setValue("SIGPACGO/sigpacTermsAccepted", true);
    }
    console.log("SIGPAC terms component loaded, acceptance state: " + accepted);
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
      text: qsTr("TÉRMINOS DE USO DE LA INFORMACIÓN DE ALTO VALOR DEL SISTEMA INTEGRADO DE GESTIÓN Y CONTROL (SIGC)")
      font.pixelSize: 20
      font.bold: true
      color: Theme.mainColor
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
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
        
        text: qsTr("<p>Conforme al Reglamento de Ejecución (UE) 2023/138, por el que se establece una lista de conjuntos de datos específicos de alto valor (HVD), que obren en poder de organismos del sector público, y modalidades de publicación y reutilización; los Recintos (capa RECINTOS) y los Elementos del paisaje (capa ELEMENTOS DEL PAISAJE) del SIGPAC, y las Líneas de declaración (capa LINEA DECLARACION) del Sistema Integrado de Gestión y Control (SIGC), tienen la consideración de datos específicos de alto valor, dentro de la categoría Geoespacial.</p>

<p>Esta condición aplica a la versión más actualizada de las citadas capas, si bien el FONDO ESPAÑOL DE GARANTÍA AGRARIA O.A (FEGA) ha establecido que se extienda la consideración de datos HVD a los que en cada momento se visualizan en el Visor Sigpac (datos de la Campaña en curso y datos de la Campaña previa).</p>

<p>En línea con las directrices establecidas en la Directiva (UE) 2019/1024 del Parlamento Europeo y del Consejo de 20 de junio de 2019, relativa a los datos abiertos y la reutilización de la información del sector público, y siguiendo las directrices del Reglamento HVD, el FEGA pone a disposición de todos los usuarios que lo requieran, los datos gráficos y alfanuméricos de las capas RECINTOS, ELEMENTOS DEL PAISAJE y LINEA DECLARACIÓN, considerados de alto valor, para su reutilización en las condiciones de la licencia Creative Commons.Atribución/Reconocimiento (CC BY 4.0).</p>

<p>La licencia permite a los licenciatarios:</p>
<ul>
<li>compartir, copiar, redistribuir y divulgar públicamente, total o parcialmente, en cualquier medio o formato, la información distribuida por el FEGA;</li>
<li>que la información distribuida pueda servir como base a obras derivadas como resultado de su análisis o estudio;</li>
<li>utilizar la información distribuida con fines comerciales o no comerciales;</li>
<li>modificar la información distribuida: remezclarla, transformarla y adaptarla.</li>
</ul>

<p>No se requiere ningún requisito formal o autorización expresa por parte del FEGA para el acceso, descarga o copia, de la información geoespacial distribuida bajo esta licencia. Si bien el acceso a los conjuntos de datos supone la aceptación implícita de los presentes Términos de Uso.</p>

<p>La aceptación de estos Términos de Uso no supone la concesión de los derechos de autor ni propiedad intelectual sobre los conjuntos de datos.</p>

<p>Si bien el FEGA proporciona la información geoespacial de las capas de alto valor del SIGC mediante los sistemas informáticos dispuestos al efecto (Visor Sigpac, WMS, Servicio Atom y otros servicios en la nube) de forma gratuita, en el caso de peticiones que pudieran requerir la distribución de la información mediante soportes físicos, los usuarios o empresas peticionarias deberán dirigir sus solicitudes a la Subdirección General de Ayudas Directas del FEGA (sg.ayudasdirectas@fega.es). Las solicitudes deberán ser aprobadas, quedando esta aprobación sujeta a la disponibilidad de medios personales para su preparación. Tras la autorización pertinente (si así fuere) del Subdirector/a General de Ayudas Directas, se podrá delegar en la Empresa de Tecnologías y Servicios Agrarios, S.A., S.M.E., M.P (TRAGSATEC), la elaboración de un presupuesto, aplicando las tarifas oficiales del Grupo TRAGSA vigentes en ese momento, que recoja los trabajos de preparación de la información objeto de distribución y puesta a disposición de los peticionarios. Aceptado el presupuesto por el peticionario, se elaborará y distribuirá la información solicitada.</p>

<p>A efectos de la licencia CC BY 4.0, se establece el correo electrónico sg.ayudasdirectas@fega.es como el punto de contacto para preguntas y cuestiones relacionadas con los datos de alto valor suministrados por el FEGA.</p>

<h3>Condiciones generales para la redistribución de la información contenida en los conjuntos de datos y el material redistribuido</h3>

<h4>Atribución/Reconocimiento</h4>
<p>La redistribución pública de los conjuntos de datos supone, bajo los términos de la licencia CC BY 4.0, la obligación de reconocer adecuadamente la autoría y citar al FONDO ESPAÑOL DE GARANTÍA AGRARIA O.A. como la fuente de los conjuntos de datos de la forma siguiente:</p>
<p><strong>Fuente de los datos: FONDO ESPAÑOL DE GARANTÍA AGRARIA O.A.</strong></p>
<p>Si se incluye esta cita en formato HTML, puede utilizar el marcado siguiente, o similar:</p>
<p><em>\"Fuente de los datos: FONDO ESPAÑOL DE GARANTÍA AGRARIA O.A.\"</em></p>
<p>Esta cita debe ser visible en todas las copias redistribuidas, de la información distribuida, u otra que incorpore ésta o cualquier derivado.</p>

<h4>Cambios en la información redistribuida y respaldo</h4>
<p>Debe indicarse si se han realizado cambios en la información redistribuida respecto a la originalmente distribuida por el FEGA. En ningún caso está permitido que la redistribución sugiera que el licenciatario tiene el respaldo, participación o patrocinio del FEGA o recibe su apoyo al uso de la información redistribuida. Debe abstenerse de la utilización de cualesquiera denominaciones escritas, gráficas, visuales, auditivas o de cualquier otra naturaleza que puedan sugerir confusión en el usuario final de la participación o apoyo por el FEGA en la actividad del utilizador de la información o del conjunto de datos.</p>
<p>El contenido de la información no debe ser alterado.</p>
<p>El sentido de la información no debe ser desnaturalizado.</p>

<h4>Fechas de la información</h4>
<p>El FEGA podrá, en cualquier momento, añadir, eliminar o modificar los conjuntos de datos publicados, quedando identificados por fechas esos cambios. Complementariamente la información distribuida contendrá datos sobre su fecha de extracción. A partir de esos datos, los licenciatarios deberán identificar, de la forma que crean más conveniente, la información redistribuida con la fecha de la última actualización de la misma (o en su defecto la periodicidad de actualización).</p>

<h4>Sin restricciones adicionales al ejercicio de los derechos bajo la licencia</h4>
<p>Los licenciatarios que redistribuyan la información no podrán aplicar ninguna medida tecnológica efectiva o imponer términos legales que impida a otras personas el acceso a la información redistribuida en las condiciones que la licencia CC BY 4.0 establece.</p>

<h4>Responsabilidad del licenciatario</h4>
<p>El licenciatario que reutilice los datos queda sometido a la Ley 18/2015, de 9 de julio, por la que se modifica la Ley 37/2007, de 16 de noviembre, sobre reutilización de la información del sector público, especialmente a su régimen sancionador, así como a toda la normativa que afecte al uso de la información, al Reglamento (UE) 2016/679 del Parlamento Europeo y del Consejo, de 27 de abril de 2016, relativo a la protección de las personas físicas en lo que respecta al tratamiento de datos personales y a la libre circulación de estos datos y al Real Decreto Legislativo 1/1996, de 12 de abril, por el que se aprueba el Texto refundido de la Ley de propiedad intelectual.</p>

<h4>Exención de garantías</h4>
<p>El FEGA no ofrece ningún tipo de garantía respecto a los conjuntos de datos publicados, por lo que no puede asegurar, a pesar de los esfuerzos por gestionar de forma adecuada los conjuntos de datos, su integridad, actualización, precisión o acceso continuo a dichos conjuntos de datos.</p>

<h4>Limitación de responsabilidad</h4>
<p>El FEGA no será responsable ante el licenciatario de cualquier pérdida, coste, gasto o daño directo, especial, indirecto, incidental, consecuente, punitivo, ejemplar u otro que surja del uso o redistribución de la información distribuida. Los licenciatarios deberán soportar las reclamaciones de terceros a que pueda dar lugar la utilización y redistribución de productos o servicios generados a partir de la información suministrada por el FEGA.</p>
<p>La aceptación de los presentes términos de uso supone que los licenciatarios que utilicen, reproduzcan, modifiquen o redistribuyan los conjuntos de datos, aceptan indemnizar, así como eximir al FEGA de cualquier responsabilidad en la que pudieran incurrir debido las reclamaciones que pudieran originarse por el incumplimiento de estos Términos de Uso o por el mero uso, reproducción, modificación o redistribución de la información.</p>
<p>En el caso de que el FEGA, fuera objeto de acciones legales o fuera sancionado económicamente, el licenciatario deberá responder ante el FEGA, de cuantos gastos, incluso procesales, sanciones o indemnizaciones pudieran declararse, dejando al FEGA totalmente indemne.</p>
<p>El FEGA, por su parte, se reserva el derecho de tomar las correspondientes medidas legales para velar por sus intereses.</p>

<h4>Suspensión del servicio</h4>
<p>El FEGA podrá suspender el acceso a los conjuntos de datos cuando se den las circunstancias técnicas y económicas que así lo determinen. Dicha suspensión será notificada a los usuarios por los medios que se determinen.</p>
<p>El FEGA no será en ningún caso responsable de los efectos que se produzcan sobre la actividad de los usuarios como consecuencia de paradas programadas o técnicas de los servicios de distribución.</p>

<h4>Revocación de la licencia</h4>
<p>La licencia CC BY 4.0 aplicada a los datos distribuidos no puede ser revocada, incluso si luego deja de distribuirse.</p>
<p>Sin embargo, si el licenciatario viola los presentes Términos de uso, la legalidad vigente o utiliza, reproduce, modifica o distribuye los conjuntos de datos de un modo perjudicial o inconveniente, el FEGA podrá cancelar su derecho de uso de la información distribuida y la licencia queda suspendida automáticamente.</p>
<p>La licencia será restablecida automáticamente a partir de la fecha en que la violación sea subsanada, siempre y cuando ésta se subsane dentro de los 30 días siguientes a partir del descubrimiento de la violación.</p>
<p>La cancelación o suspensión no tendrá efecto sobre aquellas personas o entidades que, de buena fe, hayan recibido los conjuntos de datos a través de la persona o entidad objeto de la cancelación o suspensión y que, de otra forma, estén cumpliendo estos Términos de Uso.</p>")
      }
    }
    
    CheckBox {
      id: acceptCheckbox
      text: qsTr("He leído y acepto los Términos de Uso de la Información SIGPAC")
      font: Theme.defaultFont
      Layout.fillWidth: true
    }
    
    RowLayout {
      Layout.fillWidth: true
      spacing: 10
      
      Button {
        Layout.fillWidth: true
        text: qsTr("Rechazar")
        font: Theme.defaultFont
        
        onClicked: {
          // Close the application if terms are declined
          Qt.quit()
        }
      }
      
      Button {
        Layout.fillWidth: true
        text: qsTr("Aceptar")
        font: Theme.defaultFont
        enabled: acceptCheckbox.checked
        highlighted: true
        
        onClicked: {
          // Save that SIGPAC terms have been accepted in both settings
          sigpacTermsSettings.sigpacTermsAccepted = true
          globalSettings.setValue("SIGPACGO/sigpacTermsAccepted", true)
          accepted = true
          console.log("SIGPAC terms accepted and saved to settings")
          termsAccepted()
          close()
        }
      }
    }
  }
} 