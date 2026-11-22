{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  security.pam.services.quickshell = { };

  environment.systemPackages = with pkgs; [
    apple-cursor
    awww
    brightnessctl
    cliphist
    grim
    hyprcursor
    hypridle
    hyprlandPlugins.hyprbars
    hyprwayland-scanner
    hyprwire
    kdePackages.qt6ct
    libsForQt5.qt5ct
    networkmanagerapplet
    nwg-displays
    papirus-icon-theme
    pavucontrol
    qt6.qt5compat
    qt6.qtdeclarative
    qt6.qttools
    qt6.qtwayland
    quickshell
    slurp
    wf-recorder
    wl-clipboard
  ];

  environment.sessionVariables = {
    CLUTTER_BACKEND = "wayland";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    SDL_VIDEODRIVER = "wayland";
    QML_IMPORT_PATH = builtins.concatStringsSep ":" [
      "${pkgs.qt6.qt5compat}/lib/qt-6/qml"
      "$HOME/.config/quickshell/plugin/build/qml"
    ];
    XCURSOR_THEME = "macOS";
    XCURSOR_SIZE = "24";
  };
}
