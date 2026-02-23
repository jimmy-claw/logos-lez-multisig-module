# Builds the logos-lez-multisig-app standalone application
{ pkgs, common, src, logosLiblogos, logosSdk, logosCapabilityModule, lezMultisigFfi, lezRegistryFfi, lezMultisigModule }:

pkgs.stdenv.mkDerivation rec {
  pname = "logos-lez-multisig-app";
  version = common.version;

  inherit src;
  inherit (common) buildInputs cmakeFlags meta env;

  nativeBuildInputs = common.nativeBuildInputs ++ [ pkgs.patchelf pkgs.removeReferencesTo ];

  qtLibPath = pkgs.lib.makeLibraryPath (
    [
      pkgs.qt6.qtbase
      pkgs.qt6.qtremoteobjects
      pkgs.qt6.qtdeclarative
      pkgs.zstd
      pkgs.krb5
      pkgs.zlib
      pkgs.glib
      pkgs.stdenv.cc.cc
      pkgs.freetype
      pkgs.fontconfig
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
      pkgs.libglvnd
      pkgs.mesa.drivers
      pkgs.xorg.libX11
      pkgs.xorg.libXext
      pkgs.xorg.libXrender
      pkgs.xorg.libXrandr
      pkgs.xorg.libXcursor
      pkgs.xorg.libXi
      pkgs.xorg.libXfixes
      pkgs.xorg.libxcb
    ]
  );
  qtPluginPath = "${pkgs.qt6.qtbase}/lib/qt-6/plugins";

  dontWrapQtApps = false;
  dontStrip = true;

  qtWrapperArgs = [
    "--prefix" "LD_LIBRARY_PATH" ":" qtLibPath
    "--prefix" "QT_PLUGIN_PATH" ":" qtPluginPath
    "--set" "QT_QUICK_BACKEND" "software"
  ];

  preConfigure = ''
    runHook prePreConfigure

    # Copy logos-cpp-sdk headers
    mkdir -p ./logos-cpp-sdk/include/cpp
    cp -r ${logosSdk}/include/cpp/* ./logos-cpp-sdk/include/cpp/
    mkdir -p ./logos-cpp-sdk/include/core
    cp -r ${logosSdk}/include/core/* ./logos-cpp-sdk/include/core/

    # Copy SDK library
    mkdir -p ./logos-cpp-sdk/lib
    if [ -f "${logosSdk}/lib/liblogos_sdk.so" ]; then
      cp "${logosSdk}/lib/liblogos_sdk.so" ./logos-cpp-sdk/lib/
    elif [ -f "${logosSdk}/lib/liblogos_sdk.a" ]; then
      cp "${logosSdk}/lib/liblogos_sdk.a" ./logos-cpp-sdk/lib/
    fi

    runHook postPreConfigure
  '';

  preFixup = ''
    runHook prePreFixup

    export QT_PLUGIN_PATH="${pkgs.qt6.qtbase}/lib/qt-6/plugins"
    export QML_IMPORT_PATH="${pkgs.qt6.qtbase}/lib/qt-6/qml"

    find $out -type f -executable -exec sh -c '
      if file "$1" | grep -q "ELF.*executable"; then
        if patchelf --print-rpath "$1" 2>/dev/null | grep -q "/build/"; then
          patchelf --remove-rpath "$1" 2>/dev/null || true
        fi
        if echo "$1" | grep -q "/logos-lez-multisig-app$"; then
          patchelf --set-rpath "$out/lib" "$1" 2>/dev/null || true
        fi
      fi
    ' _ {} \;

    find $out -name "*.so" -exec sh -c '
      if patchelf --print-rpath "$1" 2>/dev/null | grep -q "/build/"; then
        patchelf --remove-rpath "$1" 2>/dev/null || true
      fi
    ' _ {} \;

    runHook prePostFixup
  '';

  configurePhase = ''
    runHook preConfigure

    echo "Configuring logos-lez-multisig-app..."
    echo "liblogos: ${logosLiblogos}"
    echo "cpp-sdk: ${logosSdk}"
    echo "capability-module: ${logosCapabilityModule}"
    echo "lez-multisig-ffi: ${lezMultisigFfi}"
    echo "lez-multisig-module: ${lezMultisigModule}"

    test -d "${logosLiblogos}" || (echo "liblogos not found" && exit 1)
    test -d "${logosSdk}" || (echo "cpp-sdk not found" && exit 1)
    test -d "${logosCapabilityModule}" || (echo "capability-module not found" && exit 1)
    test -d "${lezMultisigModule}" || (echo "lez-multisig-module not found" && exit 1)

    cmake -S app -B build \
      -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=FALSE \
      -DCMAKE_INSTALL_RPATH="" \
      -DCMAKE_SKIP_BUILD_RPATH=TRUE \
      -DLOGOS_LIBLOGOS_ROOT=${logosLiblogos} \
      -DLOGOS_CPP_SDK_ROOT=$(pwd)/logos-cpp-sdk

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    cmake --build build
    echo "logos-lez-multisig-app built successfully!"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib $out/modules $out/qml

    # Install app binary
    if [ -f "build/bin/logos-lez-multisig-app" ]; then
      cp build/bin/logos-lez-multisig-app "$out/bin/"
    fi

    # Copy core binaries from liblogos
    if [ -f "${logosLiblogos}/bin/logoscore" ]; then
      cp -L "${logosLiblogos}/bin/logoscore" "$out/bin/"
    fi
    if [ -f "${logosLiblogos}/bin/logos_host" ]; then
      cp -L "${logosLiblogos}/bin/logos_host" "$out/bin/"
    fi

    # Copy shared libraries
    if ls "${logosLiblogos}/lib/"liblogos_core.* >/dev/null 2>&1; then
      cp -L "${logosLiblogos}/lib/"liblogos_core.* "$out/lib/" || true
    fi
    if ls "${logosSdk}/lib/"liblogos_sdk.* >/dev/null 2>&1; then
      cp -L "${logosSdk}/lib/"liblogos_sdk.* "$out/lib/" || true
    fi

    # Copy lez-multisig-ffi library
    if ls "${lezMultisigFfi}/lib/"liblez_multisig_ffi.* >/dev/null 2>&1; then
      cp -L "${lezMultisigFfi}/lib/"liblez_multisig_ffi.* "$out/lib/" || true
    fi

    # Determine plugin extension
    OS_EXT="so"
    case "$(uname -s)" in
      Darwin) OS_EXT="dylib";;
    esac

    # Copy module plugins
    if [ -f "${logosCapabilityModule}/lib/capability_module_plugin.$OS_EXT" ]; then
      cp -L "${logosCapabilityModule}/lib/capability_module_plugin.$OS_EXT" "$out/modules/"
    fi
    if [ -f "${lezMultisigModule}/lib/liblez_multisig_module.$OS_EXT" ]; then
      cp -L "${lezMultisigModule}/lib/liblez_multisig_module.$OS_EXT" "$out/modules/"
    fi

    # Copy QML files for the app to find
    cp ${src}/qml/*.qml "$out/qml/" 2>/dev/null || true

    runHook postInstall
  '';
}
