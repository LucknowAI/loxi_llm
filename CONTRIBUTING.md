# Contributing to Loki LLM

Thank you for your interest in contributing. Loki LLM is an on-device LLM chat
app for Android — all inference, documents, and chat history stay local. We
welcome bug reports, documentation improvements, tests, and feature work.

## Before you start

1. Search [existing issues](https://github.com/LucknowAI/loxi_llm/issues) to
   avoid duplicate work.
2. For **large changes** (new backends, major UI flows, new agent tools),
   open an issue first so maintainers can agree on direction before you invest
   significant time.
3. For **small fixes** (typos, obvious bugs, test gaps), a PR without a prior
   issue is fine.

## Development setup

See [README.md](README.md#getting-started). In short:

```bash
fvm install && fvm use
fvm flutter pub get
git submodule update --init --recursive
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run
```

Always use **`fvm flutter`** and **`fvm dart`** so you match the pinned Flutter
3.41.0 SDK.

## Branching model

| Branch | Purpose |
|--------|---------|
| `main` | Stable releases only — matches the latest semver tag |
| `develop` | Integration branch — **target for all contributor PRs** |
| `feature/*`, `fix/*`, `docs/*` | Short-lived work branches |

```text
feature/my-change  ──PR──►  develop  ──release PR──►  main  ──tag──►  vX.Y.Z
```

Do **not** open feature PRs against `main`. Maintainers cut releases by merging
`develop` into `main` and tagging (see [Releases](#releases-maintainers)).

### Branch naming

- `feature/add-foo` — new functionality
- `fix/bar-crash` — bug fixes
- `docs/update-readme` — documentation only

## Making changes

1. Fork the repo and create a branch from **`develop`**.
2. Make focused commits with clear messages (imperative mood):

   ```text
   Add speech normalizer for Markdown in TTS
   Fix model-switch unload when backend is busy
   ```

   Reference issues when applicable: `Fixes #42`.

3. Run checks locally before pushing:

   ```bash
   fvm dart run build_runner build --delete-conflicting-outputs   # if models/providers changed
   fvm flutter analyze
   fvm flutter test
   ```

   CI runs the same analyze + test pipeline on every PR — see
   [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

4. Open a pull request against **`develop`**.

## Pull request checklist

- [ ] CI passes (`Analyze & test`)
- [ ] `fvm flutter analyze` is clean
- [ ] Tests added or updated when behavior changes
- [ ] `build_runner` run if you changed `@freezed`, `@riverpod`, or ObjectBox
      entities
- [ ] User-facing changes have an entry under `[unreleased]` in
      [CHANGELOG.md](CHANGELOG.md)
- [ ] No secrets, credentials, or large binary blobs committed
- [ ] Manual device testing for UI or native (`llama_engine`) changes when
      possible

## Code conventions

- **Layout:** feature-first under `lib/features/`; shared code in `lib/core/`.
- **State:** Riverpod with code generation (`riverpod_annotation`).
- **Models:** `freezed` + `json_serializable`; run `build_runner` after edits.
- **Persistence:** ObjectBox entities in `data/*_entity.dart`.
- **Architecture:** see [docs/PROJECT.md](docs/PROJECT.md) and
  [CLAUDE.md](CLAUDE.md) (local dev reference).

Match the style of surrounding code. Prefer small, reviewable PRs over large
multi-feature dumps.

## Testing

The test suite is pure Dart and runs without a device or emulator:

```bash
fvm flutter test
fvm flutter test test/<file>_test.dart
```

Native plugins (ObjectBox, llama, ONNX) are mocked or use in-memory configs
where needed. See [docs/PROJECT.md](docs/PROJECT.md) for the coverage map.

## Changelog

User-visible changes belong in [CHANGELOG.md](CHANGELOG.md) under the
`[unreleased]` section, following [Keep a Changelog](https://keepachangelog.com/).

## Releases (maintainers)

1. Ensure `develop` is green in CI.
2. Finalize `CHANGELOG.md` (move `[unreleased]` → `[X.Y.Z] — YYYY-MM-DD`).
3. Bump `version` in `pubspec.yaml`.
4. Open a **Release vX.Y.Z** PR: `develop` → `main` (squash merge).
5. Tag `vX.Y.Z` on `main` and publish a [GitHub Release](https://github.com/LucknowAI/loxi_llm/releases).
6. Merge `main` back into `develop`.

## Community

- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security policy](SECURITY.md)
- [Privacy policy](PRIVACY.md)

Be respectful and constructive. Questions and partial contributions are welcome.
