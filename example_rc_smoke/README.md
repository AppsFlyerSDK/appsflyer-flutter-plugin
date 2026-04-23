# example_rc_smoke/

Smoke-test Flutter app that pins the published RC from pub.dev. Exists only to validate the RC artifact after `rc-release.yml` completes publishing.

## What's committed here

- `pubspec.yaml` — template. The `appsflyer_sdk: RC_VERSION_PLACEHOLDER` line is rewritten by `rc-smoke.yml` to pin the exact RC version (e.g. `appsflyer_sdk: =6.18.0-rc1`).
- `README.md` — this file.

That's it. The rest of the app (Android project, iOS project, lib/, assets, tests) is **not** committed here. `rc-smoke.yml` synthesizes it at CI time by rsyncing `example/` into this directory (excluding `pubspec.yaml`), so both app shells stay in lockstep without duplicating source.

## Exclusion from the published package

`example_rc_smoke/` is in `.pubignore`; it is never part of the plugin artifact uploaded to pub.dev.

## Why not commit a full copy of example/?

Two directories of identical app source drift quickly and bloat PR diffs. Everything that differs between `example/` and `example_rc_smoke/` lives in `pubspec.yaml`: the dependency shape. The rest is byte-for-byte the same app, built against a different `appsflyer_sdk` source.

## Running this locally

You normally won't. For a local dry-run of the full RC pipeline use:

```sh
./scripts/simulate-rc-pipeline.sh --platform ios
```

It rewrites the smoke plan at runtime to point at `example/` with a `path: ..` dependency, so you exercise the runner + plan shape without needing to publish anything to pub.dev.

## Related files

- `../scripts/af-smoke-runner.sh` — the runner `rc-smoke.yml` calls.
- `../.af-smoke/rc-test-plan.json` — the test plan; `build_cmd` targets `example_rc_smoke/`.
- `../.github/workflows/rc-smoke.yml` — the workflow that templates this `pubspec.yaml` and runs smoke.
- `../docs/RELEASE_USER_MANUAL.md` — operator manual.
