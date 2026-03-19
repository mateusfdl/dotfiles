pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
    id: root

    // Current password text
    property string currentText: ""

    // State flags
    property bool unlockInProgress: false
    property bool unlockSucceeded: false
    property bool showFailure: false

    // Signals
    signal unlocked
    signal failed

    // Try to authenticate with the entered password
    function tryUnlock() {
        if (currentText.length === 0)
            return;
        if (unlockInProgress)
            return;
        if (unlockSucceeded)
            return;

        unlockInProgress = true;
        showFailure = false;

        pamContext.start();
    }

    // Clear password and reset state
    function clearPassword() {
        currentText = "";
        showFailure = false;
        unlockSucceeded = false;
        unlockInProgress = false;
    }

    PamContext {
        id: pamContext

        configDirectory: "file:///etc/pam.d"
        config: "quickshell"

        onPamMessage: (message, isError) => {
            // PAM is asking for the password
            if (!isError) {
                pamContext.respond(root.currentText);
            }
        }

        onCompleted: success => {
            // Note: success parameter is inverted in PamContext (false = success)
            if (!success) {
                root.unlockSucceeded = true;
                root.unlockInProgress = false;
                root.unlocked();
            } else {
                root.unlockInProgress = false;
                root.showFailure = true;
                root.currentText = "";
                root.failed();
            }
        }
    }
}
