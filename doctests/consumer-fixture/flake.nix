{
  description = "zone_seq_consumer_probe — proves modules().zone_sequencer.* (no getClient)";
  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder/0.2.0";
    nix-bundle-lgx.url = "github:logos-co/nix-bundle-lgx";
    # The dependency we consume — its name MUST match metadata.dependencies + flake input attr.
    zone_sequencer.url = "git+file:///home/alisher/basecamp/modules/logos-zone-sequencer-module?ref=feat/modernize-modules-context";
  };
  outputs = inputs@{ logos-module-builder, ... }:
    logos-module-builder.lib.mkLogosModule {
      src = ./.;
      configFile = ./metadata.json;
      flakeInputs = inputs;
    };
}
