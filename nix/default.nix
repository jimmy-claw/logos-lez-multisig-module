# Common build configuration shared across all packages
{ pkgs, logosSdk, logosLiblogos }:

{
  pname = "logos-lez-multisig";
  version = "0.1.0";

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.ninja
    pkgs.pkg-config
    pkgs.qt6.wrapQtAppsHook
  ];

  buildInputs = [
    pkgs.qt6.qtbase
    pkgs.qt6.qtremoteobjects
    pkgs.qt6.qtdeclarative
    pkgs.zstd
    pkgs.krb5
    pkgs.abseil-cpp
  ];

  cmakeFlags = [
    "-GNinja"
    "-DLOGOS_CPP_SDK_ROOT=${logosSdk}"
    "-DLOGOS_LIBLOGOS_ROOT=${logosLiblogos}"
  ];

  env = {
    LOGOS_CPP_SDK_ROOT = "${logosSdk}";
    LOGOS_LIBLOGOS_ROOT = "${logosLiblogos}";
  };

  meta = with pkgs.lib; {
    description = "LEZ Multisig - Logos Core Qt6 plugin and standalone app";
    platforms = platforms.unix;
  };
}
