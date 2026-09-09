# Make Overlays Great Again

Org program: **stable, independently verified, optionally Mongo-durable overlay services** in TypeScript and Go.

GitHub Project (org-wide): **[bsv-blockchain/projects/19](https://github.com/orgs/bsv-blockchain/projects/19)**

This repository is the written roadmap. Implementation lives in `ts-stack`, `go-overlay-services`, and `go-sdk`. **Nothing here authorizes merging those PRs, publishing packages, live database migration, or turning Mongo/BASM on by default.** Isolated CI green is not the same as a working overlay stack.

## Why this exists

A generic overlay consumer should see the first independently verified useful outputs promptly, then receive verified additions from slower hosts and hosts discovered later. Identity discovery must carry that through the wallet and UI without weakening transaction verification. Operators should be able to run overlay-owned persistence on MongoDB alone. TypeScript clients talking to Go overlay servers is the leading integration case.

Today that path is split across three repositories. Reviewers who only see one draft PR cannot see the program. This repo and [project 19](https://github.com/orgs/bsv-blockchain/projects/19) are the unifying picture.

## Working rule (until local integration is proven)

1. Keep every implementation PR **draft**.
2. Continue work on local branches and worktrees. Do **not** wait for `main` / `master` merges to make progress.
3. Prove the stacked TypeScript + Go system together locally (resolver → identity → optional Mongo admission → BASM) before any merge.
4. C05 (verified progressive API) is parked. **C02 and C04 both edit `LookupResolver.ts` and must not merge independently.**

## Open implementation PRs

| Package | PR | Repository | Role |
| --- | --- | --- | --- |
| C01+C02+C03 | [ts-stack#517](https://github.com/bsv-blockchain/ts-stack/pull/517) | ts-stack | Identity evidence intake, shared verification coordinator, chain-tracker cache lifecycle |
| C04 | [ts-stack#518](https://github.com/bsv-blockchain/ts-stack/pull/518) | ts-stack | Dynamic discovery and bounded host scheduling |
| S01+S02 | [ts-stack#519](https://github.com/bsv-blockchain/ts-stack/pull/519) | ts-stack | Opt-in Mongo payload/schema foundation |
| S03 | [ts-stack#525](https://github.com/bsv-blockchain/ts-stack/pull/525) | ts-stack | Opt-in Mongo admission commit on Engine submit (stacked on #519) |
| B01 TS | [ts-stack#520](https://github.com/bsv-blockchain/ts-stack/pull/520) | ts-stack | BASM protocol validation and Merkle-path offsets |
| Identity Go | [go-overlay-services#368](https://github.com/bsv-blockchain/go-overlay-services/pull/368) | go-overlay-services | Opt-in `tm_identity` / `ls_identity` |
| BASM+S01+S04 foundation | [go-overlay-services#369](https://github.com/bsv-blockchain/go-overlay-services/pull/369) | go-overlay-services | BASM primitives and opt-in Mongo persistence foundation |
| S04 admission | [go-overlay-services#370](https://github.com/bsv-blockchain/go-overlay-services/pull/370) | go-overlay-services | Mongo `engine.Storage` + admission commit (stacked on #369) |
| BEEF Go | [go-sdk#356](https://github.com/bsv-blockchain/go-sdk/pull/356) | go-sdk | Preserve BEEF wire versions and AtomicBytes subjects |

## Package map

| Phase | Packages | Intent |
| --- | --- | --- |
| 0 Contracts | W00–W02 | Baseline, fixtures, public/persistence contracts |
| 1 Client path | C01–C09 | Secure identity intake, shared verification, discovery, progressive APIs, wallet/UI, Go client parity |
| 2 Mongo runtime | S01–S07 | Additive storage contracts, Mongo payloads, atomic admission, GASP/BASM cursors, Mongo-only readiness |
| 3 BASM + operators | B01–B05 | Protocol conformance, durable recovery, topic status |
| 4 Release | R01–R03 | Migration rehearsal, cross-stack failure campaign, docs |

C05, C06–C09, S05–S07, B02/B04/B05, and R01–R03 are not in the current PR set. W01 fixtures are not started.

## Documents

| Read | Artifact |
| --- | --- |
| Requirements | [specification.md](specification.md) |
| PR-sized packages and dependencies | [implementation-plan.md](implementation-plan.md) |
| Acceptance / fault matrix | [verification-plan.md](verification-plan.md) |
| Mongo schema and admission | [mongo-storage.md](mongo-storage.md) |
| BASM recovery and topic status | [basm-recovery-status.md](basm-recovery-status.md) |
| What has actually been accepted locally | [execution-status.md](execution-status.md) |
| Go/frontend ownership inventory | [w00-go-ownership.md](w00-go-ownership.md) |

## Explicit non-goals for this wave

- npm / module publication
- Live database migration
- Turning Mongo or BASM on by default
- Merging C02 or C04 while C05 is parked
- Claiming a package complete because hosted CI is green
