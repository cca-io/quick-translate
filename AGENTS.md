# AGENTS.md

## Purpose

This repository is a small client-side translation spreadsheet app built with ReScript, React 19, and Vite. It imports translation source/target files, lets users edit translations in a spreadsheet UI, and exports back to multiple formats.

Agents working here should optimize for small, targeted changes and preserve existing behavior around file parsing, spreadsheet editing, and export formats.

## Stack

- ReScript 12 with in-source compilation configured in `rescript.json`
- React 19 via `@rescript/react`
- Vite 7 for dev/build
- PWA setup in [`vite.config.js`](/Users/florian-cca/oss/quick-translate/vite.config.js)

## Repo Layout

- [`src/Index.res`](/Users/florian-cca/oss/quick-translate/src/Index.res): app entrypoint, mounts `App` and imports CSS
- [`src/App.res`](/Users/florian-cca/oss/quick-translate/src/App.res): top-level UI, file import/export flows, keyboard shortcuts, spreadsheet interactions
- [`src/AppState.res`](/Users/florian-cca/oss/quick-translate/src/AppState.res): reducer-backed app state, undo/redo, dialog state, localStorage persistence
- [`src/Source.res`](/Users/florian-cca/oss/quick-translate/src/Source.res): spreadsheet data model helpers
- [`src/Convert.res`](/Users/florian-cca/oss/quick-translate/src/Convert.res): import/export conversion logic for JSON, CSV, `.properties`, `.strings`, and Android XML
- [`src/components/`](/Users/florian-cca/oss/quick-translate/src/components): React UI components
- [`src/bindings/`](/Users/florian-cca/oss/quick-translate/src/bindings): JS interop bindings
- [`vendor/`](/Users/florian-cca/oss/quick-translate/vendor): vendored browser/runtime support code; spreadsheet behavior now lives in `src/`
- [`tests/fixtures/`](/Users/florian-cca/oss/quick-translate/tests/fixtures): fixture files for conversion and round-trip tests

## Development Workflow

- Install deps: `npm install`
- Start dev mode: `npm run dev`
- Production-style CI build: `npm run buildCI`
- Full local build flow: `npm run build`
- Run fixture-based conversion tests: `npm test`
- Run Cucumber behavior tests: `npm run cucumber`
- Run ReScript dead-code analysis: `npm run re:dce`
- Format ReScript sources: `npm run re:format`

Notes:

- `npm run dev` runs both the ReScript watcher and the Vite dev server on port `8083`.
- `npm run build` also starts `vite preview` at the end, so use `npm run buildCI` for non-interactive verification.
- Cucumber behavior tests live under [`features/`](/Users/florian-cca/oss/quick-translate/features) and run against compiled `src/*.res.mjs` plus generated step-definition modules under `features/step_definitions/`.
- `npm run re:dce` currently runs `rescript && rescript-tools reanalyze`. The compile step matters: running reanalyze on stale generated output can report outdated findings.
- `npm run re:format` runs `rescript format` and is the canonical formatter for ReScript sources in this repo.

## ReScript Conventions

- Source files live in `src/`.
- Generated `*.res.mjs` artifacts under `src/`, `tests/`, `features/step_definitions/`, and `lib/` output are ignored by git; do not add them to commits.
- Prefer following existing ReScript style in the touched file rather than reformatting unrelated code.
- If formatting is needed, prefer `npm run re:format` over manual style edits, but avoid formatting-only churn outside the files you are already changing unless the task is explicitly a formatting pass.
- Keep changes type-safe and local. Most behavior is driven by `AppState`, `Source`, and `Convert`.
- Before adding a new binding for standard JS/runtime functionality, check whether ReScript already provides it directly. When unsure, inspect the published ReScript package sources, especially `lib/ocaml`, before rebinding globals. Prefer existing language or stdlib support such as plain `Promise.all` over custom bindings.
- Some modules now use `@@live` annotations, for example [`src/DataSheet.res`](/Users/florian-cca/oss/quick-translate/src/DataSheet.res) and [`src/icons/Icons_Logo.res`](/Users/florian-cca/oss/quick-translate/src/icons/Icons_Logo.res), to suppress dead-code false positives. Do not remove those casually without rerunning `npm run re:dce` and checking the impact.

## Editing Guidance

- Prefer changing app code in `src/` first.
- Treat [`src/Convert.res`](/Users/florian-cca/oss/quick-translate/src/Convert.res) and [`src/Source.res`](/Users/florian-cca/oss/quick-translate/src/Source.res) as behavior-critical. Small logic changes there can affect every format import/export path.
- Prefer changing the in-repo ReScript spreadsheet implementation in [`src/DataSheet.res`](/Users/florian-cca/oss/quick-translate/src/DataSheet.res) rather than reviving old vendor code.
- Preserve CSV compatibility rules described in [`README.md`](/Users/florian-cca/oss/quick-translate/README.md), especially around delimiter detection and description/comment column handling.
- Be careful with localStorage behavior in [`src/AppState.res`](/Users/florian-cca/oss/quick-translate/src/AppState.res) and [`src/Storage.res`](/Users/florian-cca/oss/quick-translate/src/Storage.res); this app relies on persisted browser state even though README messaging still warns about refresh loss.

## Verification Expectations

For most code changes, run:

- `npm run buildCI`

If the change affects import/export logic or conversion behavior, also run:

- `npm test`

If the change affects workflow behavior such as merge/replace interactions, keyboard shortcuts, or higher-level scenarios, also run:

- `npm run cucumber`

If the change is a cleanup/refactor or you suspect unused helpers, also consider:

- `npm run re:dce`

Current judgment on `re:dce` output:

- `@@live` annotations have reduced the previous false positives substantially.
- Current observed output is 2 warnings, both `Unused Argument` findings:
  [`src/FileUtils.res`](/Users/florian-cca/oss/quick-translate/src/FileUtils.res) for `download`'s optional `blankTarget`, and [`src/Hooks.res`](/Users/florian-cca/oss/quick-translate/src/Hooks.res) for `useMultiKeyPress`'s optional `omiTextfields`.
- So `npm run re:dce` is now fairly high-signal, but even these remaining warnings should still be reviewed before cleanup because optional arguments can reflect intended API shape, not just dead code.

If the change affects import/export logic, run [`npm test`](/Users/florian-cca/oss/quick-translate/package.json) and use fixtures from [`tests/fixtures/`](/Users/florian-cca/oss/quick-translate/tests/fixtures) for additional manual spot checks when practical.

If the change affects drag/drop, dialogs, shortcuts, or spreadsheet behavior, run the dev server and perform a quick browser smoke test.

## Current Repository State

- The worktree may already contain unrelated user changes. Check `git status --short` before editing.
- Do not revert or overwrite existing unowned changes.

At the time this file was written, the repo already had local modifications and untracked files under `src/`. Work around them unless the task explicitly targets those files.

## Preferred Agent Behavior

- Read the relevant ReScript modules before editing.
- Keep patches narrow and avoid broad renames or style-only churn.
- Summarize verification clearly, especially if only `buildCI` was run.
- Call out any behavior changes that affect supported translation formats or export filenames.
