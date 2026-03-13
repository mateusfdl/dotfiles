{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    apple-cursor
    brave
    brightnessctl
    cliphist
    git
    glib
    gnupg
    grim
    hyprcursor
    hypridle
    hyprwayland-scanner
    hyprwire
    kdePackages.qt6ct
    kitty
    libsForQt5.qt5ct
    nautilus
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
    swww
    tmux
    tree-sitter
    unzip
    vim
    wget
    wl-clipboard
    wireguard-tools
  ];

  users.users.matheus.packages = with pkgs; [
    discord
    gh
    obsidian
    spotify
  ];
}
