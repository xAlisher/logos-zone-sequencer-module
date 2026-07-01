# Manual test runbook — zone_sequencer (v0.2, modernized)

Modernized module: `LogosModuleContext` + `modules()`, universal, no hand-written getClient.
What's already proven automatically (see `doctests/consume-zone-sequencer.test.yaml`, 14/14
green under logoscore): build → install → load → dispatch → **Rust FFI** → **typed
`modules().zone_sequencer.*` cross-module call**. This runbook covers the parts to confirm
**by hand**: the stateful **publish → live inscription** path, GUI Basecamp, and the
Keeper→Beacon→ia chain.

## 0. Prerequisites
- A **v0.2 testnet node** reachable. On Sneg it binds `http://127.0.0.1:8080` (localhost
  only). From another machine, tunnel: `ssh -fN -L 18080:127.0.0.1:8080 snezhok` → use
  `http://127.0.0.1:18080`.
- A **32-byte hex signing key** (64 chars). Inscriptions are **node-paid** — any valid key
  works, no faucet. ⚠️ If you drive methods via the **logoscore CLI**, the key MUST contain
  a–f letters — an all-decimal arg is coerced to a number and the method is silently skipped
  (a CLI quirk; QML/IPC pass strings fine).
- Nix (flakes), `lgpm`, and (for GUI) a Basecamp AppImage.

## 1. Build the .lgx
```sh
cd ~/basecamp/modules/logos-zone-sequencer-module
nix build .#lgx -o result-lgx        # .#lgx has the linux-amd64-dev variant lgpm installs
ls -L result-lgx/*.lgx          # → logos-zone_sequencer-module-lib.lgx
```

## 2. Smoke test (headless, logoscore) — fastest confidence
```sh
nix build 'github:logos-co/logos-logoscore-cli' --out-link ./logos
nix build 'github:logos-co/logos-package-manager#cli' --out-link ./pm
mkdir -p modules
./pm/bin/lgpm --modules-dir ./modules --allow-unsigned install --file result-lgx/*.lgx
./logos/bin/logoscore -D -m ./modules & sleep 5
./logos/bin/logoscore load-module zone_sequencer
#   expect: {"...","module":"zone_sequencer","status":"ok","version":"0.2.0"}

# derive a channel id (FFI path). Use a LETTER key:
./logos/bin/logoscore call zone_sequencer derive_channel_id aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
#   expect: {"result":{"success":true,"value":"e734ea6c2b6257de72355e472aa05a4c487e6b463c029ed306df2f01b5636b58"},...}
./logos/bin/logoscore stop
```
✅ `success:true` + a 64-hex value → module + FFI + dispatch all work.

## 3. Publish path → live inscription (the key manual check)
The stateful path: configure, then publish. Do this where the node is reachable (`NODE`).
Prefer QML/IPC or a consumer over the CLI (CLI decimal-arg gotcha; and each CLI `call`
should hit the same warm daemon instance — start with `-D`).

```sh
KEY=<64-hex-with-letters>
NODE=http://127.0.0.1:8080        # or :18080 via the tunnel
CH=$(./logos/bin/logoscore call zone_sequencer derive_channel_id "$KEY" | jq -r .result.value)

./logos/bin/logoscore call zone_sequencer set_node_url "$NODE"
./logos/bin/logoscore call zone_sequencer set_signing_key "$KEY"
./logos/bin/logoscore call zone_sequencer set_channel_id "$CH"
#   set_* return {"success":true,"value":"ok"}; a background sequencer bootstraps
#   (watch for the sequencerReady event / retry publish for a few seconds)

./logos/bin/logoscore call zone_sequencer publish "hello-v0.2-$(date +%s)"
#   PASS: {"result":{"success":true,"value":"<64-hex inscription id>"},...}
#   "sequencer still initializing" → wait ~5-15s and retry (cold-start backfill)
```
Confirm the inscription landed: query the channel back (finalized reads lag — lib trails
tip by ~thousands of slots, so it may take a while to appear):
```sh
./logos/bin/logoscore call zone_sequencer query_channel "$CH" 20
```
Or one-shot (stateless), no prior config:
```sh
./logos/bin/logoscore call zone_sequencer publish_to "$CH" "$KEY" "" "one-shot-$(date +%s)"
```

## 4. Under GUI Basecamp (the demo runtime)
```sh
lgpm --modules-dir ~/.local/share/Logos/LogosBasecamp/modules --allow-unsigned \
     install --file result-lgx/*.lgx
# launch Basecamp; a consumer/QML calls modules().zone_sequencer.* (or callModule).
```
Confirm: the module loads (Basecamp log `Module loaded: zone_sequencer`), a consumer's
`publish` returns an inscription id, and no `getClient` bad_alloc (there is none — this is a
pure provider; 0 getClient refs).

## 5. Full demo chain (end-to-end)
1. **Keeper** queues a CID (`pinCid`) → **Beacon** publishes via zone_sequencer → inscription id.
2. **ia** (AI-Archiver) scans `/cryptarchia/blocks` and surfaces the inscription once finalized.
   - ia/beacon need the v0.2 `cryptarchia_info` nesting fix (branch
     `feat/v0.2-cryptarchia-info-nesting`) — merge/build those first.
   - ia/beacon default node URL is `127.0.0.1:8080`; ensure it points at the reachable node.

## Troubleshooting
| Symptom | Cause / fix |
|---|---|
| method returns `{"success":false,"error":null,"value":null}` and seems to do nothing | all-decimal CLI arg coerced to a number → use a key/arg with a–f letters (`logoscore-cli-coerces-numeric-args`) |
| `publish` → "sequencer still initializing" | cold-start backfill in progress; wait 5–15s and retry (`set_channel_id` at current LIB, not genesis) |
| `set_signing_key` seems ignored across calls | run logoscore with `-D` (daemon keeps the instance warm); or drive via one consumer call, not separate CLI calls |
| node calls fail / empty | node is `127.0.0.1:8080` (localhost only) — tunnel from another host |
| query returns empty right after publish | finalized reads lag (lib trails tip); the inscription appears once its slot finalizes |
| `.lgx` shows "⚠ Unsigned" | expected — install with `--allow-unsigned`; sign before publishing a release |

## Expected result
`derive_channel_id` (letter key) and `publish`/`publish_to` (valid key, reachable node)
both return `success:true`; `publish` returns a 64-hex inscription id; the id later appears
in `query_channel` once finalized. That confirms the modernized module works end-to-end.
