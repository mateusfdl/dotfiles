{ ... }:
{
  system.autoUpgrade = {
    enable = true;
    flake = "github:mateusfdl/dotfiles?dir=nix#server";
    allowReboot = true;
    rebootWindow = { lower = "04:00"; upper = "05:00"; };
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
