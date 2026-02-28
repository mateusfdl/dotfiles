{ pkgs, zephyr, ... }:
{
  environment.sessionVariables = {
    ZEPHYR_TOOLCHAIN_VARIANT = "zephyr";
    ZEPHYR_SDK_INSTALL_DIR = "${zephyr.sdkFull}/zephyr-sdk";
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
    # ST-Link V2/V3
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3748", MODE="0666", GROUP="plugdev"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="374b", MODE="0666", GROUP="plugdev"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="3752", MODE="0666", GROUP="plugdev"

    # J-Link
    ATTRS{idVendor}=="1366", MODE="0666", GROUP="plugdev"

    # Arduino boards (various vendors)
    ATTRS{idVendor}=="2341", MODE="0666", GROUP="plugdev"
    ATTRS{idVendor}=="2a03", MODE="0666", GROUP="plugdev"
    ATTRS{idVendor}=="1b4f", MODE="0666", GROUP="plugdev"

    # Espressif ESP32 USB-JTAG
    ATTRS{idVendor}=="303a", MODE="0666", GROUP="plugdev"

    # CMSIS-DAP compatible probes
    ATTRS{product}=="*CMSIS-DAP*", MODE="0666", GROUP="plugdev"

    # DFU devices
    ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6015", MODE="0666", GROUP="plugdev"
    ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0666", GROUP="plugdev"

    # nRF52/nRF53 DK boards
    ATTRS{idVendor}=="1915", MODE="0666", GROUP="plugdev"

    # Raspberry Pi Debug Probe
    ATTRS{idVendor}=="2e8a", MODE="0666", GROUP="plugdev"

    # Generic USB-to-serial adapters (CP210x, CH340, FTDI)
    ATTRS{idVendor}=="10c4", MODE="0666", GROUP="dialout"
    ATTRS{idVendor}=="1a86", MODE="0666", GROUP="dialout"
    ATTRS{idVendor}=="0403", MODE="0666", GROUP="dialout"
  '';

  users.users.matheus.extraGroups = [ "dialout" "plugdev" ];
}
