---
id: F-NNN
name: Feature Name
type: [category]
platform: [platform]
status: active / planned / deprecated / removed
last_verified: YYYY-MM-DD
depends_on: []
---

## Business Purpose
Why this feature exists. What the user or product loses if it is removed.

---

## Trigger
When this feature runs. What condition activates it.

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

---

## Tests
`path/to/test_file` — what the tests cover.

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
