{ pkgs, vscode-marketplace, ... }:
{
  environment.systemPackages = [
    (pkgs.vscode-with-extensions.override {
      vscodeExtensions = with vscode-marketplace; [
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
        vadimcn.vscode-lldb
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-containers
        wakatime.vscode-wakatime
      ];
    })
  ];
}
