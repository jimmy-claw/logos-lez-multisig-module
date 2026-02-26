# Builds the lez-multisig-ui IComponent plugin .so (for logos-app-poc "UI Modules" tab)
{ pkgs, common, src, logosSdk, logosLiblogos, lezMultisigFfi, lezRegistryFfi }:

let
  llvmPkgs = pkgs.llvmPackages;

  # Create a merged LOGOS_CORE_ROOT with headers from SDK and libs from liblogos
  mergedLogosCore = pkgs.symlinkJoin {
    name = "logos-core-merged";
    paths = [ logosSdk logosLiblogos ];
  };
in
pkgs.stdenv.mkDerivation {
  pname = "${common.pname}-ui";
  version = common.version;

  inherit src;
  inherit (common) meta;

  nativeBuildInputs = common.nativeBuildInputs;

  buildInputs = common.buildInputs ++ [
    llvmPkgs.clang
    llvmPkgs.libclang
    lezMultisigFfi
    lezRegistryFfi
  ];

  LIBCLANG_PATH = "${llvmPkgs.libclang.lib}/lib";
  CLANG_PATH = "${llvmPkgs.clang}/bin/clang";

  cmakeFlags = [
    "-GNinja"
    "-DLOGOS_CORE_ROOT=${mergedLogosCore}"
    "-DLEZ_MULTISIG_LIB=${lezMultisigFfi}/lib"
    "-DLEZ_MULTISIG_INCLUDE=${lezMultisigFfi}/include"
    "-DLEZ_REGISTRY_INCLUDE=${lezRegistryFfi}/include"
    "-DBUILD_UI_PLUGIN=ON"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    found=""
    for f in $(find . -name "liblez_multisig_ui.so" -type f); do
      cp "$f" $out/lib/
      found=1
    done
    if [ -z "$found" ]; then
      echo "Error: liblez_multisig_ui.so not found"
      find . -name "liblez_multisig*" -type f
      exit 1
    fi

    runHook postInstall
  '';
}
