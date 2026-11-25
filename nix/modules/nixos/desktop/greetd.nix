{
  config,
  pkgs,
  username,
  ...
}:
let
  greeterUser = config.users.users.${username};
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.hyprland}/bin/start-hyprland -- -c ${greeterUser.home}/.config/hypr/hyprland-greeter.lua";
        user = greeterUser.name;
      };
    };
  };

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
