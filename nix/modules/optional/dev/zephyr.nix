{ pkgs, zephyr, ... }:
{
  environment.sessionVariables = {
    ZEPHYR_TOOLCHAIN_VARIANT = "zephyr";
    ZEPHYR_SDK_INSTALL_DIR = "${zephyr.sdkFull}";
  };

  environment.systemPackages = with pkgs; [
    zephyr.sdkFull
    zephyr.hosttools-nix

    zephyr.pythonEnv

    cmake
    ninja
    gnumake
    gperf

    dtc

    zephyr.openocd-zephyr
    gdb
    stlink
    dfu-util

    picocom
    minicom

    ccache
    doxygen
    wget
    xz
    file
  ];

  services.udev.extraRules = ''
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", MODE="0666", GROUP="plugdev"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374b", MODE="0666", GROUP="plugdev"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3752", MODE="0666", GROUP="plugdev"

    ATTRS{idVendor}=="1366", MODE="0666", GROUP="plugdev"

    ATTRS{idVendor}=="2341", MODE="0666", GROUP="plugdev"
    ATTRS{idVendor}=="2a03", MODE="0666", GROUP="plugdev"
    ATTRS{idVendor}=="1b4f", MODE="0666", GROUP="plugdev"

    ATTRS{idVendor}=="303a", MODE="0666", GROUP="plugdev"

    ATTRS{product}=="*CMSIS-DAP*", MODE="0666", GROUP="plugdev"

    ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6015", MODE="0666", GROUP="plugdev"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0666", GROUP="plugdev"

    ATTRS{idVendor}=="1915", MODE="0666", GROUP="plugdev"

    SUBSYSTEM=="tty", ATTRS{idVendor}=="2fe3", MODE="0666", GROUP="plugdev"

    SUBSYSTEM=="tty", ATTRS{idVendor}=="2886", MODE="0666", GROUP="plugdev"

    ATTRS{idVendor}=="2e8a", MODE="0666", GROUP="plugdev"

    ATTRS{idVendor}=="10c4", MODE="0666", GROUP="dialout"
    ATTRS{idVendor}=="1a86", MODE="0666", GROUP="dialout"
    ATTRS{idVendor}=="0403", MODE="0666", GROUP="dialout"
  '';

  users.groups.plugdev = {};
  users.users.matheus.extraGroups = [ "dialout" "plugdev" ];
}
