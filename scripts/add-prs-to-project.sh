#!/bin/sh
# Attach overlay reliability PRs to org project 19.
# Requires: gh auth refresh -s read:project,project
set -eu
OWNER=bsv-blockchain
PROJECT=19

if ! gh auth status -t 2>/dev/null | grep -q 'project'; then
  echo "This token cannot write GitHub Projects."
  echo "Run: gh auth refresh -s read:project,project"
  exit 1
fi

for url in \
  https://github.com/bsv-blockchain/ts-stack/pull/517 \
  https://github.com/bsv-blockchain/ts-stack/pull/518 \
  https://github.com/bsv-blockchain/ts-stack/pull/519 \
  https://github.com/bsv-blockchain/ts-stack/pull/520 \
  https://github.com/bsv-blockchain/ts-stack/pull/525 \
  https://github.com/bsv-blockchain/go-overlay-services/pull/368 \
  https://github.com/bsv-blockchain/go-overlay-services/pull/369 \
  https://github.com/bsv-blockchain/go-overlay-services/pull/370 \
  https://github.com/bsv-blockchain/go-sdk/pull/356
do
  echo "adding $url"
  gh project item-add "$PROJECT" --owner "$OWNER" --url "$url"
done
