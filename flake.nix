{
  description = "Zone Sequencer Module for Logos App";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/e9f00bd893984bc8ce46c895c3bf7cac95331127";
    nixpkgs-rust.url = "github:NixOS/nixpkgs/bfc1b8a4574108ceef22f02bafcf6611380c100d";
    logos-cpp-sdk = {
      url = "github:logos-co/logos-cpp-sdk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    logos-liblogos = {
      url = "github:logos-co/logos-liblogos";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.logos-cpp-sdk.follows = "logos-cpp-sdk";
    };
    logos-package = {
      url = "github:logos-co/logos-package/a2eec3694558d49fcc4abcbacb0b23c24380ade9";
    };
    # v0.2 port: point at our v0.2 branch (logos-blockchain testnet 0.2.0).
    # See xAlisher/zone-sequencer-rs#5 / PR vpavlin/zone-sequencer-rs#2.
    zone-sequencer-rs = {
      url = "github:xAlisher/zone-sequencer-rs/4e97df4";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-rust, logos-cpp-sdk, logos-liblogos, logos-package, zone-sequencer-rs, ... }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
        pkgsRust = import nixpkgs-rust { inherit system; };
        logosSdk = logos-cpp-sdk.packages.${system}.default;
        logosLiblogos = logos-liblogos.packages.${system}.default;
        lgxTool = logos-package.packages.${system}.lgx;
      });
    in
    {
      packages = forAllSystems ({ pkgs, pkgsRust, logosSdk, logosLiblogos, lgxTool }:
        let
          circuits = builtins.fetchTarball {
            url = "https://github.com/logos-blockchain/logos-blockchain/releases/download/0.1.1/logos-blockchain-circuits-v0.4.1-linux-x86_64.tar.gz";
            sha256 = "1xnhl4y2zpxvcgm0xx95v0v6av2amp5isfi0s92cxrjg7dqmp5z8";
          };

          # v0.2 added rust-rapidsnark (zk prover). Its build.rs DOWNLOADS a prebuilt
          # C lib unless RAPIDSNARK_LIB_DIR is set — and the nix sandbox blocks network.
          # Provide the pinned prebuilt PIC archive (sha from the rapidsnark repo's
          # nix-hashes.json), mirroring that repo's own flake.
          rapidsnarkLib = pkgs.fetchzip {
            url = "https://github.com/logos-blockchain/logos-blockchain-rust-rapidsnark/releases/download/rapidsnark-pic-v0.0.8/rapidsnark-linux-x86_64-pic-v0.0.8.zip";
            hash = "sha256-88+TkECQYCKBN0WbYLRB+qi6TEhbjVfrpCqlSgm0DR8=";
          };

          # v0.2 circuits crates (v0.5.3) also DOWNLOAD prebuilt artifacts at build time
          # unless LBC_ROOT_DIR points at a local copy. Provide the pinned v0.5.3 artifact
          # (root has lib/ poc/ pol/ poq/ prover/ signature/ verifier/ VERSION).
          lbcRoot = builtins.fetchTarball {
            url = "https://github.com/logos-blockchain/logos-blockchain-circuits/releases/download/v0.5.3/logos-blockchain-circuits-v0.5.3-linux-x86_64.tar.gz";
            sha256 = "1mwy3g9dyjvlwykzs62gzf79rrnm20sy7c587nv26c1y9bm71wfv";
          };

          # v0.2: deps come from the cleaned fork xAlisher/logos-blockchain
          # (logos-blockchain#3062 workaround). outputHashes below cover the
          # v0.2 git dep set (regenerate if the lock changes).
          rustLib = pkgsRust.rustPlatform.buildRustPackage {
            pname = "zone-sequencer-rs";
            version = "0.2.0";
            src = zone-sequencer-rs;

            cargoLock = {
              lockFile = "${zone-sequencer-rs}/Cargo.lock";
              outputHashes = {
                "jf-crhf-0.2.0" = "sha256-fF5gqFm7xYLubl2QzNilcZl3O0NZMFckChrr7kVudok=";
                "jf-poseidon2-0.2.0" = "sha256-XeOEusSl7YkdE05emaDjH1SccutWZt/6ty5l/9ylxNM=";
                "logos-blockchain-blend-crypto-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-blend-message-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-blend-proofs-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-chain-broadcast-service-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-chain-service-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-circuits-build-0.5.3" = "sha256-kzf4l4UywcxMqQwQcACBQl1QZYT9Nl6gbpb5FaphFqo=";
                "logos-blockchain-circuits-common-0.5.3" = "sha256-kzf4l4UywcxMqQwQcACBQl1QZYT9Nl6gbpb5FaphFqo=";
                "logos-blockchain-circuits-poc-sys-0.5.3" = "sha256-kzf4l4UywcxMqQwQcACBQl1QZYT9Nl6gbpb5FaphFqo=";
                "logos-blockchain-circuits-pol-sys-0.5.3" = "sha256-kzf4l4UywcxMqQwQcACBQl1QZYT9Nl6gbpb5FaphFqo=";
                "logos-blockchain-circuits-poq-sys-0.5.3" = "sha256-kzf4l4UywcxMqQwQcACBQl1QZYT9Nl6gbpb5FaphFqo=";
                "logos-blockchain-circuits-prover-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-circuits-signature-sys-0.5.3" = "sha256-kzf4l4UywcxMqQwQcACBQl1QZYT9Nl6gbpb5FaphFqo=";
                "logos-blockchain-circuits-types-0.5.3" = "sha256-kzf4l4UywcxMqQwQcACBQl1QZYT9Nl6gbpb5FaphFqo=";
                "logos-blockchain-common-http-client-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-core-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-cryptarchia-engine-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-cryptarchia-sync-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-groth16-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-http-api-common-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-key-management-system-keys-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-key-management-system-macros-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-key-management-system-operators-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-key-management-system-service-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-ledger-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-libp2p-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-log-targets-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-log-targets-macros-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-mmr-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-network-service-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-poc-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-pol-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-poq-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-poseidon2-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-proofs-error-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-services-utils-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-storage-service-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-time-service-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-tracing-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-utils-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-utxotree-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-zksign-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "logos-blockchain-zone-sdk-0.1.2" = "sha256-HthHmQBHnqJqb7qrD3fv97s5cSI1OwRQUPwEue4Twrg=";
                "overwatch-0.1.0" = "sha256-L7R1GdhRNNsymYe3RVyYLAmd6x1YY08TBJp4hG4/YwE=";
                "overwatch-derive-0.1.0" = "sha256-L7R1GdhRNNsymYe3RVyYLAmd6x1YY08TBJp4hG4/YwE=";
                "rust-rapidsnark-0.1.3" = "sha256-A1wVkHRw3/xpV30JUgWxvfW5PgcyrxQxk7b4So5vXNs=";
                "spongefish-0.2.0" = "sha256-prLkGrIavkaiVYKqSy+cLwl2Y1TkTp8vGl0HCeQdILc=";
              };
            };

            LOGOS_BLOCKCHAIN_CIRCUITS = circuits;
            # Skip rust-rapidsnark's network download; link the pinned prebuilt libs.
            RAPIDSNARK_LIB_DIR = "${rapidsnarkLib}/lib";
            # Skip the circuits crates' network download; use the pinned v0.5.3 artifact.
            LBC_ROOT_DIR = "${lbcRoot}";

            nativeBuildInputs = [ pkgsRust.pkg-config pkgsRust.perl ];
            buildInputs = [ pkgsRust.openssl ];

            installPhase = ''
              runHook preInstall
              mkdir -p $out/lib
              find target -name 'libzone_sequencer_rs.so' -path '*/release/*' -exec install -m755 {} $out/lib/ \;
              runHook postInstall
            '';
          };

          buildInputs = [
            pkgs.qt6.qtbase
          ];

          plugin = pkgs.stdenv.mkDerivation {
            pname = "logos-zone-sequencer-module";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = [
              pkgs.cmake
              pkgs.ninja
              pkgs.pkg-config
              pkgs.patchelf
            ];

            inherit buildInputs;

            cmakeFlags = [
              "-DLOGOS_CPP_SDK_ROOT=${logosSdk}"
              "-DZONE_SEQUENCER_RS_LIB_DIR=${rustLib}/lib"
              "-GNinja"
            ];

            buildPhase = ''
              runHook preBuild
              ninja logos_zone_sequencer_module -j''${NIX_BUILD_CORES:-1}
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out/lib
              cp liblogos_zone_sequencer_module.so $out/lib/
              cp ${rustLib}/lib/libzone_sequencer_rs.so $out/lib/
              runHook postInstall
            '';

            postFixup = ''
              patchelf --set-rpath "$out/lib:${logosLiblogos}/lib:${pkgs.lib.makeLibraryPath buildInputs}" \
                $out/lib/liblogos_zone_sequencer_module.so
            '';

            dontWrapQtApps = true;
          };

          patchManifest = name: metadataFile: ''
            python3 - ${name}.lgx ${metadataFile} <<'PY'
            import json, sys, tarfile, io

            lgx_path = sys.argv[1]
            with open(sys.argv[2]) as f:
                metadata = json.load(f)

            built_variants = {'linux-amd64', 'linux-amd64-dev'}

            with tarfile.open(lgx_path, 'r:gz') as tar:
                members = [(m, tar.extractfile(m).read() if m.isfile() else None) for m in tar.getmembers()]

            patched = []
            for member, data in members:
                if member.name == 'manifest.json':
                    manifest = json.loads(data)
                    for key in ('name', 'version', 'description', 'author', 'type', 'category', 'dependencies', 'capabilities', 'manifestVersion'):
                        if key in metadata:
                            manifest[key] = metadata[key]
                    if 'main' in manifest and isinstance(manifest['main'], dict):
                        manifest["main"] = {k: v for k, v in manifest["main"].items() if k in built_variants}
                    data = json.dumps(manifest, indent=2).encode()
                    member.size = len(data)
                patched.append((member, data))

            with tarfile.open(lgx_path, 'w:gz', format=tarfile.GNU_FORMAT) as tar:
                for member, data in patched:
                    if data is not None:
                        tar.addfile(member, io.BytesIO(data))
                    else:
                        tar.addfile(member)
            PY
          '';

          lgx = pkgs.runCommand "zone-sequencer.lgx" {
            nativeBuildInputs = [ lgxTool pkgs.python3 ];
          } ''
            lgx create zone-sequencer

            mkdir -p variant-files
            cp ${plugin}/lib/liblogos_zone_sequencer_module.so variant-files/
            cp ${plugin}/lib/libzone_sequencer_rs.so variant-files/

            # Add both portable (linux-amd64) and lgpm (linux-amd64-dev) variants.
            # Basecamp loads the portable name; lgpm installs using the -dev name.
            lgx add zone-sequencer.lgx --variant linux-amd64     --files ./variant-files --main liblogos_zone_sequencer_module.so -y
            lgx add zone-sequencer.lgx --variant linux-amd64-dev --files ./variant-files --main liblogos_zone_sequencer_module.so -y

            ${patchManifest "zone-sequencer" "${self}/manifest.json"}

            lgx verify zone-sequencer.lgx

            cp zone-sequencer.lgx $out
          '';

        in
        {
          inherit plugin rustLib lgx;
          lgx-portable = lgx;
          default = lgx;
        }
      );
    };
}
