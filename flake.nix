{
  description = "Zone Sequencer Module (universal) — logos-blockchain v0.2";

  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder/0.2.0";
    nix-bundle-lgx.url = "github:logos-co/nix-bundle-lgx";
    # Our Rust FFI cdylib, built by its own flake (fork deps + rapidsnark/circuits).
    zone-sequencer-rs.url = "github:xAlisher/zone-sequencer-rs?ref=feat/v0.2-port";
  };

  outputs = inputs@{ logos-module-builder, ... }:
    logos-module-builder.lib.mkLogosModule {
      src = ./.;
      configFile = ./metadata.json;
      flakeInputs = inputs;
      externalLibInputs = {
        # Bundles libzone_sequencer_rs.so + makes its header/lib available to the
        # build and to logos-cpp-generator's dlopen. metadata.json#nix.external_libraries
        # references the same name "zone_sequencer_rs".
        zone_sequencer_rs = {
          input = inputs.zone-sequencer-rs;
          packages.default = "zone_sequencer_rs";
        };
      };
    };
}
