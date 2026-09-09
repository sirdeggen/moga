#!/bin/sh
# Smoke the local overlay host. Does not merge, publish, or activate defaults.
set -eu
BASE=${OVERLAY_BASE_URL:-http://127.0.0.1:18080/api/v1}

fail() { echo "FAIL: $*" >&2; exit 1; }

json() {
  curl -fsS "$@"
}

echo "GET $BASE/listTopicManagers"
managers=$(json "$BASE/listTopicManagers")
echo "$managers" | grep -q tm_identity || fail "tm_identity missing from topic managers: $managers"

echo "GET $BASE/listLookupServiceProviders"
lookups=$(json "$BASE/listLookupServiceProviders")
echo "$lookups" | grep -q ls_identity || fail "ls_identity missing from lookup providers: $lookups"

echo "POST $BASE/lookup empty identityKey"
lookup=$(json -H 'Content-Type: application/json' \
  -d '{"service":"ls_identity","query":{"identityKey":"02aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","limit":1}}' \
  "$BASE/lookup")
echo "$lookup"
echo "$lookup" | grep -qi 'output-list\|formula\|outputs\|type' || fail "unexpected lookup body: $lookup"

echo "OK: local overlay host answered identity list + empty lookup"
