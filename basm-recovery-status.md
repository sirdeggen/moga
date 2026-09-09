# BASM recovery and operator status design

**Purpose.** This is a documentation-only design for making BRC-136 recovery
resumable and making its result visible without overstating what an anchor
comparison proves. It describes a proposed extension; it does not assert that
the TypeScript implementation has all of this behavior today.

## Normative baseline

The current [BRC-136](https://github.com/bsv-blockchain/BRCs/blob/master/overlays/0136.md)
defines BASM over the *ordered admitted subset* of a canonical block. It is not
the older idea of a sparse tree over every block position. Build the admitted
list by walking canonical block order and retaining every admitted transaction;
do not sort, deduplicate, or renumber it. Hash txids in internal byte order;
render wire/JSON hashes as lower-case display-order hex.

The root rules are exact:

| Admitted count | Root |
| --- | --- |
| 0 | 32 zero bytes |
| 1 | the one txid, un-hashed |
| 2+ | Bitcoin `SHA256d(left || right)` levels, duplicating an odd final leaf |

An anchor is `(topic, blockHeight, blockHash, basmRoot, admittedCount)`. Its
TAC commits to the sequence through a height with
`SHA256d(previousTac || blockHash || basmRoot)`. A block hash is part of the
claim: it must be checked against the local chain tracker before a remote
anchor can drive repair. Reorganizations invalidate anchors from the fork
height on and require canonical recomputation.

BASM is historical, confirmed-topic-set evidence. GASP remains the live and
pre-confirmation propagation mechanism. An equal BASM/TAC at a common,
canonical height is evidence that the two peers agree on the admitted history
for that topic and interval. It is **not** a claim that either peer has every
transaction globally, that lookup answers are equal, that all peers agree, or
that a topic's admission policy is compatible. It cannot detect a transaction
that every reachable comparison peer omits.

## Audit of the current TypeScript behavior

Source review was performed at ts-stack commit
[`2bc799a`](https://github.com/bsv-blockchain/ts-stack/tree/2bc799a8d8e535242e6de2d305f426ce3975ea7b).

| Area | Confirmed now | Consequence / gap |
| --- | --- | --- |
| BASM construction | [`BASM.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay/src/BASM.ts) implements display/internal conversion, zero, singleton, odd duplication, and TAC hashing. | Matches the current BRC-136 construction. |
| Anchor persistence and contiguous extension | [`Engine.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay/src/Engine.ts#L281-L396) rebuilds contiguous anchors, including zero-admission heights after genesis, and caps one pass at 1,024 heights. | Extension can resume on a later trigger, but there is no durable recovery-job cursor or completion record. |
| Remote protocol and forward repair | [`BASMRemote.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay/src/BASMRemote.ts) supplies tip, range, admitted-list, compound-proof, and raw-transaction requests. [`Engine.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay/src/Engine.ts#L1646-L1779) fetches only a bounded recent forward range, recomputes the returned list root/count, verifies each BUMP against the chain tracker, checks raw txids, then resubmits historical transactions. | The code validates important peer inputs. It does not validate a remote anchor's `blockHash` against a local header before using it in the forward path, and it does not independently verify the returned list's claimed block indices. These are proposed hardening requirements. |
| Equal-height/history divergence | [`Engine.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay/src/Engine.ts#L1681-L1686) returns `diverged` with the message that historical divergence needs manual or binary-search reconciliation when the local tip is equal to or ahead of the remote tip and TACs differ. | No automatic backward localization or repair exists today. Do not describe recovery as complete. |
| Failure isolation | A peer failure is caught and reported as `error` by [`Engine.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay/src/Engine.ts#L1699-L1703); endpoint/topic iteration is serial. | One peer is isolated, but an endpoint-discovery error before the per-peer call can abort `startBASMSync`; there is no persisted retry/backoff policy or bounded parallel scheduler. |
| Startup, polling, and reorgs | [`OverlayExpress.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay-express/src/OverlayExpress.ts#L3027-L3100) starts sync when enabled, advances anchors, polls, and optionally attaches a reorg SSE stream. The engine rebuilds affected chains and has a shallow revalidation fallback. | Startup logs “complete” after the one current run even when reports contain `advanced`, `diverged`, `error`, or no peer. Timers are fire-and-forget and have no durable lease/cursor. Reorg revalidation only scans its configured recent depth. |
| Existing monitoring | [`OverlayMonitor.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay-express/src/OverlayMonitor.ts#L337-L409) can probe one public anchor tip and flag an expected-TAC mismatch or height lag. | It is useful health evidence, not a successful peer comparison or recovery-completion proof. |
| Go audit | A bounded text inventory of `go-overlay-discovery-services`, `go-bsv-middleware`, and `go-overlay-services` found no BASM identifiers. | This is a limited audit only; it must not be read as a claim that BASM is absent from every Go implementation or deployment. |

The public HTTP implementation currently exposes the BASM request routes with
the topic in `x-bsv-topic`; its admin start route requires admin authentication
([routes](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay-express/src/OverlayExpress.ts#L2221-L2316),
[admin route](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay-express/src/OverlayExpress.ts#L2776-L2786)). A public **status/health response** is not a suitable place for peer URLs, raw txids, proof bytes, retry state, or internal errors. This does not restrict the credential-free, cross-domain BRC-136 protocol routes, whose purpose is to exchange admitted txids, BUMPs, and raw transactions under their established request bounds.

## Proposed bounded, resumable recovery

Run one logical job per `(topic, peer identity, canonical chain context)`.
Use a durable lease so only one worker mutates that job, but retain idempotent
steps because a process can die after storage writes and before cursor updates.
Each invocation has explicit bounds: maximum peer requests, anchor heights,
admitted txids, raw bytes, proof bytes, wall time, and concurrent peer/topic
work. Requeue unfinished work with bounded exponential backoff and jitter.

1. **Preflight.** Pin a local canonical tip/header snapshot and check that the
   peer speaks the agreed BASM protocol version, topic identifier, admission
   policy/version (or effective-from height), hash byte order, and genesis
   height. These are proposed, additive capability-negotiation fields: the
   current BASM endpoints do not carry them. A legacy peer may still be used
   when an operator pins an independently validated compatibility mapping
   (peer identity, topic, policy/version or effective height, genesis and
   network) and the current BRC checks pass; record that basis durably.
   Otherwise its result is explicitly unsupported/incompatible evidence, not
   agreement. Do not require a breaking wire upgrade solely to add metadata.
   Compatibility is a prerequisite, not a repairable divergence. Record
   `unavailable` for transport/timeout failures and `disabled` when the feature
   or compatible peer configuration is absent.
2. **Compare at a common canonical height and snapshot.** Choose `min(localTip,
   remoteTip, pinnedChainTip)`. Fence all range/list/proof pages by recording
   a remote tip tuple and re-reading the tip plus each relevant anchor before
   committing a page; a same-height TAC can change while a peer repairs its
   history. A peer with an additive snapshot capability may bind pages to that
   snapshot, but repeat-tip/anchor fencing makes the existing wire shape
   implementable. Abandon the attempt if the fence or local canonical epoch
   changes. Resolve and compare local and remote anchors only when both block
   hashes equal the locally resolved canonical hash. A matching TAC at that
   same height establishes the job's current `lastCommonHeight`; different
   heights must never be called a match.
3. **Locate divergence.** On mismatch, use capped `HEIGHT_RANGE` requests and
   binary search (or a capped forward scan from the durable known-good
   coordinate) to find the first mismatching anchor. Binary search is valid
   only over contiguous, canonical anchors from a previously equal height: TAC
   equality at a height means the whole prefix agrees, while a per-block root
   only speaks for that block. Persist the next range or search interval after
   every bounded batch. Equal-height/local-ahead mismatch follows this path; it
   is not a terminal “manual” result.
4. **Repair one height at a time.** Reject a remote TBA unless its topic,
   height, canonical block hash, recomputed BASM root, and count agree. Obtain
   the ordered admitted list *with block indices* under explicit count/list/byte
   limits; validate every txid/index
   against the local canonical block/BUMP proof, reject duplicates and
   non-monotonic or malformed indices, and compare the list-derived root/count
   to the TBA. Request BUMP for the missing txids, verify every path against the
   local chain tracker and intended height/header, then fetch raw transactions.
   Check raw bytes derive the requested txid, then apply the local, compatible
   admission predicate before admission. A peer list is an evidence candidate,
   never authority to insert its claimed admission. Missing local entries may
   be recovered this way; local-only entries must be retained and diagnosed as
   divergence/policy or history evidence, not automatically deleted to copy a
   peer.
5. **Commit and re-check.** Commit transaction admission and the resulting
   local anchor atomically where the storage model permits; otherwise make the
   transaction/anchor writes idempotent and recoverable. Recompute local root,
   count, and TAC from the last durable common anchor. Advance the cursor only
   after the recomputed TBA agrees with the remote TBA and its canonical header
   is still pinned. A late proved admission or repaired missing transaction at
   height `h` changes topic history even when the block hash did not change:
   increment the topic-history generation/admission revision, rebuild TAC and
   anchors from `h` forward, and invalidate comparisons/cursors completed at or
   after `h`. The job performing this repair records its own old→new history
   generation, checkpoint and lease fence in the same atomic commit, or a
   recoverable handoff that cannot claim completion until finalized; it resumes
   in that new revision rather than invalidating itself repeatedly. An
   unexpected competing history-generation change or chain reorg rewinds the
   affected work to the first affected height.
6. **Completion.** “Recently agreed” requires a successful, durable final
   comparison with at least one configured peer at one *common canonical
   height*, plus proof that the job had no uncommitted work. Persist the peer,
   compared height and hash, both TACs, protocol/policy identity, completion
   time, work ID, and coverage target (local/remote/canonical tips and allowed
   height lag). It means peer-relative historical agreement through that
   height only. A remote-ahead common-prefix match remains `syncing` until the
   durable target is caught up and a new common canonical comparison succeeds;
   it is never a caught-up completion merely because an older prefix matches.

Never use an anchor supplied by a peer as chain authority. A reorg, header
lookup failure, proof failure, inconsistent TBA/list, raw-tx mismatch, policy
mismatch, resource-limit hit, and network failure must produce distinct
machine-readable causes. Do not silently convert any of them into agreement.

## Persistence contract to coordinate with `mongo-storage.md`

This document does not change that document or prescribe its collection names.
The Mongo storage design should provide equivalent durable records and indexes
for these semantic contracts:

| Record | Required fields and invariants |
| --- | --- |
| Topic anchor | Immutable identity `(scope, topic, chainEpoch, topicHistoryGeneration, height, blockHash)` unique, matching the Mongo proposal; `scope` includes network/genesis/node ownership. A fenced canonical-current projection selects `(scope, topic, height)`; retain `basmRoot`, `admittedCount`, `tac`, source/admission-policy identity, and update time. Reorg replacement preserves prior noncanonical history; a late/repaired local admission creates a new topic-history generation even with the same block hash. Fence the projection by both generations, and rebuild TAC forward contiguously. |
| Recovery job | Stable job ID; topic, peer identity/endpoint snapshot, protocol/policy/genesis compatibility tuple, pinned tip/hash, chain epoch, topic-history generation, state, attempt/backoff, bounded-work counters, lease owner/expiry, error code, and audit timestamps. Unique active job by `(topic, peer identity, compatibility tuple)`. |
| Recovery cursor | Durable `lastCommonHeight/hash/tac`, chain epoch, topic-history generation, next search interval or range cursor, current divergent height, and commit checkpoint. Cursor movement is monotonic only inside both fenced generations; it rewinds at a recorded fork or history-revision height. |
| Successful comparison | Topic, peer identity, common height/hash, local and remote TAC, policy/protocol tuple, chain epoch, topic-history generation, local/remote/canonical target tips and allowed lag, completion time, work ID, and an integrity marker showing no uncommitted cursor work. Retain history long enough to explain a badge transition. |
| Diagnostics/audit | Sanitized status transitions, counts, durations, canonical/reorg epoch, and error class. Do not persist credentials or surface raw transaction/proof payloads in ordinary status records. |

Indexes must support topic-badge reads, active-job leasing, cursor restart,
anchor range retrieval in height order, reorg invalidation, and history-revision
invalidation. Writes that claim a green completion must use conditional
update/transaction semantics so a stale worker cannot overwrite a newer chain
epoch, topic-history generation, or attempt.

## Status contract and UI

Status is **per topic**. Existing HTTP availability, lookup health, anchor-tip
lag, or a successful `/admin/startBASMSync` call are inputs to operations; none
is equivalent to BASM agreement.

Aggregate observations conservatively. A fresh, canonical, compatible
divergence; proof/header/storage-integrity failure; or active recovery below its
durable target takes precedence over a different peer's older or common-prefix
match. A topic is green only when its required current target has a recent
durable agreement and no higher-precedence unresolved observation in its active
comparison set. Persist the compared common height and target heights so the
frontend can distinguish an agreement at the current target from a stale
prefix. A topic-history generation change invalidates a successful comparison
at or after its affected height and removes green until a fresh fenced
comparison completes. Retain local extra admissions as unresolved evidence or diagnose a
genuine policy/history conflict; do not delete them simply to make aggregation
green.

| Badge | Public meaning | Minimum evidence |
| --- | --- | --- |
| **recently agreed** (green) | This topic recently agreed with a compatible peer through the required target, at a stated common canonical height. | A durable successful comparison after completed work; peer, common height/hash, matching TACs, policy/protocol tuple, target/lag evidence, age inside an operator-set freshness window, and no unresolved higher-precedence observation. |
| **syncing** | A compatible recovery/extension job has bounded work queued or running. | Durable active/queued job, including remote-ahead common-prefix work that has not reached its persisted target. |
| **diverged** | A validated, compatible common-height comparison differs, or local repair re-check differs. | First divergent height/range and canonical validation; local-only admissions remain evidence; policy incompatibility has its own explicit reason. |
| **unavailable** | No usable comparison can currently be made or integrity/persistence prevents trustworthy completion. | Timeout, peer failure, header/proof/storage failure, no reachable peer, or exhausted retry budget, with timestamp. |
| **stale** | The last successful agreement is too old or behind the canonical tip by the configured bound. | Last durable success and configured age/height thresholds. |
| **disabled** | BASM is not enabled or lacks the required compatible configuration. | Explicit configuration reason; never infer it from a missing old record. |

The public **status/health** UI or API should show only the badge, topic, last checked time, common
height/hash when safe to disclose, and a short peer-relative statement such as
“agreed with a configured peer through height 900000.” It must not imply global
completeness. The admin UI/API may additionally show peer identity, policy and
protocol versions, TACs, cursor/range, counts, job attempt/backoff, reorg
epoch, bounded-work limits, and sanitized failure reason. It must require the
existing administrative authorization and avoid raw transactions, BUMPs,
credentials, or internal topology in the public view.

## TS/Go interoperability and fault evidence required before implementation

Shared conformance fixtures should be language-neutral and cover:

- BASM roots and TACs for empty, singleton, even, odd, duplicate-looking, and
  non-sorted block-order admitted lists; include display/internal byte-order
  vectors and canonical JSON/binary anchors.
- Topic/policy version, genesis-height, case, invalid hash, count/list/root,
  index/order, and range-limit incompatibilities; incompatibility must not be
  recorded as repaired divergence.
- Independent TypeScript and Go implementations exchanging all six BRC-136
  messages, including 1,024-boundary pagination and exact proof/raw-tx checks.
- Equal-height and local-ahead historical divergence localization; a remote
  ahead by more than one batch; local extra admission (retained, never copied
  away), remote extra admission, and successful recheck after repair.
- A stable remote snapshot across paginated range/list/proof retrieval, plus a
  changed remote tip or local chain epoch between pages; verify that mixed
  snapshots never produce a cursor advance or green completion.
- Malicious or faulty peer replies: noncanonical block hash, wrong topic,
  mismatched TBA/list/count, bad/partial BUMP, mismatched raw bytes, missing
  response entries, oversized ranges/lists/proofs, timeout, malformed JSON,
  and one failing peer while another can succeed.
- Crash/restart at every boundary: before/after lease, each fetch, admission,
  anchor write, cursor checkpoint, and final completion write. Verify no false
  green status, duplicate admission, skipped interval, or stale-worker
  overwrite.
- Reorg during localization, proof fetch, commit, and after completion;
  shallow and deeper-than-configured recovery; timer/SSE disconnection and
  restart. Verify canonical fencing and that status leaves green until a fresh
  comparison completes.
- A late or recovered admission at an already-canonical block height, during
  localization and after green completion. Verify a new topic-history
  generation, downstream TAC rebuild, cursor/comparison invalidation, and no
  stale green badge even though the block hash and chain epoch are unchanged.
- Status transitions and access control: public payload has no sensitive
  diagnostics; admin diagnostics are protected; green is impossible without
  recent durable common-height agreement and successful durable work.

## Source ledger

- [BRC-136 current specification](https://github.com/bsv-blockchain/BRCs/blob/master/overlays/0136.md): construction, wire fields, reconciliation, reorg and security rules.
- [`BASM.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay/src/BASM.ts): current TypeScript hash/type implementation.
- [`Engine.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay/src/Engine.ts): anchor extension, reorg response, endpoint resolution, peer reconciliation, and proof/raw submission.
- [`Storage.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay/src/storage/Storage.ts) and [`KnexStorage.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay/src/storage/knex/KnexStorage.ts): current optional storage contract and SQL reference behavior.
- [`BASMRemote.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay/src/BASMRemote.ts), [`OverlayExpress.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay-express/src/OverlayExpress.ts), and [`OverlayMonitor.ts`](https://github.com/bsv-blockchain/ts-stack/blob/2bc799a8d8e535242e6de2d305f426ce3975ea7b/packages/overlays/overlay-express/src/OverlayMonitor.ts): current HTTP, startup, reorg, and monitoring surfaces.

All items under “Proposed” remain design requirements until code, durable
storage, cross-implementation conformance, and fault tests demonstrate them.
