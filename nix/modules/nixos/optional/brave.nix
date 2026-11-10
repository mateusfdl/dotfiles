{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      brave = prev.brave.overrideAttrs (old: {
        preFixup = (old.preFixup or "") + ''
          gappsWrapperArgs+=(
            --add-flags ${prev.lib.escapeShellArg "--enable-features=AcceleratedVideoDecodeLinuxGL,VaapiOnNvidiaGPUs,WaylandWindowDecorations"}
          )
        '';
      });
    })
  ];

  environment.systemPackages = [ pkgs.brave ];

  environment.etc."brave/policies/managed/performance.json".text = builtins.toJSON {
    BraveRewardsDisabled = true;
    BraveWalletDisabled = true;
    BraveVPNDisabled = true;
    BraveAIChatEnabled = false;
    BraveNewsDisabled = true;
    TorDisabled = true;
    BackgroundModeEnabled = false;
    MemorySaverModeEnabled = true;
    MemorySaverModeSavings = 1;
  };
}
