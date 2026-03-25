# AGENTS.md

## Purpose

This repository is a small client-side translation spreadsheet app built with ReScript, React 18, and Vite. It imports translation source/target files, lets users edit translations in a spreadsheet UI, and exports back to multiple formats.

Agents working here should optimize for small, targeted changes and preserve existing behavior around file parsing, spreadsheet editing, and export formats.

## Stack

- ReScript 11 with in-source compilation configured in `rescript.json`
- React 18 via `@rescript/react`
- Vite 5 for dev/build
- `react-datasheet` vendored under `vendor/react-datasheet`
- PWA setup in [`vite.config.js`](/Users/florian-cca/oss/quick-translate/vite.config.js)

## Repo Layout

- [`src/Index.res`](/Users/florian-cca/oss/quick-translate/src/Index.res): app entrypoint, mounts `App` and imports CSS
- [`src/App.res`](/Users/florian-cca/oss/quick-translate/src/App.res): top-level UI, file import/export flows, keyboard shortcuts, spreadsheet interactions
- [`src/AppState.res`](/Users/florian-cca/oss/quick-translate/src/AppState.res): reducer-backed app state, undo/redo, dialog state, localStorage persistence
- [`src/Source.res`](/Users/florian-cca/oss/quick-translate/src/Source.res): spreadsheet data model helpers
- [`src/Convert.res`](/Users/florian-cca/oss/quick-translate/src/Convert.res): import/export conversion logic for JSON, CSV, `.properties`, `.strings`, and Android XML
- [`src/components/`](/Users/florian-cca/oss/quick-translate/src/components): React UI components
- [`src/bindings/`](/Users/florian-cca/oss/quick-translate/src/bindings): JS interop bindings
- [`vendor/`](/Users/florian-cca/oss/quick-translate/vendor): vendored third-party code; avoid editing unless the task is explicitly about vendor behavior
- [`examples/`](/Users/florian-cca/oss/quick-translate/examples): sample import/export fixtures

## Development Workflow

- Install deps: `npm install`
- Start dev mode: `npm run dev`
- Production-style CI build: `npm run buildCI`
- Full local build flow: `npm run build`

Notes:

- `npm run dev` runs both the ReScript watcher and the Vite dev server on port `8083`.
- `npm run build` also starts `vite preview` at the end, so use `npm run buildCI` for non-interactive verification.
- There is no dedicated test suite or lint task in this repo today.

## ReScript Conventions

- Source files live in `src/`.
- Generated `*.bs.mjs` artifacts and `lib/` output are ignored by git; do not add them to commits.
- Prefer following existing ReScript style in the touched file rather than reformatting unrelated code.
- Keep changes type-safe and local. Most behavior is driven by `AppState`, `Source`, and `Convert`.

## Editing Guidance

- Prefer changing app code in `src/` first.
- Treat [`src/Convert.res`](/Users/florian-cca/oss/quick-translate/src/Convert.res) and [`src/Source.res`](/Users/florian-cca/oss/quick-translate/src/Source.res) as behavior-critical. Small logic changes there can affect every format import/export path.
- Avoid changing vendored files in [`vendor/react-datasheet`](/Users/florian-cca/oss/quick-translate/vendor/react-datasheet) unless necessary. If a vendor patch is required, document why in the change summary.
- Preserve CSV compatibility rules described in [`README.md`](/Users/florian-cca/oss/quick-translate/README.md), especially around delimiter detection and description/comment column handling.
- Be careful with localStorage behavior in [`src/AppState.res`](/Users/florian-cca/oss/quick-translate/src/AppState.res) and [`src/Storage.res`](/Users/florian-cca/oss/quick-translate/src/Storage.res); this app relies on persisted browser state even though README messaging still warns about refresh loss.

## Verification Expectations

For most code changes, run:

- `npm run buildCI`

If the change affects import/export logic, also validate manually with fixtures from [`examples/`](/Users/florian-cca/oss/quick-translate/examples) when practical.

If the change affects drag/drop, dialogs, shortcuts, or spreadsheet behavior, run the dev server and perform a quick browser smoke test.

## Current Repository State

- The worktree may already contain unrelated user changes. Check `git status --short` before editing.
- Do not revert or overwrite existing unowned changes.

At the time this file was written, the repo already had local modifications and untracked files under `src/` and `examples/`. Work around them unless the task explicitly targets those files.

## Preferred Agent Behavior

- Read the relevant ReScript modules before editing.
- Keep patches narrow and avoid broad renames or style-only churn.
- Summarize verification clearly, especially if only `buildCI` was run.
- Call out any behavior changes that affect supported translation formats or export filenames.
