{ pkgs, ... }:

let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    cmdLineToolsVersion = "19.0";
    platformToolsVersion = "36.0.0";
    buildToolsVersions = [ "36.0.0" "35.0.0" "34.0.0" ];
    platformVersions = [ "36" "35" "34" ];
    includeNDK = true;
    ndkVersions = [ "29.0.14206865" ];

    includeEmulator = true;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];
    abiVersions = [ "x86_64" ];

    extraLicenses = [
      "android-googletv-license"
      "android-googlexr-license"
      "android-sdk-arm-dbt-license"
      "android-sdk-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];
  };

  androidSdk = androidComposition.androidsdk;
in
{
  nixpkgs.config.android_sdk.accept_license = true;

  environment.variables = {
    PKG_CONFIG_PATH = "/run/current-system/sw/lib/pkgconfig:/run/current-system/sw/share/pkgconfig";
  };

  environment.sessionVariables = {
    CHROME_EXECUTABLE = "${pkgs.brave}/bin/brave";
    ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
    ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk-bundle";
    JAVA_HOME = "${pkgs.javaPackages.compiler.openjdk17}/lib/openjdk";
  };

  environment.systemPackages = with pkgs; [
    androidSdk
    android-tools
    android-studio
    javaPackages.compiler.openjdk17

    clang
    cmake
    ninja
    gtk3
    gtk3.dev
    pcre2.dev
    libepoxy.dev
    glib.dev
    pango.dev
    harfbuzz.dev
    cairo.dev
    gdk-pixbuf.dev
    atk.dev
    at-spi2-atk.dev
    libx11.dev
    mesa-demos
  ];

  users.users.matheus.extraGroups = [ "kvm" ];
}
