{
  description = "logos-lez-multisig-module — Qt6 Logos Core plugin and standalone app for LEZ Multisig governance";

  inputs = {
    nixpkgs.follows = "logos-liblogos/nixpkgs";

    logos-liblogos.url = "github:logos-co/logos-liblogos";
    logos-cpp-sdk.url = "github:logos-co/logos-cpp-sdk";
    logos-capability-module.url = "github:logos-co/logos-capability-module";

    lez-multisig-ffi.url = "github:jimmy-claw/lez-multisig-framework";
    lez-registry-ffi.url = "github:jimmy-claw/lez-registry?dir=lez-registry-ffi";

    logos-lez-registry-module = {
      url = "github:jimmy-claw/logos-lez-registry-module";
      inputs.logos-liblogos.follows = "logos-liblogos";
      inputs.logos-cpp-sdk.follows = "logos-cpp-sdk";
      inputs.logos-capability-module.follows = "logos-capability-module";
      inputs.lez-registry-ffi.follows = "lez-registry-ffi";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      logos-cpp-sdk,
      logos-liblogos,
      logos-capability-module,
      lez-multisig-ffi,
      lez-registry-ffi,
      logos-lez-registry-module,
      ...
    }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
        logosSdk = logos-cpp-sdk.packages.${system}.default;
        logosLiblogos = logos-liblogos.packages.${system}.default;
        logosCapabilityModule = logos-capability-module.packages.${system}.default;
        lezMultisigFfi = lez-multisig-ffi.packages.${system}.default;
        lezRegistryFfi = lez-registry-ffi.packages.${system}.default;
        lezRegistryModule = logos-lez-registry-module.packages.${system}.default;
      });
    in
    {
      packages = forAllSystems ({ pkgs, logosSdk, logosLiblogos, logosCapabilityModule, lezMultisigFfi, lezRegistryFfi, lezRegistryModule }:
        let
          common = import ./nix/default.nix {
            inherit pkgs logosSdk logosLiblogos;
          };
          src = ./.;

          lib = import ./nix/lib.nix {
            inherit pkgs common src logosSdk logosLiblogos lezMultisigFfi lezRegistryFfi;
          };

          app = import ./nix/app.nix {
            inherit pkgs common src logosLiblogos logosSdk logosCapabilityModule lezMultisigFfi lezRegistryFfi lezRegistryModule;
            lezMultisigModule = lib;
          };

          ui = import ./nix/ui.nix {
            inherit pkgs common src logosSdk logosLiblogos lezMultisigFfi lezRegistryFfi;
          };
        in
        {
          inherit lib app ui;
          default = lib;
        }
      );

      devShells = forAllSystems ({ pkgs, logosSdk, logosLiblogos, lezMultisigFfi, lezRegistryFfi, ... }: {
        default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.cmake
            pkgs.ninja
            pkgs.pkg-config
          ];
          buildInputs = [
            pkgs.qt6.qtbase
            pkgs.qt6.qtremoteobjects
            pkgs.qt6.qtdeclarative
            pkgs.zstd
            pkgs.krb5
            pkgs.abseil-cpp
          ];

          shellHook = ''
            export LOGOS_CPP_SDK_ROOT="${logosSdk}"
            export LOGOS_LIBLOGOS_ROOT="${logosLiblogos}"
            export LEZ_MULTISIG_FFI_ROOT="${lezMultisigFfi}"
            export LEZ_REGISTRY_FFI_ROOT="${lezRegistryFfi}"
            echo "LEZ Multisig Module development environment"
          '';
        };
      });
    };
}
