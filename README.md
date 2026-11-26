# Collapser Seed Card — Godot editor add-on

An editor dock that runs the Collapser public demo from inside Godot and
copies the run's **seed card**: the seed that reproduces the run, the world
it made, and the result fingerprint anyone can re-check.

## What it is

The Collapser is a deterministic engine offered as a hosted service: a
written record goes in, a derived result comes out, and the result carries
a fingerprint (the SHA-256 hash of its derivation manifest) that a public
verifier can re-derive and compare. The public demo serves two published
example records — a hero's chronicle and a match record — so anyone can
watch the same record produce the same answer twice, then try to break
the seal.

This add-on is a **client of that public demo** (collapser-pilot.fly.dev).
Pick an example in the dock, press *Run the demo*, and the dock shows the
fingerprints the service returned and builds the seed card — the same
card the web playground issues. Copy it, hand it to someone: the link on
it points the playground at the same seed, and the fingerprint either
comes back identical or it doesn't.

## What it is not

- It derives nothing locally. Every number in the dock comes from the
  demo service's responses.
- It takes no API key and sends nothing but the example choice
  (`chronicle` or `replay-verify`). The demo's inputs are fixed by the
  service; a seed card is something a run gives you, never something
  the demo takes in.
- It is not the pilot integration. Pilots run their own records under
  their own key in their own integration.

## Install

Through the Asset Library (once listed): search "Collapser Seed Card",
download, then enable it under Project → Project Settings → Plugins.

Manually: copy the `addons/collapser_seed_card/` folder into your
project's `addons/` folder and enable the plugin the same way.

Requires Godot 4.2 or later and an internet connection (the demo is a
hosted service).

## Usage

1. Enable the plugin (Project → Project Settings → Plugins → Collapser
   Seed Card). The **Collapser Seed Card** dock appears in the editor.
2. Pick one of the two published examples in the dock's picker — the
   hero's chronicle or the match record.
3. Press **Run the demo**. The dock shows the record fingerprint and
   the result fingerprint the service returned, and builds the run's
   seed card.
4. Press **Copy the seed card** and paste it anywhere. The card carries
   the seed, the world line, both fingerprints, and a playground link
   (`https://collapser-pilot.fly.dev/?seed=…&h=…`) that re-runs the
   same seed so the holder can compare fingerprints.

## The pilot

The demo serves two fixed, published examples. A pilot is the next
step: your own records, run under your own key in your own integration.
Pilots are a fixed $250. The pilot path starts at the Seed Card
playground — https://collapser-pilot.fly.dev — where the demo, the
verifier, and the pilot terms live.

## Claim discipline

The Collapser is a classical, deterministic engine. A record goes in,
a result comes out, and the result's fingerprint is the SHA-256 hash of
its derivation manifest; the public verifier re-derives it from the
record with ordinary classical computation. That is the whole claim:
same record, same result, checkable by anyone.

What is not claimed: the wider Collapser project also runs experiments
on quantum processors (QPUs). Those runs are provenance and boundary
measurements only — they play no part in this add-on, in the demo
service, or in any derivation or fingerprint, and no
quantum-performance claim is made or implied anywhere in this
repository.

## License

MIT — see `LICENSE` in this folder or at the repository root.
