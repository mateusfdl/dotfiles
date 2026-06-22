{
  pkgs,
  inputs,
  system,
  ...
}:
let
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
      vscodeExtensions =
        (with vscode-marketplace; [
          andreilucaci.everforest-pro
          enkia.tokyo-night
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
