{ pkgs, ... }:
let
  pop = pkgs.stdenv.mkDerivation rec {
    pname = "pop";
    version = "8.0.21";

    src = pkgs.fetchurl {
      url = "https://download.pop.com/desktop-app/linux/${version}/pop_${version}_amd64.deb";
      sha256 = "1n9h1vn3scvpwv0vmkpygi6rqznzs0vj6y6hyzh12qgv67zwm75v";
    };

    nativeBuildInputs = with pkgs; [
      dpkg
      autoPatchelfHook
      wrapGAppsHook3
      makeShellWrapper
    ];

    buildInputs = with pkgs; [
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

    libPath = pkgs.lib.makeLibraryPath [
      pkgs.alsa-lib
      pkgs.at-spi2-atk
      pkgs.at-spi2-core
      pkgs.cairo
      pkgs.cups
      pkgs.dbus
      pkgs.expat
      pkgs.fontconfig
      pkgs.freetype
      pkgs.gdk-pixbuf
      pkgs.glib
      pkgs.gtk3
      pkgs.libdrm
      pkgs.libgbm
      pkgs.libglvnd
      pkgs.libnotify
      pkgs.libpulseaudio
      pkgs.libxkbcommon
      pkgs.nspr
      pkgs.nss
      pkgs.pango
      pkgs.pipewire
      pkgs.stdenv.cc.cc
      pkgs.systemdLibs
      pkgs.vulkan-loader
      pkgs.wayland
      pkgs.libx11
      pkgs.libxscrnsaver
      pkgs.libxcomposite
      pkgs.libxdamage
      pkgs.libxext
      pkgs.libxfixes
      pkgs.libxrandr
      pkgs.libxtst
      pkgs.libxcb
      pkgs.libxshmfence
    ];

    unpackPhase = ''
      dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{opt/pop,bin,share/icons/hicolor/256x256/apps,share/applications}

      mv usr/lib/pop/* $out/opt/pop/

      chmod +x $out/opt/pop/Pop
      patchelf --set-interpreter ${pkgs.stdenv.cc.bintools.dynamicLinker} \
          $out/opt/pop/Pop

      wrapProgramShell $out/opt/pop/Pop \
          "''${gappsWrapperArgs[@]}" \
          --unset WAYLAND_DISPLAY \
          --set DISPLAY ":0" \
          --add-flags "--ozone-platform=x11" \
          --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/" \
          --prefix LD_LIBRARY_PATH : $libPath:$out/opt/pop

      ln -s $out/opt/pop/Pop $out/bin/pop

      cp usr/share/pixmaps/pop.png $out/share/icons/hicolor/256x256/apps/pop.png

      cp usr/share/applications/pop.desktop $out/share/applications/pop.desktop
      substituteInPlace $out/share/applications/pop.desktop \
        --replace-fail "/usr/bin/pop" "$out/bin/pop" \
        --replace-fail "/usr/share/pixmaps/pop.png" "pop"

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Low latency videoconferencing & screen sharing with multiplayer drawing & control";
      homepage = "https://pop.com";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "pop";
    };
  };
in
{
  environment.systemPackages = [ pop ];
}
