#!/usr/bin/env bash
#
# codeowners.sh — Resolve the upstream GitHub repo's code owners for a formula
# and print their GitHub logins, one per line.
#
# Given a Formula/*.rb whose `url` points at a github.com archive tarball, this
# fetches the upstream repo's CODEOWNERS file (checking the conventional
# locations), extracts every @owner / @org/team mention, and prints the
# usernames (without the leading @). Org/team refs (@org/team) are printed as
# individual usernames. GitHub PR assignees must be individual users, so
# @org/team entries are dropped and reported on stderr.
#
# Usage:
#   codeowners.sh <formula.rb>
#
# Output: newline-separated GitHub usernames on stdout (may be empty).
# Exit codes:
#   0  Ran successfully (even if no CODEOWNERS / no owners found).
#   1  Error (bad args, unexpected formula shape, gh failure).
#
# Requirements: gh (authenticated via GH_TOKEN or gh auth).

set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

FORMULA="${1:-}"
[ -n "$FORMULA" ] || die "usage: codeowners.sh <formula.rb>"
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

# CODEOWNERS may live in any of these paths (GitHub's documented locations).
raw=""
for path in ".github/CODEOWNERS" "CODEOWNERS" "docs/CODEOWNERS"; do
  if raw="$(gh api "repos/$owner/$repo/contents/$path" \
      -H "Accept: application/vnd.github.raw" 2>/dev/null)"; then
    [ -n "$raw" ] && break
  fi
  raw=""
done

if [ -z "$raw" ]; then
  echo "no CODEOWNERS found for $owner/$repo (checked .github/, root, docs/)" >&2
  exit 0
fi

# Extract @mentions from non-comment lines. Individual users only:
# drop @org/team entries (can't be PR assignees) and warn about them.
printf '%s\n' "$raw" \
  | sed 's/#.*//' \
  | grep -oE '@[A-Za-z0-9/_-]+' \
  | sed 's/^@//' \
  | sort -u \
  | while IFS= read -r handle; do
      if [[ "$handle" == */* ]]; then
        echo "skipping team owner @$handle (not an assignable user)" >&2
      else
        echo "$handle"
      fi
    done
