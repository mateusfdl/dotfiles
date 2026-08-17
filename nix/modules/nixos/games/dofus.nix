{ pkgs, ... }:
let
  pname = "ankama-launcher";
  version = "3.14.14";
  pad = pkgs.lib.strings.replicate 42 " ";

  src = pkgs.fetchurl {
    url = "https://web.archive.org/web/20260605015300/https://launcher.cdn.ankama.com/installers/production/Ankama%20Launcher-Setup-x86_64.AppImage";
    hash = "sha256-9w1ho9DZvDHXQbXjpMY1wnWDwYlMKO1igrJcCahQkVQ=";
  };

  extracted = pkgs.appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      ${pkgs.perl}/bin/perl -pi -e 's|autoupdaterUrl:"https://launcher\.cdn\.ankama\.com/installers"|autoupdaterUrl:""${pad}|g' $out/resources/app.asar
    '';
  };

  ankama-launcher = pkgs.appimageTools.wrapAppImage {
    inherit pname version;
    src = extracted;
    extraPkgs = p: [ p.wine ];
    profile = ''
      export __EGL_EXTERNAL_PLATFORM_CONFIG_DIRS=/run/opengl-driver/share/egl/egl_external_platform.d
      export SDL_VIDEODRIVER=X11
    '';
    extraInstallCommands = ''
      install -m 444 -D ${extracted}/zaap.desktop $out/share/applications/ankama-launcher.desktop
      sed -i 's/.*Exec.*/Exec=ankama-launcher/' $out/share/applications/ankama-launcher.desktop
      install -m 444 -D ${extracted}/zaap.png $out/share/icons/hicolor/256x256/apps/zaap.png
    '';
  };
in
{
  environment.systemPackages = [ ankama-launcher ];
}

