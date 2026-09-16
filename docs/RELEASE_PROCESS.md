# Release Process

The full checklist for cutting a release, expanding on `CONTRIBUTING.md`'s
"Releases (maintainers)" summary with the gotchas found while shipping
v1.2.0. Sequence:

```text
develop (readiness review) → CHANGELOG + version bump chore → Release PR
(develop → main, squash) → tag + GitHub Release (+ signed APK)
→ merge main back into develop → close milestone → housekeeping
```

## 1. Pre-release readiness review

- [ ] CI green on `develop`'s tip: `gh run list --branch develop --limit 5`
- [ ] `fvm flutter analyze` clean
- [ ] `fvm flutter test` — all passing
- [ ] No open PRs pending: `gh pr list --state open`
- [ ] Submodule(s) cleanly pinned, not dirty/detached: `git submodule status`
- [ ] Milestone issue audit — see the gotcha below; the milestone should show
      0 open issues before cutting the release
      (`gh api repos/<owner>/<repo>/milestones/<num> --jq '{open_issues,closed_issues}'`)
- [ ] Docs (`README.md`, `docs/PROJECT.md`) don't reference the outgoing
      version as still-unreleased/upcoming

## 2. Gotcha: issues don't auto-close on merge into `develop`

GitHub's `Fixes #N` / `Closes #N` auto-close only fires when a PR merges into
the **repository's default branch**. This repo's default branch is `main`,
but `CONTRIBUTING.md` requires all contributor PRs to target `develop`. So
**every** PR merged into `develop` that references an issue leaves that issue
open, even though the fix has landed — this went unnoticed across two
releases until manually audited (5 issues: #18, #65, #67, #68, #73).

Audit before every release:

```bash
# List merged PRs with linked issues + their base branch
gh pr list --repo <owner>/<repo> --state merged --limit 100 \
  --json number,title,baseRefName,closingIssuesReferences \
  | jq -c '.[] | select(.closingIssuesReferences | length > 0) |
      {number, base: .baseRefName, issues: [.closingIssuesReferences[].number]}'

# For each referenced issue where base != main, check + close if still open
gh issue view <N> --json state
gh issue close <N> --comment \
  "Fixed by #<PR> (merged into \`develop\`). Not auto-closed since the PR's base was \`develop\`, not the repo's default branch (\`main\`)."
```

## 3. CHANGELOG + version bump — its own tracked chore

Per `CLAUDE.md`, this is its own issue + branch + PR into `develop`, same as
any other change — not a direct commit to `develop`.

1. Open an issue: "[Chore] Prepare vX.Y.Z release: finalize CHANGELOG and
   bump version"
2. Branch off `develop`: `git checkout -b docs/<n>-prepare-vX.Y.Z-release develop`
3. In `CHANGELOG.md`: rename the `## [Unreleased]` header to
   `## [X.Y.Z] — YYYY-MM-DD`, and add a fresh empty `## [Unreleased]` above it.
   - Credit external contributors inline: append
     `, thanks [@handle](https://github.com/handle)` to the bullet(s) their PR
     fixed. Cross-reference PR authors with `gh pr view <n> --json author`.
     Add a `### Contributors` line at the end of the version's section
     thanking everyone by handle (this also covers non-user-facing PRs that
     have no bullet of their own).
4. Bump `version:` in `pubspec.yaml` — `+1` build number convention
   (e.g. `1.1.0+2` → `1.2.0+3`).
5. `fvm flutter analyze` clean, commit, push, open PR into `develop`, merge.
   Close the chore issue manually afterward (same auto-close gap as above).

## 4. Release PR (`develop` → `main`)

```bash
gh pr create --base main --head develop --title "Release vX.Y.Z" \
  --body "<CHANGELOG summary + the readiness checks from step 1, restated so a reviewer doesn't have to re-derive them>"
```

## 5. Squash-merge — preserve contributor attribution

`CONTRIBUTING.md` specifies squash merge for the release PR. **GitHub's
default squash commit message auto-lists every squashed commit — that list
is what carries multi-author attribution through. Don't blindly replace it
with a fully custom message**, or every external contributor whose work is
in this release becomes invisible on the repo's Contributors graph
(`/graphs/contributors`). That graph is computed purely from commit
authorship reachable from the default branch — CHANGELOG or Release-notes
credit does **not** fix it, since it doesn't touch any commit object.

Before merging, check who actually contributed since the last release:

```bash
git log --format="%an <%ae>" origin/main..origin/develop | sort -u
```

For every name that isn't you, add an explicit trailer to the squash commit
message:

```text
Co-authored-by: Full Name <exact-email-from-git-log>
```

Use the **exact** email from `git log`, not a guess — GitHub only links it to
a profile if it matches a verified email on that account. If merging with
`gh pr merge --squash --subject "..." --body "..."`, include these trailers
in `--body`. If merging via the GitHub UI, edit the pre-filled message to
keep the commit list (or add the trailers manually) rather than replacing it
outright.

If this step is missed and the release is already tagged/published, fixing
it means amending the squash commit, force-pushing `main`, and re-tagging —
see the "History correction" note at the bottom. Treat that as a last
resort, not routine.

## 6. Tag, GitHub Release, and the signed APK

```bash
gh release create vX.Y.Z --repo <owner>/<repo> --target main \
  --title "vX.Y.Z — <headline>" \
  --notes "<CHANGELOG section content, plus a ### Contributors line crediting external contributors by handle>"
```

This creates the tag directly via the API — no local `git push` needed for
this step.

**Signed APK** — the release should carry a signed release APK so people can
try it without building from source:

1. Build/sign it locally, with your own signing config (the keystore never
   needs to touch an AI coding session): `fvm flutter build apk --release`
2. Attach the resulting file (typically
   `build/app/outputs/flutter-apk/app-release.apk`):
   ```bash
   gh release upload vX.Y.Z /path/to/app-release.apk --repo <owner>/<repo>
   ```

## 7. Merge `main` back into `develop`

```bash
git checkout develop && git pull
git merge main --no-edit
git push origin develop
```

This keeps `develop` a clean descendant of `main` going forward. Skipping
this step is what causes old, already-released commits to keep reappearing
in every future release PR's commit list (confirm with
`git merge-base main develop` — it should equal `main`'s own tip).

## 8. Close the milestone

```bash
gh api repos/<owner>/<repo>/milestones/<num> -X PATCH -f state=closed
```

## 9. Post-release housekeeping

- Delete local/remote branches for merged PRs (remote is usually
  auto-deleted if `delete_branch_on_merge` is on).
- `git branch -d <branch>` — if it refuses, that means the merge was a
  squash (breaks `-d`'s ancestor check); confirm the PR is actually merged
  via `gh pr view <n> --json state,mergedAt`, then `git branch -D`.

## Operational notes for Claude Code

- Pushing to `origin` (any branch), force-pushing, and tag creation via raw
  `git push` all require the environment's SSH agent/key. If blocked
  (`Permission denied (publickey)`), those specific steps need a human to
  run them — `gh` (HTTPS-based: PRs, issues, releases, milestones, and even
  tag creation via `gh release create`) is unaffected and can be run
  directly.
- Modifying repo/branch security settings (e.g. toggling branch protection's
  `allow_force_pushes`) is blocked by the coding agent's own safety
  classifier by default — this needs a human to do it, or to explicitly
  grant permission first.
- `main`'s branch protection blocks force-pushes and deletions by default —
  only touch that for a genuine, human-approved history correction (see
  below), never routinely.

### History correction (last resort)

If a release is already tagged/published and needs a commit-message-only
fix (e.g. missing `Co-authored-by:` trailers), and it's still fresh enough
that no one else has likely pulled `main`:

```bash
git checkout main
git commit --amend -m "<original subject>

<original body>

Co-authored-by: Name <email>"
# Verify only the message changed:
git log -1 --format="%H %T %P"   # tree + parent must match the pre-amend commit

git push --force-with-lease origin main   # needs allow_force_pushes temporarily enabled

# Re-tag + recreate the Release at the new commit:
gh release delete vX.Y.Z --cleanup-tag -y
gh release create vX.Y.Z --target main --title "..." --notes "..."
```

Always restore branch protection immediately after, and prefer never
needing this — get step 5 right the first time.
