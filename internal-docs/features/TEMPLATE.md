---
id: F-NNN
name: Feature Name
type: [category]
platform: [platform]
status: active / planned / deprecated / removed
last_verified: YYYY-MM-DD
depends_on: []
---

Metadata rules:

- `active` means the current public/plugin/native implementation supports the feature. Use `removed` for a tombstone that documents a deleted API and its replacement. Use `planned` or `deprecated` only when implementation/release evidence supports that state.
- `platform` is exactly `android`, `ios`, or `both`.
- `depends_on` lists only feature IDs required by the implemented capability or its complete documented workflow. Do not add thematic similarity, optional configuration, implementation-helper reuse, or an inverse “is used by” relationship. In dependency diagrams, `A --> B` means A depends on B.
- Update `last_verified` only after checking the current Dart API, platform plugin, relevant native RPC/SDK layers, tests, and dependency configuration. A prose-only edit is not implementation verification.

## Business Purpose
Why this feature exists. What the user or product loses if it is removed.

---

## Trigger
When this feature runs. State verified ordering such as before `init()`, after `init()`, before `start()`, once per foreground, or once per process. If ordering differs by platform, list each platform separately.

---

## Call Chain
```
EntryPoint::method()
  → NextLayer::method()    [file]
    → FinalLogic::method() [file]
```

---

## Files
| File | Role |
|------|------|

---

## Input / Output
| | |
|--|--|
| **Input** | What comes in |
| **Output** | What goes out |

For a `Future`, say whether completion means synchronous setter invocation, native callback completion, or event delivery. Name any timeout and whether native work can continue afterward. Keep validation errors, `AppsFlyerException`, event failure payloads, and platform no-op defaults distinct.

---

## Tests
`path/to/test_file` — what the tests cover.

State missing native, lifecycle, packaging, or end-to-end coverage explicitly. A Dart RPC-map test does not prove native SDK behavior.

---

## Known Limitations
- Limitation — why it exists, what the risk is

---

## Dependencies
```mermaid
flowchart LR
    FXXX["F-XXX · This Feature"]:::typeA -->|"relationship"| FYYY["F-YYY · Other Feature"]:::typeB
    [classDef blocks — one per approved category]
```

If `depends_on` is empty, use a standalone node or concise prose. Keep optional relationships out of dependency metadata and label them explicitly if they are useful to show elsewhere.
