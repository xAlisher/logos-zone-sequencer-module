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
      url = "github:logos-co/logos-package/9e3730d5c0e3ec955761c05b50e3a6047ee4030b";
    };
    zone-sequencer-rs = {
      url = "github:xAlisher/zone-sequencer-rs/5d5c18413e62bf7fe42440ba935019aea68b21ee";
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

          rustLib = pkgsRust.rustPlatform.buildRustPackage {
            pname = "zone-sequencer-rs";
            version = "0.1.0";
            src = zone-sequencer-rs;

            cargoLock = {
              lockFile = "${zone-sequencer-rs}/Cargo.lock";
              outputHashes = {
                "jf-crhf-0.1.1" = "sha256-TUm91XROmUfqwFqkDmQEKyT9cOo1ZgAbuTDyEfe6ltg=";
                "jf-poseidon2-0.1.0" = "sha256-QeCjgZXO7lFzF2Gzm2f8XI08djm5jyKI6D8U0jNTPB8=";
                "logos-blockchain-blend-crypto-0.1.2" = "sha256-sfNJXdGgJ0nNl5jq8XLYiKFwTa+gJCwG8W9lVKtmjvQ=";
                "overwatch-0.1.0" = "sha256-L7R1GdhRNNsymYe3RVyYLAmd6x1YY08TBJp4hG4/YwE=";
              };
            };

            LOGOS_BLOCKCHAIN_CIRCUITS = circuits;

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

            built_variants = {'linux-x86_64-dev', 'linux-amd64-dev'}

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
                        manifest["main"] = {k.replace("-dev", ""): v for k, v in manifest["main"].items() if k in built_variants}
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

            lgx add zone-sequencer.lgx --variant linux-x86_64-dev --files ./variant-files --main liblogos_zone_sequencer_module.so -y
            lgx add zone-sequencer.lgx --variant linux-amd64-dev --files ./variant-files --main liblogos_zone_sequencer_module.so -y

            lgx verify zone-sequencer.lgx

            ${patchManifest "zone-sequencer" "${self}/manifest.json"}

            mkdir -p $out
            cp zone-sequencer.lgx $out/zone-sequencer.lgx
          '';

        in
        {
          inherit plugin rustLib lgx;
          default = lgx;
        }
      );
    };
}
