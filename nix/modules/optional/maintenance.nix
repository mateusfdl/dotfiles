{ ... }:
{
  # automatic NixOS upgrades with reboot at 4am
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "04:00";
  };

  # garbage collection: weekly, keep 14 days
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # SSD health
  services.fstrim.enable = true;

  # compressed in-memory swap
  zramSwap.enable = true;

  # disable all sleep targets (always-on server)
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
}
