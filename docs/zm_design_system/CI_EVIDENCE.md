# CI laboratory scope — 2026-10-18

Branch: audit/zm-design-system-flutter-ci-20261018 (based on master).

Purpose: obtain a real Flutter SDK in GitHub Actions without touching production branch.

The CI has **two independent jobs**:
1. `current-client`: run `flutter pub get`, `flutter analyze`, and `flutter test` on the already-existing application (baseline diagnostic only; no design claims).
2. `design-laboratory`: compile/analyze and widget-test FE-052 payment component candidate in `design_lab/`.

A passing run is NOT visual approval. No Flutter golden baseline has been human-approved. The code currently staged is an isolated payment-component pilot, not the full audited zip. If failures occur, inspect the job logs and change only the audit branch. No automatic merge to master.
