# AGENTS.md

Guidance for agents (and humans) working in this repository.

## What this repo is

`springernature/homebrew-opensource` is a [Homebrew](https://brew.sh) tap hosting formulae for Springer Nature's open-source command-line tools. It contains no application logic itself — only Homebrew formula definitions (Ruby DSL) and packaging metadata (URLs, checksums, dependency lists) for projects that are themselves open-sourced and hosted elsewhere (typically `github.com/springernature/<project>`).

## Repository layout

- `Formula/<name>.rb` — one formula per tool.
- `Aliases/<short-name>` — symlink to a `Formula/*.rb` file, giving a formula a shorter `brew install` name (e.g. `Aliases/occe -> ../Formula/opencode-copilot-credit-estimator.rb`).
- `README.md` — user-facing tap documentation (how to tap/install).

## Before adding or updating a formula

1. **Confirm the upstream project is public and licensed.** A formula must not be added for a private repo unless explicitly agreed as a temporary `head`-only workaround (see below) with the intent to make it public soon. Check with:
   ```sh
   gh repo view <org>/<repo> --json isPrivate,licenseInfo
   ```
2. **Prefer a tagged release over `head`.** Pin `url`/`sha256` to a release tarball (e.g. `https://github.com/<org>/<repo>/archive/refs/tags/vX.Y.Z.tar.gz`) and set the real `license` (e.g. `"MIT"`), rather than tracking `head "...", branch: "main"`. Only use `head`-only formulae as a stopgap when upstream has no tags yet, and note this clearly in a comment.
3. **For Python CLI tools without a `[build-system]` in `pyproject.toml`** (i.e. a standalone script, not pip-installable), don't use `virtualenv_install_with_resources` directly (it will try `pip install <buildpath>` and fail with no build backend). Instead:
   - `virtualenv_create(libexec, "pythonX.Y")` to build a venv with just the dependencies (`venv.pip_install resources`).
   - `libexec.install` the script itself.
   - Write a thin wrapper in `bin/` that execs the venv's Python against the installed script.
   - See `Formula/opencode-copilot-credit-estimator.rb` for a worked example.
4. **Use wheel URLs, not sdists, for Python `resource` blocks** where a wheel is available (`bdist_wheel` in the PyPI JSON API `urls` list) — this avoids needing build-time network access for a build backend (hatchling/setuptools/etc.) inside Homebrew's build sandbox.
5. **Double-check every resource URL resolves and matches its declared sha256** before committing — a URL/sha256 mismatch (e.g. accidentally pairing an sdist URL with a wheel's checksum) will only surface as a failed download during `brew install`, not at review time. Fetch fresh JSON per package from `https://pypi.org/pypi/<name>/<version>/json` rather than trusting anything cached.

## Testing a formula locally

Don't rely on `brew install ./Formula/x.rb` — Homebrew requires formulae to be loaded from a tap. Use a local tap pointing at this working directory:

```sh
brew tap springernature/opensource /path/to/this/repo
brew trust springernature/opensource   # required, or brew refuses to load an untrusted tap's formulae
brew install --build-from-source springernature/opensource/<formula>   # or --HEAD for head-only formulae
brew test springernature/opensource/<formula>
brew style Formula/<formula>.rb
brew audit --formula --tap=springernature/opensource <formula>
```

Note: `brew tap` clones the **committed** state of this repo, not the working tree — commit changes locally before re-tapping to pick them up. Untap/re-tap (`brew untap springernature/opensource`) to pick up new commits during iteration.

Clean up after testing:
```sh
brew uninstall <formula>
brew untap springernature/opensource
```

## Git and permissions

- `git push` is typically denied by sandbox/agent permission policy in this environment. Make commits locally and hand the exact `git push` command back to the user rather than assuming it happened — verify against `git log --oneline origin/<branch>..HEAD` or `gh api repos/<org>/<repo>/tags`/`git ls-remote` once the user confirms they've pushed.
- Do not force-push, rewrite history, or push directly unless explicitly asked.

## Open-source process for upstream projects

This tap only packages projects that have themselves gone through Springer Nature's open-source approval process (see the private `springernature/open-source` repo for the policy and proposal template). When onboarding a new formula for a not-yet-public project, check proposal/approval status before assuming a repo can be made public — don't guess.
