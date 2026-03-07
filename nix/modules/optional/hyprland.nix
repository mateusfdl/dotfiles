{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  security.pam.services.quickshell = { };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QML_IMPORT_PATH = builtins.concatStringsSep ":" [
      "${pkgs.qt6.qt5compat}/lib/qt-6/qml"
      "$HOME/.config/quickshell/plugin/build/qml"
    ];
    XCURSOR_THEME = "macOS";
    XCURSOR_SIZE = "24";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
