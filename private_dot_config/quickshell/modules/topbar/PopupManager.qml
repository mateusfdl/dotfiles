import "." as Topbar
import QtQuick
pragma Singleton

QtObject {
    id: popupManager

    property var activeSysTrayMenu: null

    // Function to close all popups except the specified one
    function closeAllExcept(exceptPopup) {
        if (exceptPopup !== "volume") {
            Topbar.VolumePopup.hidePopup();
        }
        if (exceptPopup !== "pomodoro") {
            Topbar.PomodoroPopup.hidePopup();
        }
        if (exceptPopup !== "controlcenter") {
            Topbar.ControlCenterPopup.hidePopup();
        }
        if (exceptPopup !== "systray") {
            closeSysTrayMenu();
        }
    }

    // Function to close systray menu
    function closeSysTrayMenu() {
        if (activeSysTrayMenu) {
            activeSysTrayMenu.close();
            activeSysTrayMenu = null;
        }
    }

    // Function to show a specific popup
    function showPopup(popupName, x, y) {
        closeAllExcept(popupName);

        if (popupName === "volume") {
            Topbar.VolumePopup.showPopup(x, y);
        } else if (popupName === "pomodoro") {
            Topbar.PomodoroPopup.showPopup(x, y);
        } else if (popupName === "controlcenter") {
            Topbar.ControlCenterPopup.showPopup(x, y);
        }
    }
}
