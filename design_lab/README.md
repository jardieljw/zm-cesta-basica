# ZM — isolated Flutter validation laboratory

Status: **CANDIDATE, NOT VISUALLY CERTIFIED**.

This laboratory is derived from the user's approved FE-052 HTML reference and its audited measurements (430 × 940 CSS px). It is not derived from the current app's appearance. The measured FE-052 mode capsule was 60 px tall with circular indicators; the date field was 56 px with a trailing icon. Reference source SHA-256: `774f5bbce0ccbc8048818a2daa24531804619551432113795a00a6dbe4eaf53f`.

The earlier local zip `ZM_DESIGN_SYSTEM_AUDITADO_2026-10-18.zip` contains a larger **unapproved** Flutter candidate and documentation. **This branch initially stages an isolated pilot only**; it does not claim to transfer or certify the full 98-file package.

Commands from repository root:
```sh
cd design_lab
flutter pub get
flutter analyze --fatal-infos
flutter test --reporter expanded
```

Required before any integration into `client/`: independently reproduce full FE-052 form and review state, compare equivalent Flutter/HTML viewports with approved reference, test mobile/desktop/light/dark/accessibility, review and approve golden baselines, record screenshots and approval, and make CI enforce these artifacts. Passing widget tests alone is insufficient.

DO NOT merge this laboratory as production design.
