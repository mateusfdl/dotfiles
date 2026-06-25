{ ... }:
{
  security.polkit.enable = true;

  services.dbus.enable = true;
  services.earlyoom.enable = true;
  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  zramSwap.enable = true;

  boot.kernel.sysctl."vm.swappiness" = 180;
}
