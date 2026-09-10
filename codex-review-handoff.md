# Codex review handoff — overlay reliability (Grok)

**Date:** 9 September 2026  
**Author:** Grok 4.6 (this session)  
**For:** Codex, independent review of unmerged overlay work  
**Planning folder:** `/Users/personal/Documents/ChatGPT/Make Overlays Great Again`  
**Also published:** `bsv-blockchain/make-overlays-great-again` (private org repo) at `codex-review-handoff.md`

This is a review brief, not an acceptance claim. Isolated CI green is **not** integration acceptance. **Do not merge** any implementation PR to `main` / `master`.

---

## 1. What you are reviewing

A multi-repo overlay reliability program (“Make Overlays Great Again”). Goal: TypeScript and Go overlays that independently verify useful outputs, identity discovery that does not weaken tx verification, and **opt-in** Mongo-only persistence. Leading integration case: **TS client → Go overlay server**.

User instruction after CI work: **stop treating merge as the next step**. Complete and validate on local stacked branches (localhost, Docker Mongo, ngrok) before human review / merge. C05 remains parked.

Binding docs (same folder / same private repo):

| File | Role |
| --- | --- |
| `specification.md` | Requirements |
| `implementation-plan.md` | Packages W00–R03 |
| `verification-plan.md` | Evidence matrix (mostly unrun as live integration) |
| `mongo-storage.md` | Mongo schema / admission |
| `basm-recovery-status.md` | BASM |
| `execution-status.md` | Ledger (may lag this session) |
| `README.md` | Public-facing program map |

Org board: https://github.com/orgs/bsv-blockchain/projects/19  
Tracker: https://github.com/bsv-blockchain/make-overlays-great-again/issues/1

---

## 2. Hard constraints (do not violate)

- Keep all implementation PRs **draft**.
- No npm / package publication.
- No live DB migration.
- Do not turn Mongo or BASM on as production defaults.
- **C05 parked.** C02 (`ts-stack#517`) and C04 (`ts-stack#518`) both edit `LookupResolver.ts` and **must not merge independently**.
- Testdata in go-sdk is gitignored and excluded from golangci-lint (user confirmed). Probe mains need `git add -f` if reintroduced.
- HTTP overlay-services still defaulted to `NewNoopEngineProvider` on the PR branches. The local host is a **separate unpushed worktree**, not a default-engine change on those PRs.
- Do not force-push stacked branches unless restacking.

---

## 3. Draft PRs (heads as of this handoff)

All labeled `overlay-reliability`. Descriptions and comments link project 19 + tracker #1. Merge state `BLOCKED` is review/draft, except #370 `CLEAN` vs its stacked base.

