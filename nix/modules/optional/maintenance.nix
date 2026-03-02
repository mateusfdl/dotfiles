{ ... }:
{
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "04:00";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  services.fstrim.enable = true;

  zramSwap.enable = true;

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
}
