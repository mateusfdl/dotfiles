{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.brave ];

  nixpkgs.overlays = [
    (_: prev: {
      brave = prev.brave.override {
        commandLineArgs = builtins.concatStringsSep " " [
          "--ignore-gpu-blocklist"
          "--enable-gpu-rasterization"
          "--enable-zero-copy"
          "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder"
        ];
      };
    })
  ];

  environment.etc."brave/policies/managed/performance.json".text = builtins.toJSON {
    BraveRewardsDisabled = true;
    BraveWalletDisabled = true;
    BraveVPNDisabled = true;
    BraveAIChatEnabled = false;
    BraveNewsDisabled = true;
    TorDisabled = true;
    BackgroundModeEnabled = false;
  };
}
