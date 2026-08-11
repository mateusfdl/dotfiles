{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.brave.overrideAttrs (old: {
      preFixup = (old.preFixup or "") + ''
        gappsWrapperArgs+=(
          --add-flags ${
            pkgs.lib.escapeShellArg "--enable-features=AcceleratedVideoDecodeLinuxGL,VaapiOnNvidiaGPUs,WaylandWindowDecorations"
          }
        )
      '';
    }))
  ];

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
