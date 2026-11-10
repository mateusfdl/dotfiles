{
  lib,
  clangStdenv,
  fetchFromGitHub,
  copyDesktopItems,
  makeDesktopItem,
  pkg-config,
  freetype,
  libGL,
  libx11,
  libxext,
  libxfixes,
  libxrandr,
  zenity,
  llvm,
}:
let
  zenityBin = lib.getExe zenity;
  llvmSymbolizer = lib.getExe' llvm "llvm-symbolizer";
in
clangStdenv.mkDerivation {
  pname = "raddebugger";
  version = "0.9.29-alpha-unstable-2026-11-02";

  src = fetchFromGitHub {
    owner = "EpicGames";
    repo = "raddebugger";
    rev = "5ddba649d3e3232c7380df1c00f01f340662501d";
    hash = "sha256-3Pbr+HyD+qGXNwHRq4dBEU149vD2iIV3wljRhmAt0XQ=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    copyDesktopItems
    pkg-config
  ];

  buildInputs = [
    freetype
    libGL
    libx11
    libxext
    libxfixes
    libxrandr
  ];

  postPatch = ''
    substituteInPlace src/linux/shell/linux_shell.c \
      --replace-fail '| zenity ' '| ${zenityBin} ' \
      --replace-fail '"zenity ' '"${zenityBin} '
    substituteInPlace src/linux/base/linux_base.c \
      --replace-fail '"llvm-symbolizer ' '"${llvmSymbolizer} '
  '';

  buildPhase = ''
    runHook preBuild
    bash build.sh raddbg clang release
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 build/raddbg $out/bin/raddbg
    install -Dm644 data/logo.png $out/share/icons/hicolor/256x256/apps/raddbg.png
    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "raddbg";
      desktopName = "RAD Debugger";
      genericName = "Debugger";
      comment = "Native, user-mode, multi-process, graphical debugger";
      exec = "raddbg";
      icon = "raddbg";
      categories = [
        "Development"
        "Debugger"
      ];
      startupWMClass = "RADDBG";
    })
  ];

  meta = {
    description = "Native, user-mode, multi-process, graphical debugger";
    homepage = "https://github.com/EpicGames/raddebugger";
    license = lib.licenses.mit;
    mainProgram = "raddbg";
    platforms = [ "x86_64-linux" ];
  };
}
