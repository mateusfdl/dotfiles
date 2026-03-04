pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Greetd

Scope {
    id: root

    // User credentials
    property string username: Quickshell.env("USER") || "user"
    property string currentText: ""

    // Session command to launch after successful auth
    property list<string> sessionCommand: ["uwsm", "start", "hyprland-uwsm.desktop"]

    // State flags
    property bool loginInProgress: false
    property bool loginSucceeded: false
    property bool showFailure: false
    property string errorMessage: ""
    property bool greetdAvailable: Greetd.available

    // Signals
    signal authenticated()  // Auth succeeded, UI should show loading screen
    signal failed()

    // Timer for simulating auth delay in demo mode
    Timer {
        id: demoAuthTimer
        interval: 800
        repeat: false
        onTriggered: {
            root.loginSucceeded = true;
            root.loginInProgress = false;
            root.authenticated();
        }
    }

    // Start the login flow: create a greetd session for the user
    function tryLogin() {
        if (currentText.length === 0) return;
        if (loginInProgress) return;
        if (loginSucceeded) return;

        loginInProgress = true;
        showFailure = false;
        errorMessage = "";

        if (!greetdAvailable) {
            // Demo mode: simulate auth after a short delay
            demoAuthTimer.start();
            return;
        }

        Greetd.createSession(username);
    }

    // Called by the UI to start the user session.
    // The loading screen stays visible until greetd kills this compositor.
    function launchSession() {
        if (!greetdAvailable) {
            // Demo mode: just log, don't call greetd
            console.log("[demo] Session would launch now:", root.sessionCommand);
            return;
        }
        Greetd.launch(root.sessionCommand);
    }

    // Clear password and reset state
    function clearPassword() {
        currentText = "";
        showFailure = false;
        errorMessage = "";
        loginInProgress = false;
    }

    // Cancel any active session and reset
    function resetSession() {
        if (Greetd.state === GreetdState.Authenticating || Greetd.state === GreetdState.ReadyToLaunch) {
            Greetd.cancelSession();
        }
        clearPassword();
        loginSucceeded = false;
    }

    // ===== Greetd signal handlers =====
    Connections {
        target: Greetd

        // greetd is asking for authentication (typically the password)
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (error) {
                // Recoverable error from greetd (e.g. fingerprint scanner issue)
                root.errorMessage = message;
                return;
            }

            if (responseRequired) {
                // greetd wants the password - send it
                Greetd.respond(root.currentText);
            }
            // If no response required, it's just an informational message
        }

        // Authentication succeeded - session is ready to launch
        function onReadyToLaunch() {
            root.loginSucceeded = true;
            root.loginInProgress = false;

            root.authenticated();
        }

        // Authentication failed (bad password, timeout, etc.)
        function onAuthFailure(message) {
            root.loginInProgress = false;
            root.loginSucceeded = false;
            root.showFailure = true;
            root.errorMessage = message || "Authentication failed";
            root.currentText = "";
            root.failed();
        }

        // greetd encountered a protocol-level error
        function onError(error) {
            root.loginInProgress = false;
            root.showFailure = true;
            root.errorMessage = error || "An error occurred";
        }
    }
}
