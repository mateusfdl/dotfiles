{ pkgs, ... }:
{
  home.packages = with pkgs; [
    luarocks
    luaPackages.luacheck
    stylua
    lua-language-server
  ];
}
