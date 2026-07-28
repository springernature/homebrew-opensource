# scripts/

Utility scripts for maintaining this Homebrew tap. These are used by the
`update-formula` skill but are equally usable by hand.

## check_and_update.sh

Check a formula's upstream GitHub project for a newer release and, optionally,
update the formula's top-level `url` + `sha256` in place.

All version detection, semver comparison, tarball download, checksum
computation, and file rewriting happen in the script — no manual editing of the
`url`/`sha256` lines is needed.

### Usage

```sh
scripts/check_and_update.sh <formula.rb> [--apply]
```

- `<formula.rb>` — path to a `Formula/*.rb` file. Always pass the real formula,
  not an `Aliases/*` symlink.
- `--apply` — rewrite `url` + `sha256` in the formula. Without it, the script
  only reports what it would change.

### Examples

Check whether a newer release exists (report only, no changes written):

```sh
scripts/check_and_update.sh Formula/opencode-copilot-credit-estimator.rb
```

Apply the bump to the latest release:

```sh
scripts/check_and_update.sh Formula/opencode-copilot-credit-estimator.rb --apply
```

Check every formula in the tap:

```sh
for f in Formula/*.rb; do scripts/check_and_update.sh "$f"; done
```

### Exit codes

| Code | Meaning |
|------|---------|
| `0`  | Up to date, or (with `--apply`) update written successfully. |
| `3`  | A newer release is available (report-only mode; no changes written). |
| `1`  | Error — bad arguments, network/parse failure, or unexpected formula shape. |

### What it does and does not change

- Updates **only** the top-level `url` and `sha256`. Resource blocks (e.g.
  Python dependency `resource` stanzas) are deliberately left untouched.
- After applying a bump, verify whether upstream dependencies changed between the
  old and new tag and regenerate resource blocks if so (see `AGENTS.md`):

  ```sh
  gh api repos/<owner>/<repo>/compare/<oldtag>...<newtag> --jq '.files[].filename'
  ```

- Won't downgrade: if the current tag is already `>=` the latest release, it
  reports up-to-date and exits `0`.

### Requirements

- [`gh`](https://cli.github.com) authenticated (`gh auth status`). It queries
  `repos/<owner>/<repo>/releases/latest`, so upstream must publish GitHub
  **Releases**, not just tags. If it errors with *"no published 'latest'
  release"*, the project only has tags — fall back to the highest semver tag via
  `gh api repos/<owner>/<repo>/tags`.
- `curl` and `shasum` on `PATH`.

### Assumptions

- The formula's `url` must be a GitHub archive tarball of the form
  `https://github.com/<owner>/<repo>/archive/refs/tags/<tag>.tar.gz`.

## codeowners.sh

Resolve the upstream GitHub repo's code owners for a formula and print their
GitHub usernames, one per line.

Given a `Formula/*.rb`, it derives the upstream `<owner>/<repo>` from the `url`,
fetches that repo's `CODEOWNERS` (checking `.github/`, root, then `docs/`),
extracts every `@mention`, and prints individual usernames. `@org/team` entries
can't be PR assignees, so they're dropped and reported on stderr.

### Usage

```sh
scripts/codeowners.sh Formula/<name>.rb
```

Prints nothing (and exits `0`) if the upstream repo has no `CODEOWNERS` or no
individual owners. Used by the daily update workflow to assign the generated PR
to the changed formulae's upstream owners.

Requires `gh` authenticated (`GH_TOKEN` or `gh auth`).
