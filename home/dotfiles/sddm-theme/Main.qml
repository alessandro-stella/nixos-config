/**
 * Pixie SDDM
 * A minimal SDDM theme inspired by Pixel UI and Material Design 3.
 * Author: xCaptaiN09
 * GitHub: https://github.com/xCaptaiN09/pixie-sddm
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "components"

Rectangle {
    id: container

    width: 1920
    height: 1080

    color: config.backgroundColor
    focus: !loginState.visible

    property int userIndex: 0
    property int sessionIndex: 0
    property bool isLoggingIn: false

    // ============================================================
    // Dynamic accents
    // ============================================================

    property color accent1: "#FF00FF"
    property color accent2: "#FFFF00"
    property bool accentsLoaded: false

    Loader {
        id: accentsLoader

        source: "file:///var/lib/current-theme/AccentsSDDM.qml"

        onLoaded: {
            if (item) {
                container.accent1 = item.accent1
                container.accent2 = item.accent2
                container.accentsLoaded = true

                console.log(
                    "Pixie SDDM: Accents loaded:",
                    container.accent1,
                    container.accent2
                )
            } else {
                console.log(
                    "Pixie SDDM: AccentsSDDM.qml loaded but item is null"
                )

                container.accent1 = "#E0D0B0"
                container.accent2 = "#E0D0B0"
                container.accentsLoaded = true
            }
        }

        onStatusChanged: {
            if (status === Loader.Error) {
                console.log(
                    "Pixie SDDM: Failed to load /var/lib/current-theme/AccentsSDDM.qml"
                )

                container.accent1 = "#E0D0B0"
                container.accent2 = "#E0D0B0"
                container.accentsLoaded = true
            }
        }
    }

    // ============================================================
    // Startup
    // ============================================================

    Component.onCompleted: {
        if (typeof userModel !== "undefined" &&
            userModel.lastIndex >= 0) {
            userIndex = userModel.lastIndex;
        }

        if (typeof sessionModel !== "undefined" &&
            sessionModel.lastIndex >= 0) {
            sessionIndex = sessionModel.lastIndex;
        }
    }

    // ============================================================
    // Helpers
    // ============================================================

    function cleanName(name) {
        if (!name)
            return "";

        var s = name.toString();

        if (s.endsWith("/"))
            s = s.substring(0, s.length - 1);

        if (s.indexOf("/") !== -1)
            s = s.substring(s.lastIndexOf("/") + 1);

        if (s.indexOf(".desktop") !== -1)
            s = s.substring(0, s.indexOf(".desktop"));

        return s;
    }

    function doLogin() {
        if (!loginState.visible || isLoggingIn)
            return;

        var user = "";

        if (typeof userModel !== "undefined" &&
            userModel.count > 0) {

            var idx = container.userIndex;

            if (idx < 0 || idx >= userModel.count)
                idx = 0;

            var edit = userModel.data(
                userModel.index(idx, 0),
                Qt.EditRole
            );

            var nameRole = userModel.data(
                userModel.index(idx, 0),
                Qt.UserRole + 1
            );

            var display = userModel.data(
                userModel.index(idx, 0),
                Qt.DisplayRole
            );

            user = edit
                ? edit.toString()
                : (nameRole
                    ? nameRole.toString()
                    : (display
                        ? display.toString()
                        : ""));
        }

        if (!user || user === "" || user === "User")
            user = sddm.lastUser;

        if (!user &&
            typeof userModel !== "undefined" &&
            userModel.count > 0) {

            var firstEdit = userModel.data(
                userModel.index(0, 0),
                Qt.EditRole
            );

            user = firstEdit
                ? firstEdit.toString()
                : "";
        }

        if (!user)
            return;

        container.isLoggingIn = true;

        var pass = passwordField.text;
        var sess = container.sessionIndex;

        if (typeof sessionModel !== "undefined") {
            if (sess < 0 || sess >= sessionModel.count)
                sess = 0;
        } else {
            sess = 0;
        }

        console.log(
            "Pixie SDDM: Attempting login for user [" +
            user +
            "] session index [" +
            sess +
            "]"
        );

        sddm.login(
            user.trim(),
            pass,
            sess
        );

        loginTimeout.start();
    }

    // ============================================================
    // Login timeout
    // ============================================================

    Timer {
        id: loginTimeout

        interval: 5000

        onTriggered: {
            container.isLoggingIn = false;
        }
    }

    // ============================================================
    // SDDM login signals
    // ============================================================

    Connections {
        target: sddm

        function onLoginFailed() {
            container.isLoggingIn = false;
            loginTimeout.stop();

            loginState.isError = true;

            shakeAnimation.start();

            passwordField.text = "";
            passwordField.forceActiveFocus();
        }

        function onLoginSucceeded() {
            loginTimeout.stop();
        }
    }

    // ============================================================
    // Fonts
    // ============================================================

    FontLoader {
        id: fontRegular
        source: "assets/fonts/FlexRounded-R.ttf"
    }

    FontLoader {
        id: fontMedium
        source: "assets/fonts/FlexRounded-M.ttf"
    }

    FontLoader {
        id: fontBold
        source: "assets/fonts/FlexRounded-B.ttf"
    }

    // ============================================================
    // Background
    // ============================================================

    Image {
        id: backgroundImage

        source: config.background

        anchors.fill: parent

        fillMode: Image.PreserveAspectCrop
    }

    MultiEffect {
        id: backgroundBlur

        anchors.fill: parent

        source: backgroundImage

        blurEnabled: true

        blur: loginState.visible ? 1.0 : 0.0

        opacity: loginState.visible ? 1.0 : 0.0

        autoPaddingEnabled: false

        Behavior on opacity {
            NumberAnimation {
                duration: 400
                easing.type: Easing.InOutQuad
            }
        }

        Behavior on blur {
            NumberAnimation {
                duration: 400
                easing.type: Easing.InOutQuad
            }
        }
    }

    Rectangle {
        anchors.fill: parent

        color: "black"

        opacity: loginState.visible ? 0.6 : 0.4

        Behavior on opacity {
            NumberAnimation {
                duration: 400
            }
        }
    }

    // ============================================================
    // Power bar
    // ============================================================

    PowerBar {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 30
            rightMargin: 40
        }

        textColor: container.accent1

        z: 100

        opacity: container.accentsLoaded ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
    }

    // ============================================================
    // Keyboard shortcuts
    // ============================================================

    Shortcut {
        sequence: "Escape"

        enabled: loginState.visible

        onActivated: {
            loginState.visible = false;
            loginState.isError = false;
            passwordField.text = "";
            container.focus = true;
        }
    }

    Shortcut {
        sequences: ["Return", "Enter"]

        enabled: loginState.visible

        onActivated: container.doLogin()
    }

    // ============================================================
    // Date
    // ============================================================

    Text {
        id: dateText

        text: Qt.formatDateTime(
            new Date(),
            "dddd, MMMM d"
        )

        color: container.accent1

        font.pixelSize: 22
        font.family: config.fontFamily

        anchors {
            top: parent.top
            left: parent.left
            topMargin: 50
            leftMargin: 60
        }

        opacity: container.accentsLoaded ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
    }

    // ============================================================
    // Lock screen
    // ============================================================

    Item {
        id: lockState

        anchors.fill: parent

        visible: !loginState.visible

        opacity: visible ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 400
            }
        }

        Clock {
            id: mainClock

            anchors.centerIn: parent

            backgroundSource: config.background

            baseAccent: container.accent1

            fontFamily: config.fontFamily

            opacity: container.accentsLoaded ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }
        }

        Text {
            text: "Press any key to unlock"

            color: container.accent2

            font.pixelSize: 16

            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 100
            }

            opacity: container.accentsLoaded ? 0.5 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }
        }

        MouseArea {
            anchors.fill: parent

            onClicked: {
                loginState.visible = true;
                passwordField.forceActiveFocus();
            }
        }
    }

    // ============================================================
    // Login state
    // ============================================================

    Item {
        id: loginState

        anchors.fill: parent

        visible: false

        opacity: visible ? 1 : 0

        z: 10

        Behavior on opacity {
            NumberAnimation {
                duration: 400
            }
        }

        onVisibleChanged: {
            if (visible)
                passwordField.forceActiveFocus();
        }

        property bool isError: false

        // ========================================================
        // Login card shake
        // ========================================================

        SequentialAnimation {
            id: shakeAnimation

            loops: 2

            PropertyAnimation {
                target: loginCard
                property: "x"
                from: (container.width - loginCard.width) / 2
                to: (container.width - loginCard.width) / 2 - 10
                duration: 50
                easing.type: Easing.InOutQuad
            }

            PropertyAnimation {
                target: loginCard
                property: "x"
                from: (container.width - loginCard.width) / 2 - 10
                to: (container.width - loginCard.width) / 2 + 10
                duration: 50
                easing.type: Easing.InOutQuad
            }

            PropertyAnimation {
                target: loginCard
                property: "x"
                from: (container.width - loginCard.width) / 2 + 10
                to: (container.width - loginCard.width) / 2
                duration: 50
                easing.type: Easing.InOutQuad
            }

            onStopped: {
                isError = false;
            }
        }

        // ========================================================
        // Login card
        // ========================================================

        Rectangle {
            id: loginCard

            width: 380
            height: 480

            x: (parent.width - width) / 2
            y: (parent.height - height) / 2

            color: loginState.isError
                ? "#442222"
                : "#1A1C18"

            opacity: 0.7

            radius: 32

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }

            ColumnLayout {
                anchors.fill: parent

                anchors.margins: 40

                spacing: 15

                // =================================================
                // Avatar
                // =================================================

                Item {
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 120
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        id: avatarFallback

                        anchors.fill: parent

                        color: "#2D2F27"

                        radius: width / 2

                        visible: avatar.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent

                            text: {
                                var n = "";

                                if (typeof userModel !== "undefined" &&
                                    userModel.count > 0) {

                                    var d = userModel.data(
                                        userModel.index(
                                            container.userIndex,
                                            0
                                        ),
                                        Qt.DisplayRole
                                    );

                                    var nr = userModel.data(
                                        userModel.index(
                                            container.userIndex,
                                            0
                                        ),
                                        Qt.UserRole + 1
                                    );

                                    n = d
                                        ? d.toString()
                                        : (nr
                                            ? nr.toString()
                                            : "U");
                                } else {
                                    n = sddm.lastUser
                                        ? sddm.lastUser
                                        : "U";
                                }

                                return n.charAt(0).toUpperCase();
                            }

                            color: container.accent1

                            font.pixelSize: 48
                            font.family: fontBold.name
                            font.weight: Font.Bold
                        }
                    }

                    Canvas {
                        id: avatarCanvas

                        anchors.fill: parent

                        visible: avatar.status === Image.Ready

                        onPaint: {
                            var ctx = getContext("2d");

                            ctx.reset();

                            ctx.beginPath();

                            ctx.arc(
                                width / 2,
                                height / 2,
                                width / 2,
                                0,
                                2 * Math.PI
                            );

                            ctx.closePath();
                            ctx.clip();

                            ctx.drawImage(
                                avatar,
                                0,
                                0,
                                width,
                                height
                            );
                        }

                        Timer {
                            id: repaintTimer

                            interval: 500

                            onTriggered: {
                                avatarCanvas.requestPaint();
                            }
                        }

                        Image {
                            id: avatar

                            anchors.fill: parent

                            fillMode: Image.PreserveAspectCrop

                            smooth: true

                            visible: false

                            Component.onCompleted: {
                                var s = Qt.resolvedUrl(
                                    "assets/avatar.jpg"
                                );

                                if (typeof userModel !== "undefined" &&
                                    userModel.count > 0) {

                                    var icon = userModel.data(
                                        userModel.index(
                                            container.userIndex,
                                            0
                                        ),
                                        Qt.UserRole + 3
                                    );

                                    if (icon &&
                                        icon.toString().match(
                                            /\.(jpg|jpeg|png|bmp|webp|svg)$/i
                                        )) {
                                        s = icon.toString();
                                    }
                                }

                                source = s;
                            }

                            onStatusChanged: {
                                if (status === Image.Ready)
                                    repaintTimer.start();
                            }
                        }
                    }
                }

                // =================================================
                // Username
                // =================================================

                Item {
                    Layout.alignment: Qt.AlignHCenter

                    Layout.preferredWidth:
                        userNameLabel.width + 40

                    Layout.preferredHeight:
                        userNameLabel.height + 20

                    Layout.topMargin: 10

                    Rectangle {
                        anchors.fill: parent

                        color: "white"

                        opacity:
                            userClickArea.pressed ? 0.2 : 0

                        radius: 12

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 100
                            }
                        }
                    }

                    Text {
                        id: userNameLabel

                        anchors.centerIn: parent

                        text: {
                            if (typeof userModel !== "undefined" &&
                                userModel.count > 0) {

                                var modelIdx =
                                    userModel.index(
                                        container.userIndex,
                                        0
                                    );

                                var display =
                                    userModel.data(
                                        modelIdx,
                                        Qt.DisplayRole
                                    );

                                var edit =
                                    userModel.data(
                                        modelIdx,
                                        Qt.EditRole
                                    );

                                var nr =
                                    userModel.data(
                                        modelIdx,
                                        Qt.UserRole + 1
                                    );

                                var realName =
                                    userModel.data(
                                        modelIdx,
                                        Qt.UserRole + 2
                                    );

                                var rawName =
                                    edit
                                        ? edit.toString()
                                        : (nr
                                            ? nr.toString()
                                            : (display
                                                ? display.toString()
                                                : (realName
                                                    ? realName.toString()
                                                    : "User")));

                                return rawName +
                                    (userModel.count > 1
                                        ? " ▾"
                                        : "");
                            }

                            return sddm.lastUser
                                ? sddm.lastUser.name
                                : "User";
                        }

                        color: "white"

                        font.pixelSize: 24
                        font.weight: Font.Bold
                        font.family: config.fontFamily
                    }

                    MouseArea {
                        id: userClickArea

                        anchors.fill: parent

                        onClicked: userPopup.open()
                    }

                    scale: userClickArea.pressed ? 0.95 : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                        }
                    }
                }

                // =================================================
                // Session selector
                // =================================================

                Rectangle {
                    id: sessionPill

                    Layout.alignment: Qt.AlignHCenter

                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 36

                    color:
                        (sessionClickArea.pressed ||
                         sessionPopup.opened)
                        ? "#3D3F37"
                        : "#2D2F27"

                    radius: 18

                    border.width: 1

                    border.color:
                        (sessionClickArea.pressed ||
                         sessionPopup.opened)
                        ? container.accent1
                        : "#3D3F37"

                    scale:
                        sessionClickArea.pressed
                        ? 0.95
                        : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 100
                        }
                    }

                    RowLayout {
                        anchors.centerIn: parent

                        spacing: 8

                        Text {
                            text: "󰟀"

                            color: container.accent1

                            font.pixelSize: 16
                        }

                        Text {
                            text: {
                                if (typeof sessionModel !== "undefined" &&
                                    sessionModel.count > 0) {

                                    var idx =
                                        container.sessionIndex;

                                    var modelIdx =
                                        sessionModel.index(
                                            idx,
                                            0
                                        );

                                    var n =
                                        sessionModel.data(
                                            modelIdx,
                                            Qt.UserRole + 4
                                        );

                                    var f =
                                        sessionModel.data(
                                            modelIdx,
                                            Qt.UserRole + 2
                                        );

                                    var d =
                                        sessionModel.data(
                                            modelIdx,
                                            Qt.DisplayRole
                                        );

                                    var finalName =
                                        n
                                            ? n.toString()
                                            : (f
                                                ? f.toString()
                                                : (d
                                                    ? d.toString()
                                                    : "Session " +
                                                      (idx + 1)));

                                    return cleanName(
                                        finalName
                                    ) +
                                    (sessionModel.count > 1
                                        ? " ▾"
                                        : "");
                                }

                                return "Hyprland";
                            }

                            color: "white"

                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: sessionClickArea

                        anchors.fill: parent

                        onClicked: sessionPopup.open()
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                // =================================================
                // Password
                // =================================================

                TextField {
                    id: passwordField

                    echoMode: TextInput.Password

                    Layout.fillWidth: true

                    horizontalAlignment:
                        Text.AlignHCenter

                    font.pixelSize: 18

                    color: "white"

                    focus: loginState.visible

                    enabled: !container.isLoggingIn

                    background: Rectangle {
                        color: "#2D2F27"

                        radius: 16

                        border.width:
                            parent.activeFocus ? 2 : 0

                        border.color: container.accent1

                        opacity:
                            parent.enabled ? 1.0 : 0.5
                    }

                    Text {
                        text: "Enter Password"

                        color: "gray"

                        font.pixelSize: 16

                        visible: !parent.text

                        anchors.centerIn: parent

                        opacity: 0.5
                    }

                    onAccepted: container.doLogin()
                }

                // =================================================
                // Num Lock
                // =================================================

                Text {
                    id: numLockIndicator

                    text: "Num Lock is on"

                    color: container.accent2

                    font.pixelSize: 14
                    font.family: config.fontFamily
                    font.weight: Font.Medium

                    Layout.alignment: Qt.AlignHCenter

                    visible: {
                        if (typeof keyboard !== "undefined" &&
                            typeof keyboard.numLock !== "undefined") {
                            return keyboard.numLock;
                        }

                        return false;
                    }

                    opacity: visible ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                // =================================================
                // Login button
                // =================================================

                RoundButton {
                    id: loginButton

                    Layout.alignment: Qt.AlignHCenter

                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64

                    focusPolicy: Qt.NoFocus

                    enabled: !container.isLoggingIn

                    contentItem: Text {
                        text:
                            container.isLoggingIn
                            ? "⋯"
                            : "→"

                        color: "white"

                        font.pixelSize: 32

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter
                    }

                    background: Rectangle {
                        color:
                            container.isLoggingIn
                            ? "#3D3F37"
                            : (
                                loginButton.pressed
                                ? Qt.darker(
                                    container.accent1,
                                    1.1
                                )
                                : container.accent1
                            )

                        radius: 32

                        opacity:
                            container.isLoggingIn
                            ? 0.5
                            : 1.0
                    }

                    onClicked: {
                        container.doLogin();
                    }
                }
            }
        }
    }

    // ============================================================
    // Unlock with keyboard
    // ============================================================

    Keys.onPressed: function(event) {
        if (!loginState.visible) {
            loginState.visible = true;
            passwordField.forceActiveFocus();
            event.accepted = true;
        }
    }

    // ============================================================
    // User popup
    // ============================================================

    Popup {
        id: userPopup

        width: 260

        height:
            (typeof userModel !== "undefined")
            ? Math.min(
                300,
                userModel.count * 50 + 20
            )
            : 100

        x: (parent.width - width) / 2

        y: (parent.height - height) / 2 - 50

        modal: true

        focus: true

        closePolicy:
            Popup.CloseOnEscape |
            Popup.CloseOnPressOutside

        onOpened: userList.forceActiveFocus()

        background: Rectangle {
            color: "#1A1C18"

            radius: 24

            opacity: 0.95

            border.color: container.accent2

            border.width: 1
        }

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 200
            }
        }

        ListView {
            id: userList

            anchors.fill: parent

            anchors.margins: 10

            model:
                (typeof userModel !== "undefined")
                ? userModel
                : null

            spacing: 5

            clip: true

            focus: true

            currentIndex: container.userIndex

            highlightFollowsCurrentItem: true

            delegate: ItemDelegate {
                width: parent.width

                height: 40

                property bool isCurrent:
                    index === userList.currentIndex

                background: Rectangle {
                    color:
                        isCurrent
                        ? "#3D3F37"
                        : (
                            hovered
                            ? "#2D2F27"
                            : "transparent"
                        )

                    radius: 12

                    Rectangle {
                        anchors.left: parent.left

                        anchors.verticalCenter:
                            parent.verticalCenter

                        anchors.leftMargin: 8

                        width: 4

                        height:
                            isCurrent ? 16 : 0

                        color: container.accent1

                        radius: 2

                        Behavior on height {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }
                }

                contentItem: RowLayout {
                    anchors.fill: parent

                    spacing: 0

                    Item {
                        Layout.preferredWidth: 20
                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28

                        Layout.alignment:
                            Qt.AlignVCenter

                        color:
                            isCurrent
                            ? container.accent1
                            : "#3D3F37"

                        radius: 14

                        Text {
                            anchors.centerIn: parent

                            text: {
                                var mIdx =
                                    userModel.index(
                                        index,
                                        0
                                    );

                                var d =
                                    userModel.data(
                                        mIdx,
                                        Qt.DisplayRole
                                    );

                                var n_r =
                                    userModel.data(
                                        mIdx,
                                        Qt.UserRole + 1
                                    );

                                var finalVal =
                                    d
                                        ? d.toString()
                                        : (
                                            n_r
                                            ? n_r.toString()
                                            : "U"
                                        );

                                return finalVal
                                    .charAt(0)
                                    .toUpperCase();
                            }

                            color:
                                isCurrent
                                ? "#1A1C18"
                                : "white"

                            font.pixelSize: 12
                            font.family: fontBold.name
                            font.weight: Font.Bold
                        }
                    }

                    Item {
                        Layout.preferredWidth: 12
                    }

                    Text {
                        Layout.fillWidth: true

                        text: {
                            var mIdx =
                                userModel.index(
                                    index,
                                    0
                                );

                            var d =
                                userModel.data(
                                    mIdx,
                                    Qt.DisplayRole
                                );

                            var n_r =
                                userModel.data(
                                    mIdx,
                                    Qt.UserRole + 1
                                );

                            var r =
                                userModel.data(
                                    mIdx,
                                    Qt.UserRole + 2
                                );

                            var e =
                                userModel.data(
                                    mIdx,
                                    Qt.EditRole
                                );

                            return cleanName(
                                d
                                    ? d
                                    : (
                                        r
                                        ? r
                                        : (
                                            n_r
                                            ? n_r
                                            : e
                                        )
                                    )
                            );
                        }

                        color:
                            isCurrent
                            ? "white"
                            : (
                                hovered
                                ? "#DDDDDD"
                                : "#AAAAAA"
                            )

                        font.pixelSize: 15

                        font.family:
                            config.fontFamily

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter

                        rightPadding: 60

                        elide:
                            Text.ElideRight
                    }
                }

                onClicked: {
                    container.userIndex = index;
                    userPopup.close();
                }
            }

            Keys.onDownPressed:
                incrementCurrentIndex()

            Keys.onUpPressed:
                decrementCurrentIndex()

            Keys.onReturnPressed: {
                container.userIndex = currentIndex;
                userPopup.close();
            }

            Keys.onEnterPressed: {
                container.userIndex = currentIndex;
                userPopup.close();
            }
        }
    }

    // ============================================================
    // Session popup
    // ============================================================

    Popup {
        id: sessionPopup

        width: 260

        height:
            (typeof sessionModel !== "undefined")
            ? Math.min(
                250,
                sessionModel.count * 50 + 20
            )
            : 100

        x: (parent.width - width) / 2

        y: (parent.height - height) / 2 + 80

        modal: true

        focus: true

        closePolicy:
            Popup.CloseOnEscape |
            Popup.CloseOnPressOutside

        onOpened: sessionList.forceActiveFocus()

        background: Rectangle {
            color: "#1A1C18"

            radius: 24

            opacity: 0.95

            border.color: container.accent2

            border.width: 1
        }

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 200
            }
        }

        ListView {
            id: sessionList

            anchors.fill: parent

            anchors.margins: 10

            model:
                (typeof sessionModel !== "undefined")
                ? sessionModel
                : null

            spacing: 5

            clip: true

            focus: true

            currentIndex: container.sessionIndex

            highlightFollowsCurrentItem: true

            delegate: ItemDelegate {
                width: parent.width

                height: 40

                property bool isCurrent:
                    index === sessionList.currentIndex

                background: Rectangle {
                    color:
                        isCurrent
                        ? "#3D3F37"
                        : (
                            hovered
                            ? "#2D2F27"
                            : "transparent"
                        )

                    radius: 12

                    Rectangle {
                        anchors.left: parent.left

                        anchors.verticalCenter:
                            parent.verticalCenter

                        anchors.leftMargin: 8

                        width: 4

                        height:
                            isCurrent ? 16 : 0

                        color: container.accent1

                        radius: 2

                        Behavior on height {
                            NumberAnimation {
                                duration: 150
                            }
                        }
                    }
                }

                contentItem: RowLayout {
                    anchors.fill: parent

                    spacing: 0

                    Item {
                        Layout.preferredWidth: 20
                    }

                    Text {
                        Layout.preferredWidth: 40

                        text: "󰟀"

                        color:
                            isCurrent
                            ? container.accent1
                            : "gray"

                        font.pixelSize: 16

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter
                    }

                    Text {
                        Layout.fillWidth: true

                        text: {
                            var n_val =
                                sessionModel.data(
                                    sessionModel.index(
                                        index,
                                        0
                                    ),
                                    Qt.UserRole + 4
                                );

                            var f_val =
                                sessionModel.data(
                                    sessionModel.index(
                                        index,
                                        0
                                    ),
                                    Qt.UserRole + 2
                                );

                            return cleanName(
                                n_val
                                    ? n_val
                                    : f_val
                            );
                        }

                        color:
                            isCurrent
                            ? "white"
                            : "#AAAAAA"

                        font.pixelSize: 14

                        font.family:
                            config.fontFamily

                        horizontalAlignment:
                            Text.AlignHCenter

                        verticalAlignment:
                            Text.AlignVCenter

                        rightPadding: 60

                        elide:
                            Text.ElideRight
                    }
                }

                onClicked: {
                    container.sessionIndex = index;
                    sessionPopup.close();
                }
            }

            Keys.onDownPressed:
                incrementCurrentIndex()

            Keys.onUpPressed:
                decrementCurrentIndex()

            Keys.onReturnPressed: {
                container.sessionIndex = currentIndex;
                sessionPopup.close();
            }

            Keys.onEnterPressed: {
                container.sessionIndex = currentIndex;
                sessionPopup.close();
            }
        }
    }
}
