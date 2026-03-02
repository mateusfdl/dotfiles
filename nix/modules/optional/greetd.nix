{ pkgs, ... }:
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # launch hyprland as the greeter compositor.
        # after successful auth, greetd kills nukes it and
        # starts the real user session via uwsm.
        command = "${pkgs.hyprland}/bin/start-hyprland -- -c /home/matheus/.config/hypr/hyprland-greeter.conf";
        user = "matheus";
      };
    };
  };

  # prevents the default greetd tty warning message from cluttering the vt
  # before the graphical greeter starts.
  # not sure if its the best approach tho.
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
}
