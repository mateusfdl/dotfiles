{
  lib,
  appimageTools,
  fetchurl,
  runtimeShell,
}:
appimageTools.wrapType2 (finalAttrs: {
  pname = "paseo-desktop";
  version = "0.16.1";

  src = fetchurl {
    url = "https://github.com/getpaseo/paseo/releases/download/v${finalAttrs.version}/Paseo-x86_64.AppImage";
    hash = "sha256-oYDhuC3btcxzRAMYWLAL9g43gxuLPSKre68xJYij4aM=";
  };

  extraInstallCommands = ''
    install -Dm444 ${finalAttrs.contents}/Paseo.desktop $out/share/applications/Paseo.desktop
    substituteInPlace $out/share/applications/Paseo.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${finalAttrs.pname}'
    cp -r ${finalAttrs.contents}/usr/share/icons $out/share

    cat > $out/bin/paseo <<EOF
    #!${runtimeShell}
    export ELECTRON_RUN_AS_NODE=1
    export PASEO_NODE_ENV=production
    export PASEO_CLI=${finalAttrs.contents}/resources/bin/paseo
    exec $out/bin/${finalAttrs.pname} --disable-warning=DEP0040 \
      ${finalAttrs.contents}/resources/app.asar.unpacked/dist/daemon/node-entrypoint-runner.js \
      node-script ${finalAttrs.contents}/resources/app.asar/node_modules/@getpaseo/cli/dist/index.js "\$@"
    EOF
    chmod +x $out/bin/paseo
  '';

  meta = {
    description = "Desktop app and CLI to run and supervise coding agents";
    homepage = "https://paseo.sh";
    license = lib.licenses.asl20;
    mainProgram = finalAttrs.pname;
    platforms = [ "x86_64-linux" ];
  };
})
