#!/usr/bin/env bash
#
# check_and_update.sh — Check a formula's upstream GitHub project for a newer
# release and (optionally) update the formula's `url` + `sha256` in place.
#
# Prefers scripts over model reasoning: all version comparison, URL
# construction, checksum computation, and file rewriting is done here.
#
# Usage:
#   check_and_update.sh <formula.rb> [--apply]
#
#   <formula.rb>   Path to a Formula/*.rb file.
#   --apply        Rewrite url/sha256 in the formula. Without it, only reports.
#
# Exit codes:
#   0  Up to date, OR (with --apply) update written successfully.
#   3  A newer release is available (report-only mode, no --apply).
#   1  Error (bad args, network/parse failure, unexpected formula shape).
#
# Requirements: gh (authenticated), curl, shasum. Optional: brew (for `brew
# bump-formula-pr`-style sha, not used here).

set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

FORMULA=""
APPLY=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    -*) die "unknown flag: $arg" ;;
    *) [ -z "$FORMULA" ] && FORMULA="$arg" || die "unexpected extra arg: $arg" ;;
  esac
done

[ -n "$FORMULA" ] || die "usage: check_and_update.sh <formula.rb> [--apply]"
[ -f "$FORMULA" ] || die "no such file: $FORMULA"

command -v gh   >/dev/null || die "gh not found on PATH"
command -v curl >/dev/null || die "curl not found on PATH"
command -v shasum >/dev/null || die "shasum not found on PATH"

# --- Parse the current url + owner/repo out of the formula ------------------

current_url="$(sed -n 's/^[[:space:]]*url[[:space:]]*"\(.*\)".*/\1/p' "$FORMULA" | head -n1)"
[ -n "$current_url" ] || die "could not find a url \"...\" line in $FORMULA"

# Expect: https://github.com/<owner>/<repo>/archive/refs/tags/<tag>.tar.gz
if [[ "$current_url" =~ github\.com/([^/]+)/([^/]+)/archive/refs/tags/(.+)\.tar\.gz ]]; then
  owner="${BASH_REMATCH[1]}"
  repo="${BASH_REMATCH[2]}"
  current_tag="${BASH_REMATCH[3]}"
else
  die "url is not a github archive tarball url (expected .../archive/refs/tags/<tag>.tar.gz): $current_url"
fi

echo "formula:     $FORMULA"
echo "repo:        $owner/$repo"
echo "current tag: $current_tag"

# --- Ask GitHub for the latest published Release ----------------------------

latest_tag="$(gh api "repos/$owner/$repo/releases/latest" --jq '.tag_name' 2>/dev/null || true)"
[ -n "$latest_tag" ] || die "no published 'latest' release found for $owner/$repo (does upstream publish Releases, not just tags?)"

echo "latest tag:  $latest_tag"

if [ "$latest_tag" = "$current_tag" ]; then
  echo "status:      up to date"
  exit 0
fi

# Compare as semver (strip a leading v). Refuse to "downgrade".
norm() { echo "${1#v}"; }
higher="$(printf '%s\n%s\n' "$(norm "$current_tag")" "$(norm "$latest_tag")" \
  | sort -V | tail -n1)"
if [ "$higher" != "$(norm "$latest_tag")" ]; then
  echo "status:      current tag ($current_tag) is >= latest release ($latest_tag); nothing to do"
  exit 0
fi

new_url="https://github.com/$owner/$repo/archive/refs/tags/$latest_tag.tar.gz"

echo "status:      newer release available: $current_tag -> $latest_tag"
echo "new url:     $new_url"

# --- Compute sha256 of the new tarball --------------------------------------

echo "downloading new tarball to compute sha256..."
new_sha="$(curl -fsSL "$new_url" | shasum -a 256 | awk '{print $1}')"
[ -n "$new_sha" ] || die "failed to compute sha256 for $new_url"
echo "new sha256:  $new_sha"

if [ "$APPLY" -ne 1 ]; then
  echo
  echo "report-only (no --apply). Re-run with --apply to write these changes."
  echo "NOTE: verify upstream dependencies (pyproject.toml / requirements) did not"
  echo "change between $current_tag and $latest_tag; resource blocks are NOT updated."
  exit 3
fi

# --- Rewrite url + sha256 in place ------------------------------------------
# Only touch the top-level url/sha256 (the first occurrences), never the
# resource blocks' url/sha256 lines.

tmp="$(mktemp)"
awk -v newurl="$new_url" -v newsha="$new_sha" '
  BEGIN { done_url=0; done_sha=0 }
  # First top-level url "..."  (indented two spaces in these formulae)
  !done_url && $1=="url" {
    match($0, /^[[:space:]]*/); indent=substr($0, RSTART, RLENGTH)
    print indent "url \"" newurl "\""
    done_url=1; next
  }
  # First top-level sha256 "..." after the url
  done_url && !done_sha && $1=="sha256" {
    match($0, /^[[:space:]]*/); indent=substr($0, RSTART, RLENGTH)
    print indent "sha256 \"" newsha "\""
    done_sha=1; next
  }
  { print }
' "$FORMULA" > "$tmp"

mv "$tmp" "$FORMULA"
echo
echo "updated $FORMULA: $current_tag -> $latest_tag"
echo "REMINDER: verify resource blocks (Python deps) are still correct, then run"
echo "  brew style $FORMULA && brew audit --formula --tap=springernature/opensource ${repo}"
exit 0
