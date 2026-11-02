#!/usr/bin/env bash
# Keeps a single GitHub issue in sync with the broken links reported by the
# link-check job of the current workflow run:
# - opens the issue when broken links are found and none is open
# - rewrites the issue body with the latest list on every run (no notification)
# - comments only when the list changes, so notifications mean something new
# - closes the issue when all links are valid
#
# Timeouts are listed in the issue but never open it or trigger a comment on
# their own: slow sites come and go, and a timeout isn't proof a link is broken.
#
# Hyperhawk has no outputs and GitHub keeps only 10 warning annotations per
# step, so the list is read from the link-check job log.
#
# Required environment: GH_TOKEN, REPO, RUN_ID, RUN_URL
set -euo pipefail

LABEL="broken-links"
MARKER_START="<!-- broken-links:start -->"
MARKER_END="<!-- broken-links:end -->"

current=$(mktemp)
previous=$(mktemp)
body=$(mktemp)
solid_current=$(mktemp)
solid_previous=$(mktemp)

job_id=$(gh api "repos/$REPO/actions/runs/$RUN_ID/jobs" --jq '.jobs[] | select(.name == "link-check") | .id')
gh api "repos/$REPO/actions/jobs/$job_id/logs" \
  | { grep -o '##\[warning\]Broken .*' || true; } \
  | sed 's/^##\[warning\]//' \
  | sort -u > "$current"

issue=$(gh issue list --repo "$REPO" --label "$LABEL" --state open --json number --jq '.[0].number // empty')

if [ ! -s "$current" ]; then
  echo "No broken links."
  if [ -n "$issue" ]; then
    gh issue comment "$issue" --repo "$REPO" --body "All links are valid as of [this run]($RUN_URL). Closing."
    gh issue close "$issue" --repo "$REPO"
  fi
  exit 0
fi

count=$(wc -l < "$current" | tr -d ' ')
echo "$count broken link(s)."
{
  echo "The weekly link check reports $count broken link(s). Last checked in [this run]($RUN_URL)."
  echo
  echo "$MARKER_START"
  sed 's/^\(.*\)$/- `\1`/' "$current"
  echo "$MARKER_END"
  echo
  echo "This issue is updated by the link check workflow. It gets a comment when the list changes and is closed when all links are valid."
} > "$body"

grep -v '(Timed out' "$current" > "$solid_current" || true

if [ -z "$issue" ] && [ ! -s "$solid_current" ]; then
  echo "Only timeouts, not opening an issue."
  exit 0
fi

if [ -z "$issue" ]; then
  gh label create "$LABEL" --repo "$REPO" --force --color d73a4a --description "Reported by the weekly link check"
  gh issue create --repo "$REPO" --title "Broken links" --label "$LABEL" --body-file "$body"
  exit 0
fi

gh issue view "$issue" --repo "$REPO" --json body --jq .body \
  | sed -n "/$MARKER_START/,/$MARKER_END/p" \
  | { grep '^- `' || true; } \
  | sed 's/^- `\(.*\)`$/\1/' \
  | sort -u > "$previous"
grep -v '(Timed out' "$previous" > "$solid_previous" || true

gh issue edit "$issue" --repo "$REPO" --body-file "$body"

# Compare by URL (the 4th field: "Broken <type> link: <url> (<error>)"), so a
# link whose error message changes isn't a change. A link counts as fixed only
# when it's no longer reported at all, not when it merely times out instead.
added=$(awk 'FILENAME == ARGV[1] { seen[$4]; next } !($4 in seen)' "$solid_previous" "$solid_current")
removed=$(awk 'FILENAME == ARGV[1] { seen[$4]; next } !($4 in seen)' "$current" "$solid_previous")
if [ -z "$added" ] && [ -z "$removed" ]; then
  echo "No changes since the last run."
  exit 0
fi

{
  echo "The list changed in [this run]($RUN_URL)."
  if [ -n "$added" ]; then
    echo
    echo "**New:**"
    echo "$added" | sed 's/^\(.*\)$/- `\1`/'
  fi
  if [ -n "$removed" ]; then
    echo
    echo "**Fixed or no longer reported:**"
    echo "$removed" | sed 's/^\(.*\)$/- `\1`/'
  fi
} > "$body"
gh issue comment "$issue" --repo "$REPO" --body-file "$body"
