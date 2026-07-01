{
  description = "zone_seq_ui_probe — proves modules().zone_sequencer.* from a ui_qml LogosUiPluginContext backend (the untested shop pattern, headlessly verified)";
  inputs = {
    logos-module-builder.url = "github:logos-co/logos-module-builder/0.2.0";
    nix-bundle-lgx.url = "github:logos-co/nix-bundle-lgx";
    # Dependency we consume — attr name MUST match metadata.dependencies.
    zone_sequencer.url = "git+file:///home/alisher/basecamp/modules/logos-zone-sequencer-module?ref=feat/modernize-modules-context";
  };
  outputs = inputs@{ logos-module-builder, ... }:
    logos-module-builder.lib.mkLogosQmlModule {
      src = ./.;
      configFile = ./metadata.json;
      flakeInputs = inputs;
    };
}
