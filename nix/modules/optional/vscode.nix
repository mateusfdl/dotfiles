{ pkgs, vscode-marketplace, ... }:
{
  environment.systemPackages = [
    (pkgs.vscode-with-extensions.override {
      vscodeExtensions = with vscode-marketplace; [
        # Themes
        andreilucaci.everforest-pro
        enkia.tokyo-night
        vscode-icons-team.vscode-icons

        # Editor
        vscodevim.vim
        evgeniypeshkov.syntax-highlighter

        # Git
        waderyan.gitblame

        # AI
        anthropic.claude-code

        # Languages
        golang.go
        ziglang.vscode-zig

        # C/C++
        ms-vscode.cmake-tools
        ms-vscode.cpptools
        ms-vscode.cpptools-extension-pack
        ms-vscode.cpptools-themes
        twxs.cmake

        # Debugging
        vadimcn.vscode-lldb

        # Containers
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-containers

        # Productivity
        wakatime.vscode-wakatime
      ];
    })
  ];
}
