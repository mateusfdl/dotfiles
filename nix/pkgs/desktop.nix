{ pkgs, inputs, system, ... }:
let
  claude-desktop-pkg = inputs.claude-desktop.packages.${system}.claude-desktop;
  hunk-pkg = inputs.hunk.packages.${system}.default;
  taskwarriorAsTaskw = pkgs.writeShellScriptBin "taskw" ''
    exec ${pkgs.taskwarrior3}/bin/task "$@"
  '';
in
{
  environment.systemPackages = with pkgs; [
    apple-cursor
    brave
    brightnessctl
    bubblewrap
    cliphist
    ffmpeg
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
    mpv
    networkmanagerapplet
    nwg-displays
    papirus-icon-theme
    pavucontrol
    python3
    qt6.qt5compat
    qt6.qtdeclarative
    qt6.qttools
    qt6.qtwayland
    quickshell
    slurp
    awww
    taskwarriorAsTaskw
    tmux
    tree-sitter
    unzip
    vim
    wget
    wf-recorder
    wl-clipboard
    wireguard-tools
  ];

  users.users.matheus.packages = with pkgs; [
    claude-desktop-pkg
    discord
    gh
    hunk-pkg
    morgen
    obsidian
    spotify
  ];
}
