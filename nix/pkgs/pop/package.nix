{
  lib,
  stdenv,
  fetchurl,
  makeFontsConf,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  makeShellWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libpulseaudio,
  libxkbcommon,
  nspr,
  nss,
  pango,
  pipewire,
  systemdLibs,
  vulkan-loader,
  wayland,
  libx11,
  libxscrnsaver,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxtst,
  libxcb,
  libxshmfence,
}:
let
  fontsConf = makeFontsConf {
    fontDirectories = [ "/run/current-system/sw/share/X11/fonts" ];
    includes = [ ];
  };
in
stdenv.mkDerivation rec {
  pname = "pop";
  version = "8.0.21";

  src = fetchurl {
    url = "https://download.pop.com/desktop-app/linux/${version}/pop_${version}_amd64.deb";
    sha256 = "1n9h1vn3scvpwv0vmkpygi6rqznzs0vj6y6hyzh12qgv67zwm75v";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
    makeShellWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libglvnd
    libnotify
    libxkbcommon
    nspr
    nss
    pango
    libx11
    libxscrnsaver
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxtst
    libxcb
    libxshmfence
  ];

  dontWrapGApps = true;

  libPath = lib.makeLibraryPath [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libglvnd
    libnotify
    libpulseaudio
    libxkbcommon
    nspr
    nss
    pango
    pipewire
    stdenv.cc.cc
    systemdLibs
    vulkan-loader
    wayland
    libx11
    libxscrnsaver
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxtst
    libxcb
    libxshmfence
  ];

  unpackPhase = ''
    dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{opt/pop,bin,share/icons/hicolor/256x256/apps,share/applications}

    mv usr/lib/pop/* $out/opt/pop/

    chmod +x $out/opt/pop/Pop
    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
        $out/opt/pop/Pop

    wrapProgramShell $out/opt/pop/Pop \
        "''${gappsWrapperArgs[@]}" \
        --set DISPLAY ":0" \
        --set FONTCONFIG_FILE "${fontsConf}" \
        --add-flags "--ozone-platform=x11" \
        --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}/" \
        --prefix LD_LIBRARY_PATH : $libPath:$out/opt/pop

    ln -s $out/opt/pop/Pop $out/bin/pop

    cp usr/share/pixmaps/pop.png $out/share/icons/hicolor/256x256/apps/pop.png

    cp usr/share/applications/pop.desktop $out/share/applications/pop.desktop
    substituteInPlace $out/share/applications/pop.desktop \
      --replace-fail "/usr/bin/pop" "$out/bin/pop" \
      --replace-fail "/usr/share/pixmaps/pop.png" "pop"

    runHook postInstall
  '';

  meta = {
    description = "Low latency videoconferencing & screen sharing with multiplayer drawing & control";
    homepage = "https://pop.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pop";
  };
}