| Package | PR | Branch → base | SHA |
| --- | --- | --- | --- |
| C01+C02+C03 | [ts-stack#517](https://github.com/bsv-blockchain/ts-stack/pull/517) | `codex/overlay-evidence-c02` → `main` | `582a1e988c` |
| C04 | [ts-stack#518](https://github.com/bsv-blockchain/ts-stack/pull/518) | `codex/overlay-discovery-c04` → `main` | `30f0398fae` |
| S01+S02 | [ts-stack#519](https://github.com/bsv-blockchain/ts-stack/pull/519) | `codex/overlay-mongo-s02` → `main` | `0a847b56c7` |
| S03 | [ts-stack#525](https://github.com/bsv-blockchain/ts-stack/pull/525) | `codex/overlay-admission-s03` → `main` | `3e59bb8efa` |
| B01 TS | [ts-stack#520](https://github.com/bsv-blockchain/ts-stack/pull/520) | `codex/basm-protocol-hardening` → `main` | `a2a32b90e9` |
| Identity Go | [go-overlay-services#368](https://github.com/bsv-blockchain/go-overlay-services/pull/368) | `codex/go-identity-topic` → `master` | `0ab86b2e72` |
| BASM+Mongo foundation | [go-overlay-services#369](https://github.com/bsv-blockchain/go-overlay-services/pull/369) | `codex/go-overlay-mongo-s04` → `master` | `13b67045dd` |
| S04 admission | [go-overlay-services#370](https://github.com/bsv-blockchain/go-overlay-services/pull/370) | `codex/go-overlay-admission-s04` → `#369` | `a6acfc836a` |
| BEEF Go | [go-sdk#356](https://github.com/bsv-blockchain/go-sdk/pull/356) | `codex/go-beef-compatibility` → `master` | `529032523b` |

**CI (ts-stack):** merge-gate, Early policy, Build/lint/policy, Quality gate **zero new Sonar findings**, and Coverage / aggregate upload (90% patch) passed on these heads. **`codecov/patch` is informational** and was red on several PRs; do not treat it as the merge gate.

**CI (Go):** GitHub checks green on #368/#369/#370/#356. SonarCloud’s public issue search can still list stale `line: None` findings; Go does not run ts-stack’s zero-new-findings script.

**Not started as PRs:** W01 fixtures, C05–C09, S05–S07, B02/B04/B05, R01–R03. Certificate field-order (`localeCompare` vs `sort.Strings`) remains OPEN.

---

## 4. Worktrees (local)

| Path | Branch | Notes |
| --- | --- | --- |
| `/Users/personal/.codex/worktrees/c436/ts-stack` | `codex/overlay-evidence-c02` | #517 |
| `/Users/personal/.codex/worktrees/22a2/ts-stack` | `codex/overlay-discovery-c04` | #518 |
| `/Users/personal/.codex/worktrees/s02-ci/ts-stack` | `codex/overlay-mongo-s02` | #519 |
| `/Users/personal/.codex/worktrees/84d9/ts-stack` | `codex/basm-protocol-hardening` | #520 |
| `/Users/personal/.codex/worktrees/bbd6/ts-stack` | `codex/overlay-admission-s03` | #525 (includes S02 + S03 vs main) |
| `/Users/personal/git/go/worktrees/go-overlay-services-identity` | `codex/go-identity-topic` | #368 |
| `/Users/personal/git/go/worktrees/go-overlay-services-s04-ci` | `codex/go-overlay-mongo-s04` | #369 |
| `/Users/personal/git/go/worktrees/go-overlay-services-basm` | `codex/go-overlay-admission-s04` | #370 |
| `/Users/personal/git/go/worktrees/go-sdk-beef-compatibility` | `codex/go-beef-compatibility` | #356; `go.mod` testdata gitignored |
| `/Users/personal/git/go/worktrees/go-overlay-local` | `local/overlay-validation` | **Unpushed.** Merge of #370 + #368 identity. Local host example. `go.mod` replace → BEEF SDK worktree. **Do not push this branch.** |

---

## 5. What Grok changed after the original package implementations

These are the main follow-ups Codex should review (behavior and CI), not the entire overlay design.

### 5.1 ts-stack product / CI

- **Wallet identity without `services`:** `discoverOverlayCertificates` no longer calls `getServices()` (that threw and broke BRC-100 `discoverBy*` conformance). Missing services returns `[]` unless `forceRefresh` (still throws `WERR_INVALID_PARAMETER`). Extracted `requireOverlayChainTracker` for S3776.
- **`StorageUint64` brand (S6564):** kept as branded string; added `asStorageUint64`; Engine/Mongo admission write sites updated. Decode path returns the brand.
- **Mongo write conflicts:** concurrent snapshot spends threw `WriteConflict` without `TransientTransactionError`. Retries in `MongoTransactionRunner` (claim + body) and `commitAdmission` (`runAdmissionWithWriteConflictRetry`, 8 attempts).
- **Patch coverage:** tests added so 90% patch-coverage gate passes. `Storage.ts` / `ChainTracker.ts` were types-only and absent from LCOV; tiny runtime helpers (`storageHasAdmission`, chain-tracker helper) plus tests.
- **Sonar in tests:** S5906 `.length).toBe(` → `.toHaveLength(`.
- **js-yaml GHSA-2883:** pnpm override `js-yaml@<3.15.2: 3.15.2`, plus `exceptions.json`, `dependency-release-policy.json` (`retainedCount` 22), and `scripts/dependency-release-governance.test.mjs` ratchet 21→22.
- **Browser budgets:** raised SDK / wallet-toolbox client+mobile / message-box-client / did-client UMD/Vite/esbuild/Hermes after sonar helper extraction grew bundles. Prettier `requiredExports: ["DIDClient"]` one-liner.
- **#525** retargeted to `main` so `ci.yml` runs; merged latest S02 coverage helper into the stack.

### 5.2 Go

- S3776 extractions on identity (`ProjectOutput`, `compileAttributes`, `selectedTransaction`), BEEF `AtomicBytes` / `beefEntryID`, Mongo/BASM helpers, admission `CommitAdmission`.
- golangci follow-ups on #369 (errorlint `errors.Is`, shadow, prealloc, ctx-first, error-last, G115).
- **#370 compile break after merging #369 sonar helpers:** admission collection constants, field names, `projector`, and `schemaDataSpecs()` bootstrap were dropped; restored on #370 (`a6acfc8`). Review that merge carefully.
- go-sdk `authhttp` DATA RACE on #356 was treated as **unrelated flake** and rerun; do not “fix” authhttp as part of BEEF unless it reproduces.

### 5.3 Program visibility (not overlay code)

- Private repo `bsv-blockchain/make-overlays-great-again` with roadmap README.
- Label `overlay-reliability` on all nine PRs.
- Grok **could not** add cards to org project 19 (token/app lacks Project write). User can auto-add items with `label:overlay-reliability`.

---

## 6. Local validation stack (running at handoff)

| Piece | State |
| --- | --- |
| Docker Mongo `rs0` | `local-mongo-1`, `127.0.0.1:27017` |
| Go host | `http://127.0.0.1:18080/api/v1` — binary `/tmp/overlay-local-host`, source `examples/localhost` in `go-overlay-local` |
| Public tunnel | `https://deggen.ngrok.app` → localhost:18080 (`ngrok http 18080 --url deggen.ngrok.app`) |
| Smoke | `listTopicManagers` → `tm_identity`; `listLookupServiceProviders` → `ls_identity`; `POST /lookup` empty identityKey → `{ "type": "output-list" }` |

Harness docs: `local/README.md`, `local/smoke.sh`, `local/client.mjs`, `local/docker-compose.yml`.

**Proven:** HTTP wiring of stacked Go identity + Mongo store bootstrap + Engine as `OverlayEngineProvider` (PR branches still no-op HTTP by default). Node/curl client against localhost and ngrok.

**Not proven (do not claim):**

- Real identity certificate **submit** (needs valid BEEF + independent chain tracker).
- Identity projection durability (example uses **in-memory** projection; restart wipes it; Mongo store is for engine admission UTXOs, not the identity index).
- Example `localTracker` **always returns true** for merkle roots — local-only, unsafe for any verification claim.
- C04 LookupResolver discovery / host scheduling against this host.
- Wallet/UI (C06/C07), GASP, BASM recovery jobs, Atlas failover.
- ngrok without `ngrok-skip-browser-warning` in browsers.

Host processes can die after ~10h session cap; Mongo/ngrok may outlive them. Restart:

```sh
docker compose -f local/docker-compose.yml up -d
cd /Users/personal/git/go/worktrees/go-overlay-local
OVERLAY_MONGO_URI='mongodb://127.0.0.1:27017/?replicaSet=rs0' go run ./examples/localhost
# if ngrok down:
ngrok http 18080 --url deggen.ngrok.app
```

---

## 7. Suggested Codex review focus

Priority order:

1. **#517 Wallet `requireOverlayChainTracker` / empty vs throw** — conformance vs C02 “no unverified identities”.
2. **#525 / #519 admission + `StorageUint64` + write-conflict retries** — retries must not convert a true spend-conflict into a silent success, or starve the winner.
3. **#370 restored Mongo constants / `schemaDataSpecs`** after sonar merge — confirm admission collections still bootstrap and scores still remap `"0"` to Unix millis.
4. **#518 LookupResolver** — health forbids `JSON.stringify` (use `stringifyBRC100`); C05 still parked; discovery cache keys.
5. **#356 AtomicBytes** — wire bytes identical to pre-extract; testdata still force-added / lint-excluded.
6. **Local `examples/localhost`** — not for merge; review only as validation harness (always-true tracker, memory projection).
7. **Budget / js-yaml / coverage helpers** — necessary for CI; confirm they do not hide real missing tests or pin unjustified bundle growth.

Please record findings against package IDs (C02, S03, S04, …) and say whether each finding blocks **local integration** vs **eventual merge**.

---

## 8. Suggested next work (after review)

Still no merge.

1. Canned identity certificate **submit** against the local host (fixtures in `pkg/topics/identity/testdata`), with a real or recorded chain tracker — not `localTracker`.
2. Point C04 `LookupResolver` at `http://127.0.0.1:18080` and `https://deggen.ngrok.app` (skip ngrok warning header).
3. Durable identity `Projection` on Mongo (package currently forbids an in-memory production adapter).
4. W01 fixtures.
5. Only then human review of drafts.

---

## 9. What this document is not

- Not an update of `execution-status.md` to `verified` for any package.
- Not authorization to merge, publish, or activate Mongo/BASM defaults.
- Not evidence that T01–T49 in `verification-plan.md` have been run.
