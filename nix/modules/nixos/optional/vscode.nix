{
  pkgs,
  inputs,
  system,
  ...
}:
let
  vscode = pkgs.symlinkJoin {
    name = pkgs.vscode.name;
    paths = [ pkgs.vscode ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    passthru = pkgs.vscode.passthru // {
      inherit (pkgs.vscode) executableName longName;
    };
    postBuild = ''
      wrapProgram $out/bin/code --unset NIXOS_OZONE_WL
    '';
  };
  vscodePkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [ inputs.nix-vscode-extensions.overlays.default ];
  };
  vscode-marketplace = vscodePkgs.nix-vscode-extensions.vscode-marketplace;
  vscode-marketplace-universal = vscodePkgs.nix-vscode-extensions.vscode-marketplace-universal;
in
{
  environment.systemPackages = [
    (pkgs.vscode-with-extensions.override {
      inherit vscode;

      vscodeExtensions =
        (with vscode-marketplace; [
          andreilucaci.everforest-pro
          enkia.tokyo-night
          teabyii.ayu
          vscode-icons-team.vscode-icons
          vscodevim.vim
          evgeniypeshkov.syntax-highlighter
          waderyan.gitblame
          golang.go
          ziglang.vscode-zig
          ms-vscode.cmake-tools
          ms-vscode.cpptools
          ms-vscode.cpptools-extension-pack
          ms-vscode.cpptools-themes
          twxs.cmake
          ms-azuretools.vscode-docker
          ms-vscode-remote.remote-containers
          wakatime.vscode-wakatime
        ])
        ++ [
          vscode-marketplace-universal.vadimcn.vscode-lldb
        ];
    })
  ];
}
