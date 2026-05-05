{ pkgs, ... }:
let
  blender-mcp-src = pkgs.fetchFromGitHub {
    owner = "ahujasid";
    repo = "blender-mcp";
    rev = "7636d13bded82eca58eb93c3f4cd8708dfdfbe8b";
    hash = "sha256-VGilcq/ZuX5ancdUqQpc6z7LGoBpyCMIasaTIzmTbRM=";
  };
  blenderVersion = pkgs.lib.versions.majorMinor pkgs.blender.version;
in
{
  environment.systemPackages = with pkgs; [
    blender
  ];

  systemd.user.tmpfiles.rules = [
    "L+ %h/.config/blender/${blenderVersion}/scripts/addons/blender_mcp.py - - - - ${blender-mcp-src}/addon.py"
  ];
}
