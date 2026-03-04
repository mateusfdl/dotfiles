#!/bin/bash
# Test the quickshell lock screen

echo "Lock Screen Test Script"
echo "======================"
echo ""
echo "Commands:"
echo "  lock    - Show the lock screen (test mode)"
echo "  unlock  - Hide the lock screen"
echo "  toggle  - Toggle lock screen visibility"
echo ""

case "$1" in
    lock)
        quickshell ipc call lockscreen lock
        echo "Lock screen shown"
        ;;
    unlock)
        # In test mode, you can close it by entering any password
        echo "To unlock in test mode, enter any password in the lock screen"
        ;;
    toggle)
        quickshell ipc call lockscreen toggle
        echo "Lock screen toggled"
        ;;
    *)
        echo "Usage: $0 {lock|unlock|toggle}"
        echo ""
        echo "Note: In test mode (default), any password will work."
        echo "To test with real PAM authentication, edit shell.qml and set testMode: false"
        exit 1
        ;;
esac
