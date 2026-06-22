{ pkgs, inputs, system, ... }:
let
  claude-desktop-pkg = inputs.claude-desktop.packages.${system}.claude-desktop;
  taskwarriorAsTaskw = pkgs.writeShellScriptBin "taskw" ''
    exec ${pkgs.taskwarrior3}/bin/task rc:/home/matheus/Documents/personal-org-mode/Personal/Journal/todos/taskrc "$@"
  '';
in
{
  environment.systemPackages = with pkgs; [
    apple-cursor
    brightnessctl
    bubblewrap
    cliphist
    ffmpeg
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
    qt6.qt5compat
    qt6.qtdeclarative
    qt6.qttools
    qt6.qtwayland
    quickshell
    slurp
    awww
    taskwarriorAsTaskw
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
    morgen
    obsidian
    spotify
  ];
}
