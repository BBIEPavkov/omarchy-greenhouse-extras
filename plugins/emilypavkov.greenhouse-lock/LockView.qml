import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false
  property int lastPasswordLength: 0
  property bool celebrating: false
  property date now: new Date()
  // Slow drift of the whole layout so nothing stays on the same pixels.
  property real driftX: 0
  property real driftY: 0

  SequentialAnimation on driftX {
    loops: Animation.Infinite
    NumberAnimation { from: -24; to: 24; duration: 47000; easing.type: Easing.InOutSine }
    NumberAnimation { from: 24; to: -24; duration: 47000; easing.type: Easing.InOutSine }
  }

  SequentialAnimation on driftY {
    loops: Animation.Infinite
    NumberAnimation { from: -16; to: 16; duration: 31000; easing.type: Easing.InOutSine }
    NumberAnimation { from: 16; to: -16; duration: 31000; easing.type: Easing.InOutSine }
  }

  // Leaf greens are shifted from the theme accent so any theme still gets a
  // matching spread: deeper, brighter, warmer (pothos) and cooler (snake plant).
  // Pink Princess philodendron pink, for the blossoms and petals.
  readonly property var petalColors: ["#D98FA8", "#EAB0C2", "#C97A95"]

  readonly property var leafColors: [
    Color.accent,
    Qt.darker(Color.accent, 1.35),
    Qt.lighter(Color.accent, 1.3),
    Qt.hsla(Math.max(0, Color.accent.hslHue - 0.06), Color.accent.hslSaturation, Math.min(0.75, Color.accent.hslLightness * 1.15), 1),
    Qt.hsla(Math.min(1, Color.accent.hslHue + 0.08), Color.accent.hslSaturation * 0.8, Color.accent.hslLightness * 0.9, 1)
  ]

  readonly property string placeholderText: "Welcome back 🌸"
  readonly property int fieldWidth: 381
  readonly property int fieldHeight: 67
  readonly property int outlineThickness: 3
  readonly property int fieldFontSize: Math.round(Style.font.heading * 1.125)
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.4)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.3)
  // Space to keep clear on each side of the field for the fingerprint icon
  // (icon width plus a gap) so the centered dots never run under it.
  readonly property real fingerprintReserve: fingerprintConfigured ? Math.round(fingerprintIcon.implicitWidth + 12) : 0
  // Shrink the dots to fit once the password outgrows the field, so every
  // keystroke stays visible — otherwise long passwords clip with no feedback.
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Color.lock.borderError, root.outlineThickness, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", Color.lock.borderActive, root.outlineThickness, "border-alpha")

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  // Cache-busts the lock background by appending `?v=`. Adding a query
  // string keeps Image's loader happy while forcing it to reload when the
  // user picks a new background mid-session.
  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onFailureMessageChanged: {
    if (failureMessage.length === 0) return
    shake.restart()
    dropAnim.restart()
  }
  onCelebratingChanged: {
    if (!celebrating) return
    spawnBurst(inputField.x + inputField.width / 2, inputField.y + inputField.height / 2, 50, 420)
    for (var i = 0; i < 4; i++)
      spawnBurst(Math.random() * width, Math.random() * height, 12, 160)
  }

  function spawnBurst(cx, cy, count, distance) {
    for (var i = 0; i < count; i++) {
      var angle = Math.random() * Math.PI * 2
      var dist = distance * (0.4 + Math.random() * 0.6)
      var petal = Math.random() < 0.55
      (petal ? burstPetal : burstLeaf).createObject(bursts, {
        startX: cx, startY: cy,
        endX: cx + Math.cos(angle) * dist,
        endY: cy + Math.sin(angle) * dist,
        leafColor: petal
          ? root.petalColors[Math.floor(Math.random() * root.petalColors.length)]
          : root.leafColors[Math.floor(Math.random() * root.leafColors.length)]
      })
    }
  }

  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  // Bundled so the plugin works without the font installed system-wide.
  FontLoader {
    id: fraunces
    source: Qt.resolvedUrl("Fraunces.ttf")
  }

  // Measures the masked password at full size; passwordDotScale compares this
  // against the field width to decide how far the dots must shrink to fit.
  TextMetrics {
    id: dotMetrics
    font: passwordInput.font
    text: "❦".repeat(passwordInput.text.length)
  }

  // A pothos-style heart leaf hanging from its stem point at (0, 0).
  component Leaf: Shape {
    id: leaf
    property real leafWidth: 30
    property real leafLength: 40
    property color leafColor: Color.accent
    width: leafWidth
    height: leafLength
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: leaf.leafColor
      strokeColor: "transparent"
      startX: 0; startY: 0
      PathCubic {
        x: 0; y: leaf.leafLength
        control1X: -leaf.leafWidth * 0.8; control1Y: -leaf.leafLength * 0.2
        control2X: -leaf.leafWidth * 0.5; control2Y: leaf.leafLength * 0.7
      }
      PathCubic {
        x: 0; y: 0
        control1X: leaf.leafWidth * 0.5; control1Y: leaf.leafLength * 0.7
        control2X: leaf.leafWidth * 0.8; control2Y: -leaf.leafLength * 0.2
      }
    }

    ShapePath {
      fillColor: "transparent"
      strokeColor: Qt.lighter(leaf.leafColor, 1.35)
      strokeWidth: 1.2
      startX: 0; startY: leaf.leafLength * 0.05
      PathQuad { x: 0; y: leaf.leafLength * 0.85; controlX: leaf.leafWidth * 0.06; controlY: leaf.leafLength * 0.45 }
    }
  }

  // A five-petal blossom centered on (0, 0).
  component Blossom: Item {
    id: blossom
    property real size: 18
    property color petalColor: root.petalColors[0]

    Repeater {
      model: 5

      Rectangle {
        required property int index
        width: blossom.size * 0.55
        height: blossom.size * 0.38
        radius: height / 2
        color: blossom.petalColor
        x: 0
        y: -height / 2
        transformOrigin: Item.Left
        rotation: index * 72 - 90
      }
    }

    Rectangle {
      width: blossom.size * 0.24
      height: width
      radius: width / 2
      x: -width / 2
      y: -height / 2
      color: "#E8D08A"
    }
  }

  Rectangle {
    anchors.fill: parent
    color: Color.background

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: root.loadBackground && wallpaper.status === Image.Ready
      blur: 1.0
      blurMax: 128
      blurMultiplier: 1.25
      contrast: -0.08
      brightness: -0.12
    }

    // Pothos vines hanging from the top edge. Each one grows down when the
    // lock opens, its leaves unfurl in turn, then it sways.
    Item {
      id: vines
      anchors.fill: parent

      Repeater {
        model: 8

        Item {
          id: vine
          required property int index
          readonly property real length: vines.height * (0.22 + ((index * 37) % 10) / 10 * 0.4)
          readonly property int leafCount: Math.max(4, Math.round(length / 42))
          readonly property real wave: 10 + (index % 3) * 6
          property real grown: 0
          // Four vines on each side, clear of the middle third.
          x: (index < 4 ? vines.width * (0.03 + index * 0.085) : vines.width * (0.69 + (index - 4) * 0.085)) + ((index * 53) % 30 - 15)
          y: -4
          width: 1
          height: length
          transformOrigin: Item.Top

          NumberAnimation on grown {
            running: vines.height > 0
            from: 0; to: 1
            duration: 2600 + vine.index * 180
            easing.type: Easing.OutCubic
          }

          SequentialAnimation on rotation {
            loops: Animation.Infinite
            running: vine.grown > 0.99
            NumberAnimation { from: -1.2; to: 1.2; duration: 5200 + vine.index * 300; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1.2; to: -1.2; duration: 5200 + vine.index * 300; easing.type: Easing.InOutSine }
          }

          // The stem, revealed from the top as the vine grows.
          Item {
            width: vine.wave * 2 + 8
            x: -width / 2
            height: vine.length * vine.grown
            clip: true

            Shape {
              preferredRendererType: Shape.CurveRenderer
              ShapePath {
                strokeColor: Qt.darker(Color.accent, 1.6)
                strokeWidth: 2.5
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: vine.wave + 4; startY: 0
                PathQuad { x: vine.wave + 4; y: vine.length / 2; controlX: vine.wave * 2 + 4; controlY: vine.length / 4 }
                PathQuad { x: vine.wave + 4; y: vine.length; controlX: 4; controlY: vine.length * 3 / 4 }
              }
            }
          }

          Repeater {
            model: vine.leafCount

            Leaf {
              id: vineLeaf
              required property int index
              readonly property real t: (index + 1) / (vine.leafCount + 0.5)
              readonly property bool leftSide: index % 2 === 0
              readonly property real restAngle: leftSide ? 35 + (index * 13) % 20 : -35 - (index * 17) % 20
              // Unfurls once the stem has grown past this leaf.
              readonly property real open: Math.max(0, Math.min(1, (vine.grown - t) * 6))
              leafWidth: 22 + ((vine.index + index) * 7) % 14
              leafLength: leafWidth * 1.25
              leafColor: root.leafColors[(vine.index + index) % root.leafColors.length]
              x: Math.sin(t * Math.PI * 2) * vine.wave * 0.5
              y: vine.length * t
              opacity: 0.92 * open
              scale: 0.2 + 0.8 * open
              transformOrigin: Item.TopLeft
              rotation: restAngle * open + (leftSide ? 90 : -90) * (1 - open)

              Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
            }
          }

          // Blossoms open between the leaves once the vine has grown past them.
          Repeater {
            model: Math.max(1, Math.floor(vine.leafCount / 3))

            Blossom {
              required property int index
              readonly property real t: (index * 3 + 2.5) / (vine.leafCount + 0.5)
              readonly property real open: Math.max(0, Math.min(1, (vine.grown - t) * 4))
              size: 24 + ((vine.index + index) * 5) % 10
              petalColor: root.petalColors[(vine.index + index) % root.petalColors.length]
              x: Math.sin(t * Math.PI * 2) * vine.wave * 0.5
              y: vine.length * t
              scale: open
              rotation: 40 * (1 - open) + vine.index * 11
              opacity: 0.95
            }
          }
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: function(mouse) {
        root.wakeRequested()
        root.forcePasswordFocus()
        root.spawnBurst(mouse.x, mouse.y, 10, 110)
      }
      onPositionChanged: root.wakeRequested()
    }

    Column {
      transform: Translate { x: root.driftX; y: root.driftY }
      layer.enabled: true
      layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.5
        shadowBlur: 0.8
      }
      anchors.bottom: inputField.top
      anchors.bottomMargin: 44
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 0

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(root.now, "h:mm")
        font.italic: true
        color: Color.lock.text
        font.family: fraunces.name
        font.variableAxes: { "wght": 300, "opsz": 144, "SOFT": 100 }
        font.pixelSize: Math.round(Style.font.heading * 8)
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(root.now, "dddd, MMMM d")
        color: Color.lock.text
        font.family: fraunces.name
        font.italic: true
        font.variableAxes: { "wght": 400, "SOFT": 100 }
        font.pixelSize: Math.round(Style.font.heading * 2)
      }

      Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
      }
    }

    BorderSurface {
      transform: Translate { x: root.driftX; y: root.driftY }
      id: inputField
      width: root.fieldWidth
      height: root.fieldHeight
      anchors.centerIn: parent
      anchors.verticalCenterOffset: 60
      color: Color.lock.background
      borderSpec: root.inputBorderSpec
      radius: height / 2
      clip: true

      SequentialAnimation {
        id: shake
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: -12; duration: 50 }
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: 12; duration: 70 }
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: -6; duration: 70 }
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
      }

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.topMargin: inputField.borderTop
        // Reserve the fingerprint icon's width on both sides so the centered
        // dots stay symmetric and never slide under the icon as they grow.
        anchors.rightMargin: inputField.borderRight + 18 + root.fingerprintReserve
        anchors.bottomMargin: inputField.borderBottom
        anchors.leftMargin: inputField.borderLeft + 18 + root.fingerprintReserve
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        activeFocusOnPress: true
        clip: true
        enabled: root.inputEnabled && !root.authenticatingPassword
        readOnly: root.authenticatingPassword
        echoMode: TextInput.Password
        passwordCharacter: "❦"
        passwordMaskDelay: 0
        color: Color.lock.borderActive
        selectionColor: Color.lock.selection
        selectedTextColor: Color.lock.text
        font.family: "DejaVu Sans"
        font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
        font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
        cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
        cursorDelegate: Rectangle {
          width: 2
          color: Color.lock.text
          visible: passwordInput.cursorVisible
        }

        onTextChanged: {
          root.lastPasswordLength = text.length
          if (!root.syncingPasswordText) root.passwordTextEdited(text)
          if (text.length > 0) {
            root.wakeRequested()
          }
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: {
          var submitted = root.passwordText
          root.passwordTextEdited("")
          if (submitted.length > 0) root.submitPassword(submitted)
        }

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            root.passwordTextEdited("")
            event.accepted = true
          }
        }
      }

      Text {
        anchors.fill: passwordInput
        text: root.authenticatingPassword ? "Checking…" : (root.failureMessage.length > 0 ? root.failureMessage : root.placeholderText)
        visible: passwordInput.text.length === 0
        color: root.authenticatingPassword ? Color.lock.text : (root.failureMessage.length > 0 ? Color.lock.textError : Color.lock.placeholder)
        font.family: fraunces.name
        font.pixelSize: root.fieldFontSize
        font.italic: !root.authenticatingPassword && root.failureMessage.length > 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }

      // Fingerprint hint pinned inside the field's right edge when a sensor is
      // enrolled, so the user knows they can touch to unlock instead of typing.
      // Matches hyprlock, which draws its fingerprint icon in the same spot.
      Text {
        id: fingerprintIcon
        objectName: "fingerprintIndicator"
        anchors.right: parent.right
        anchors.rightMargin: inputField.borderRight + 18
        anchors.verticalCenter: parent.verticalCenter
        visible: root.fingerprintConfigured
        text: "󰈷"
        color: Color.lock.placeholder
        font.family: Style.font.family
        font.pixelSize: Math.round(root.fieldFontSize * 1.1)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    // A water drop falls past the field on a wrong password.
    Text {
      id: drop
      transform: Translate { x: root.driftX; y: root.driftY }
      x: inputField.x + inputField.width + 18
      text: "💧"
      font.family: "Noto Color Emoji"
      font.pixelSize: Math.round(root.fieldFontSize * 1.4)
      opacity: 0

      SequentialAnimation {
        id: dropAnim
        ParallelAnimation {
          NumberAnimation { target: drop; property: "opacity"; from: 0; to: 1; duration: 150 }
          NumberAnimation { target: drop; property: "y"; from: inputField.y - 40; to: inputField.y + 10; duration: 450; easing.type: Easing.OutBounce }
        }
        PauseAnimation { duration: 800 }
        NumberAnimation { target: drop; property: "opacity"; to: 0; duration: 400 }
      }
    }

    // Leaf bursts on click and unlock.
    Item {
      id: bursts
      anchors.fill: parent
    }

    Component {
      id: burstPetal

      Rectangle {
        id: petal
        property real startX
        property real startY
        property real endX
        property real endY
        property color leafColor
        readonly property int lifeMs: 900 + Math.random() * 700
        width: 8 + Math.random() * 8
        height: width * 0.6
        radius: height / 2
        color: leafColor
        x: startX
        y: startY
        rotation: Math.random() * 360

        ParallelAnimation {
          running: true
          NumberAnimation { target: petal; property: "x"; to: petal.endX; duration: petal.lifeMs; easing.type: Easing.OutCubic }
          NumberAnimation { target: petal; property: "y"; to: petal.endY + 90; duration: petal.lifeMs; easing.type: Easing.InOutSine }
          NumberAnimation { target: petal; property: "rotation"; to: petal.rotation + (Math.random() < 0.5 ? -360 : 360); duration: petal.lifeMs }
          NumberAnimation { target: petal; property: "opacity"; from: 1; to: 0; duration: petal.lifeMs; easing.type: Easing.InQuad }
          onFinished: petal.destroy()
        }
      }
    }

    Component {
      id: burstLeaf

      Leaf {
        id: particle
        property real startX
        property real startY
        property real endX
        property real endY
        readonly property int lifeMs: 700 + Math.random() * 600
        leafWidth: 12 + Math.random() * 14
        leafLength: leafWidth * 1.25
        x: startX
        y: startY
        rotation: Math.random() * 360

        ParallelAnimation {
          running: true
          NumberAnimation { target: particle; property: "x"; to: particle.endX; duration: particle.lifeMs; easing.type: Easing.OutCubic }
          NumberAnimation { target: particle; property: "y"; to: particle.endY + 50; duration: particle.lifeMs; easing.type: Easing.OutQuad }
          NumberAnimation { target: particle; property: "rotation"; to: particle.rotation + (Math.random() < 0.5 ? -180 : 180); duration: particle.lifeMs }
          NumberAnimation { target: particle; property: "opacity"; from: 1; to: 0; duration: particle.lifeMs; easing.type: Easing.InQuad }
          onFinished: particle.destroy()
        }
      }
    }
  }
}
