#!/usr/bin/env bash
#
# check_codeowners.sh — Determine whether a formula's upstream GitHub repo has a
# CODEOWNERS file, and if not, identify its top contributor.
#
# Given a Formula/*.rb, derives the upstream <owner>/<repo> from its `url` and
# checks the conventional CODEOWNERS locations (.github/, root, docs/). If none
# is found, queries the contributors API and prints the login of the contributor
# with the most commits.
#
# Usage:
#   check_codeowners.sh <formula.rb>
#
# Output (stdout), tab-separated, one line:
#   <owner>/<repo>\t<status>\t<top_contributor>
# where <status> is "present" or "missing", and <top_contributor> is the login
# (only populated when status is "missing"; "-" otherwise).
#
# Exit codes:
#   0  Ran successfully (check the printed status).
#   1  Error (bad args, unexpected formula shape, gh failure).
#
# Requirements: gh (authenticated via GH_TOKEN or gh auth).

set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

FORMULA="${1:-}"
[ -n "$FORMULA" ] || die "usage: check_codeowners.sh <formula.rb>"
[ -f "$FORMULA" ] || die "no such file: $FORMULA"
command -v gh >/dev/null || die "gh not found on PATH"

current_url="$(sed -n 's/^[[:space:]]*url[[:space:]]*"\(.*\)".*/\1/p' "$FORMULA" | head -n1)"
[ -n "$current_url" ] || die "could not find a url \"...\" line in $FORMULA"

if [[ "$current_url" =~ github\.com/([^/]+)/([^/]+)/archive/refs/tags/ ]]; then
  owner="${BASH_REMATCH[1]}"
  repo="${BASH_REMATCH[2]}"
else
  die "url is not a github archive tarball url: $current_url"
fi

# Check the documented CODEOWNERS locations.
found="missing"
for path in ".github/CODEOWNERS" "CODEOWNERS" "docs/CODEOWNERS"; do
  if gh api "repos/$owner/$repo/contents/$path" \
      -H "Accept: application/vnd.github.raw" >/dev/null 2>&1; then
    found="present"
    break
  fi
done

if [ "$found" = "present" ]; then
  printf '%s/%s\tpresent\t-\n' "$owner" "$repo"
  exit 0
fi

# No CODEOWNERS: find the top contributor (most commits). The contributors API
# returns entries sorted by number of commits, descending.
top="$(gh api "repos/$owner/$repo/contributors?per_page=1" \
  --jq '.[0].login' 2>/dev/null || true)"
[ -n "$top" ] && [ "$top" != "null" ] || top="-"

printf '%s/%s\tmissing\t%s\n' "$owner" "$repo" "$top"
