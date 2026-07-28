---
name: update-formula
description: |-
  Check a Homebrew formula's upstream GitHub project for a newer release and update the formula's
  url + sha256. Uses scripts/check_and_update.sh (gh Releases API + shasum) for all detection,
  version comparison, and file rewriting — the model only handles resource-dependency review and
  local testing. Use proactively when asked to bump, update, or check for new releases of a formula
  in this tap.

  Examples:
  - user: "Is there a new release of occe?" → run check_and_update.sh (report-only) on its formula
  - user: "Bump opencode-copilot-credit-estimator to the latest release" → run with --apply, then review deps + test
  - user: "Update all the formulae" → loop check_and_update.sh over Formula/*.rb
  - user: "Check every formula for upstream updates" → run report-only for each, summarise
---
# Update Formula

Check upstream GitHub releases and update a Homebrew formula's `url` + `sha256`.

## Golden rule: run the script, don't reason

`scripts/check_and_update.sh` does version detection, semver comparison, tarball
download, sha256 computation, and in-place rewriting. Do NOT reimplement any of
that by hand or by eyeballing tags — invoke the script.

## Workflow

1. **Check (report-only)** — for each target formula:
   ```sh
   scripts/check_and_update.sh Formula/<name>.rb
   ```
   Exit codes: `0` up to date · `3` newer release available · `1` error.
   Aliases (`Aliases/occe`) are symlinks; always pass the real `Formula/*.rb`.

2. **Apply** — when a bump is wanted and exit code was `3`:
   ```sh
   scripts/check_and_update.sh Formula/<name>.rb --apply
   ```
   This rewrites ONLY the top-level `url`/`sha256`, never resource blocks.

3. **Review resources (model's job)** — the script deliberately does NOT touch
   Python `resource` blocks. After an apply, check whether upstream dependencies
   changed between the old and new tag:
   ```sh
   gh api repos/<owner>/<repo>/compare/<oldtag>...<newtag> --jq '.files[].filename'
   ```
   If `pyproject.toml`, `requirements*.txt`, `poetry.lock`, or `uv.lock` changed,
   the resource blocks likely need regenerating (see AGENTS.md rules 3–5 for how:
   wheel URLs from `https://pypi.org/pypi/<name>/<version>/json`, sha256 matched
   per package). Flag this to the user; don't silently ship stale deps.

4. **Validate locally** (per AGENTS.md):
   ```sh
   brew style Formula/<name>.rb
   brew audit --formula --tap=springernature/opensource <name>
   ```
   Deeper install/test requires committing then re-tapping (brew taps the
   committed state, not the working tree).

5. **Commit** — only if the user asked. Do not `git push`; hand the exact push
   command back to the user (AGENTS.md).

## Requirements

- `gh` authenticated (`gh auth status`). Uses `repos/<owner>/<repo>/releases/latest`,
  so upstream must publish GitHub **Releases**, not just tags. If the script errors
  with "no published 'latest' release", the project only has tags — fall back to
  picking the highest semver tag via `gh api repos/<owner>/<repo>/tags` manually.
- `curl` and `shasum` on PATH.

## Assumptions the script enforces

- Formula `url` must be a `.../archive/refs/tags/<tag>.tar.gz` GitHub tarball.
- Won't downgrade: if the current tag is already >= latest release, it reports
  up-to-date and exits `0`.
