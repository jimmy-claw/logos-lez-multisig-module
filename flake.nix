{
  description = "logos-lez-multisig-module — Qt6 Logos Core plugin and standalone app for LEZ Multisig governance";

  inputs = {
    nixpkgs.follows = "logos-liblogos/nixpkgs";

    logos-liblogos.url = "github:logos-co/logos-liblogos";
    logos-cpp-sdk.url = "github:logos-co/logos-cpp-sdk";
    logos-capability-module.url = "github:logos-co/logos-capability-module";

    # NOTE: lez-multisig-ffi does not exist yet in the lez-multisig repo.
    # Once it's created (similar to lez-registry-ffi), uncomment and point here:
    # lez-multisig-ffi.url = "github:jimmy-claw/lez-multisig?dir=lez-multisig-ffi";

    # Re-use lez-registry-ffi for the registry_bridge header
    lez-registry-ffi.url = "github:jimmy-claw/lez-registry?dir=lez-registry-ffi";
  };

  outputs =
    {
      self,
      nixpkgs,
      logos-cpp-sdk,
      logos-liblogos,
      logos-capability-module,
      lez-registry-ffi,
      ...
    }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
        logosSdk = logos-cpp-sdk.packages.${system}.default;
        logosLiblogos = logos-liblogos.packages.${system}.default;
        logosCapabilityModule = logos-capability-module.packages.${system}.default;
        lezRegistryFfi = lez-registry-ffi.packages.${system}.default;
      });
    in
    {
      packages = forAllSystems ({ pkgs, logosSdk, logosLiblogos, logosCapabilityModule, lezRegistryFfi }:
        let
          common = import ./nix/default.nix {
            inherit pkgs logosSdk logosLiblogos;
          };
          src = ./.;

          # Stub FFI: creates a minimal .so and header so the build can link
          # Replace with the real lez-multisig-ffi input once it exists
          lezMultisigFfiStub = pkgs.stdenv.mkDerivation {
            pname = "lez-multisig-ffi-stub";
            version = "0.0.0";
            dontUnpack = true;
            buildPhase = ''
              # Create a stub shared library
              cat > stub.c << 'EOF'
              /* Stub implementations — replace with real lez-multisig-ffi */
              const char* lez_multisig_version(void) { return "stub-0.0.0"; }
              void lez_multisig_free_string(char* s) { (void)s; }
              EOF
              $CC -shared -o liblez_multisig_ffi.so stub.c

              # Create a minimal header
              mkdir -p include
              cat > include/lez_multisig.h << 'HEOF'
              #ifndef LEZ_MULTISIG_H
              #define LEZ_MULTISIG_H
              #ifdef __cplusplus
              extern "C" {
              #endif
              const char* lez_multisig_version(void);
              void lez_multisig_free_string(char* s);
              #ifdef __cplusplus
              }
              #endif
              #endif
              HEOF
            '';
            installPhase = ''
              mkdir -p $out/lib $out/include
              cp liblez_multisig_ffi.so $out/lib/
              cp include/lez_multisig.h $out/include/
            '';
          };

          lezMultisigFfi = lezMultisigFfiStub;

          lib = import ./nix/lib.nix {
            inherit pkgs common src logosSdk logosLiblogos lezMultisigFfi lezRegistryFfi;
          };

          app = import ./nix/app.nix {
            inherit pkgs common src logosLiblogos logosSdk logosCapabilityModule lezMultisigFfi lezRegistryFfi;
            lezMultisigModule = lib;
          };
        in
        {
          inherit lib app;
          default = lib;
        }
      );

      devShells = forAllSystems ({ pkgs, logosSdk, logosLiblogos, lezRegistryFfi, ... }: {
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
            export LEZ_REGISTRY_INCLUDE="${lezRegistryFfi}/include"
            echo "LEZ Multisig Module development environment"
            echo "NOTE: lez-multisig-ffi not yet available — using stubs"
          '';
        };
      });
    };
}
