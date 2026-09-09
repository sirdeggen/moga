# Evidence and acceptance plan

Status: proposed implementation checks, 8 September 2026. These tests and benchmarks have **not** been run by this planning task. The current executed work is focused read-only source inspection, official-reference checks by the delegated reviewers, Markdown/link/consistency review and planning. This document defines the evidence future implementation PRs must produce.

## Evidence vocabulary and retention

Keep separate claims for source implementation, runtime wiring, enabled configuration, released artifact and observed deployment. A code branch or green unit test does not establish live activation. Record source SHA, runtime/driver/backend versions, policy/network/genesis, test seed, host hardware, fixture digest, exact command, exit status and artifact path for every acceptance result. Record failures and limits as well as successes. Use synthetic identities, keys, topics and payloads in public evidence; telemetry should use bounded counts/sizes/durations/error classes rather than queries, emails, phone numbers, keys or transaction payloads.

The authoritative source inventory is [evidence-client-go.md](evidence-client-go.md), augmented by baseline tables in [BASM](basm-recovery-status.md) and [Mongo storage](mongo-storage.md). Main requirements and proposed contracts are in [specification.md](specification.md); package ownership and review gates are in [implementation-plan.md](implementation-plan.md). Official references are linked at the claims they support in those focused documents. Pin the BRC-136 revision/hash used for conformance when W01 creates fixtures; a moving `master` URL alone is insufficient fixture provenance.

## Required profiles

| Profile | Purpose |
| --- | --- |
| TS client → Go server, Mongo replica set | Primary product integration; progressive identity, independently verified data, durable server recovery/status. |
| TS client → TS server, Mongo and retained SQL profiles | Feature parity and default/backward compatibility. |
| Go client → Go and TS servers | Language-neutral output/proof and BASM/GASP interoperability; Go-client package ownership resolved in W00. |
| Browser/worker, browser without optional WASM/worker facilities, Node, supported mobile bundle | Lifecycle, memory and responsiveness without Node dependency leakage or mandatory cross-origin isolation. |
| Current peer ↔ legacy peer, legacy wallet ↔ updated IdentityClient | Capability fallback preserves wire/result/defaults; unsupported progress/status is explicit. |
| Three-member Mongo replica set plus controlled Atlas staging | Deterministic crash/failover contracts locally; managed-service failover/restore validation with separately authorized environment. |

All conformance fixtures are implementation-independent. Generate expected Bitcoin txids/Merkle roots/TACs using an independent reference calculation and reviewed known vectors; avoid two implementations agreeing only because one generated both expected values and results. Interpret duplicate-looking root test data separately from valid admission lists: real admitted-list duplicates and duplicate block indices are rejected.

## Client, discovery and verification matrix

| Case | Fixture / failure injection | Acceptance invariant | Requirements / packages |
| --- | --- | --- | --- |
| T01 Late tracker | Tracker A returns host A immediately; tracker B later returns new host B; A lacks a useful output B has. Also run shared stale-cache refresh. | A verified result can arrive early; B is queried and contributes within active attempt; cache/subscribers retain B. No permanently first-tracker host selection. | P1, P2 / C04–C07 |
| T02 Heterogeneous discovery | Trackers advertise disjoint services, one tracker serves none itself; empty/malformed/offline trackers; different endpoint URLs. | Only requested-service eligible advertised hosts queried; no assumption trackers host it; provenance/empty/failure preserved; one failure isolated. | P1, P4 / C04 |
| T03 Hanging peers | Never-resolving DNS/fetch/body, headers then stalled body, no Content-Length, slow large response. | First useful output independent of hang; bounded attempts settle with timeout coverage and existing temporary backoff; body bytes and queued work bounded. | P3, P4 / C04, C05 |
| T04 Byte identity | Valid BEEF with false/nonempty txid hint, malformed raw bytes, mismatched target/output index and proof-bound ID. | No trusted txid/cache/output publication before derived-byte match; later correctly bound candidate succeeds. | V1–V3 / C01, C02 |
| T05 Shared transaction | Many outputs from one transaction, repeats from several hosts, two consumers arriving while verification runs, shared ancestors across transactions. | One coordinating transaction job per compatible txid/context; no repeated successful transaction verification for each output/host; shared valid ancestors reused; all distinct valid outpoints retained. | V2, V4 / C02, C03 |
| T06 Candidate recovery | Bad/partial/malformed proof first, complete valid proof later both during and after initial failure; conflicting Merkle path; bounded flood of variants. | First candidate cannot poison txid forever; later valid evidence accepted; failed candidate isn't global invalidity; fair bounded retention and unresolved-limit reporting. | V3 / C02 |
| T07 Confirmed/unconfirmed | Small confirmed proof; long/wide unconfirmed ancestry; missing input; invalid script/value; valid cert in transaction without valid chain anchoring. | Canonical Merkle fast path for confirmed; necessary ancestry/scripts for unconfirmed; no `scripts only` or certificate-only acceptance; false and throws both fail closed. | V1, V5 / C01–C03 |
| T08 Chain/policy | Same txid/network variants, stale header cache, reorg during fetch/verify/delivery, deep reorg, policy change, restarted persistent cache. | Positive verdict keyed to context; affected dependency chain invalidated, old in-flight result cannot publish; unaffected history reusable; no cached height-root assumption. | V4 / C03 |
| T09 Output/identity | Same tx multiple indices, out-of-range index, conflicting host context, wrong certificate/output binding, untrusted certifier, decrypt failure, certificate false/throw fixture. | Transaction inclusion doesn't bypass service/output checks; only qualifying verified identities displayed; built-in invalid-signature throw remains rejected. Explicit false fixture validates proposed adapter contract, not a claim of existing exploit. | V2, V5 / C01, C02, C06 |
| T10 Permission/cache/contact | Different originators/authenticated users, permission enabled/disabled, `seekPermission` omitted/explicit, trust settings changed, local-contact override, legacy cache hit. | Existing permission semantics preserved and new capability mediated; no cross-originator decrypted/trust cache sharing; local contacts not marked overlay-verified; trust/reorg invalidate relevant cached result. | P2, V4, V5, X1 / C03, C06 |
| T11 Lifecycle | Typeahead A then B; unsubscribe one of two consumers; last subscriber detaches; stop iterator; non-interruptible worker completes late; slow subscriber overflow. | A never changes B's rows/state/errors; cancellation doesn't kill work owned by another; no ownerless unbounded work; bounded snapshot resync preserves removals/final event; terminal exactly once. | P3 / C02, C04–C07 |
| T12 Outcomes | Successful empty host, all unavailable, semantic rejection, only invalid proof, certifier filter removes all, mixed partial valid/failed hosts, freeform response. | Distinct attempt outcome/evidence; no empty means global absence; freeform retains its own validation/aggregation; completion claims only observed bounded coverage. | P4 / C05–C07 |
| T13 Wallet/API compatibility | Old Promise discovery methods/result object, limit/offset, local contacts, current helper pagination gap, new optional capability and old remote transport. | Existing wire/declarations/default behavior fixture preserved; new progress doesn't bypass wallet; legacy fallback accurately final-only/wallet-attested; primary capable path genuinely progressive. | P2, X1 / W00, W02, C06, C07 |
| T14 Worker/backends | Cold/warm JS/WASM, batch mixed contexts, disposal, worker crash, oversized item, memory-limited SDK route, no SharedArrayBuffer. | Verdict parity and correct job mapping; errors don't downgrade trust; budgets effective, UI responsive, no forced COOP/COEP/CORS restriction. | P3, V6, X1 / C08 |
| T15 Generic/Go consumer | Non-identity output consumer plus Go client tests against both servers. | Resolver reusable beyond identity; same outpoint and verification semantics; context cancellation bounds and legacy wire supported. | P2, V1–V4, X1 / C05, C09 |

Host reputation regression fixtures preserve the current grace/backoff/success-reset rules. Intentional cancellation, semantic rejection and local resource limits must not count as ordinary network failures. Cryptographic failure remains separate from availability/structural response health.

## MongoDB, migration and propagation matrix

| Case | Fixture / failure injection | Acceptance invariant | Requirements / packages |
| --- | --- | --- | --- |
| T20 Commit crash points | Kill before/after op claim, payload reference, spend/output/history write, outbox write, commit and ACK send. | No partial published logical admission; acknowledged operations survive restart; retry returns saved deterministic result; all durable side effects eventually recover. | S1, S2 / S01–S04 |
| T21 Ambiguous commit | Inject `TransientTransactionError`, `UnknownTransactionCommitResult`, primary change and ACK loss separately. | Transient abort body rerun idempotent; ambiguous commit reconciles same identity/commit before fresh body; no duplicate effects or lost acknowledged commit. | S2 / S02–S04 |
| T22 Concurrency | Duplicate submission, same idempotency key/different digest, competing spend, stale worker lease/fence, multi-replica startup. | Unique deterministic admission, mismatch rejected, conflict semantics explicit, stale owner cannot overwrite newer epoch or completed operation. | S2 / S01–S05 |
| T23 Index/publication | Enlisted Mongo projection fails, external projector fails/duplicates/reorders, unsupported plugin idempotency, projection rebuild, banned discovery record race. | ACK/lookup visibility accurately reflect publication contract; no assumed plugin replay safety; backlog/rebuild observable; serving bans don't erase historical admission/BASM. | S2, O2 / S03, S05 |
| T24 Payload boundaries | BSON metadata near limit, >16 MiB individual raw tx, large BEEF ancestry, same ancestor referenced by several BEEFs, staged GridFS upload crash and corrupt/missing chunk. | Safe out-of-transaction upload then ready publication; references never point to incomplete content; per-tx/proof decomposition demonstrates shared ancestry, individual tx supported; digest mismatch rejected. | S3 / S02 |
| T25 Payload GC | Concurrent publisher/pinner/GC, crash between payload-ready and admission, payload retained only by recovery/outbox/old canonical history, restore. | Atomic live→deleting claim serializes with new reference/pin creation; after claim no new reference can commit, before claim live references prevent deletion; physical chunk deletion resumes safely after crash. Abandoned uploads eventually reclaimed without loss of required historical data. | S3 / S02, R01 |
| T26 GASP recovery | Multiple identical scores across page boundary; inclusive and strict-since legacy peers with finite page caps; crash after graph admission before cursor; invalid peer before healthy peer. | Overlap fallback only after inclusive/all-ties-drain semantics are proven; otherwise proven full resync or explicit capability limitation with no skipped cursor advance. Negotiated tuple honors stable ordering; cursor advances with durable finalization only; peer/topic isolation. | S2, B3, X1 / S06 |
| T27 Propagation | Network unreachable after local commit, duplicate delivery, changed advertisement, restart with queued work, later successful peer. | Durable retryable intent not dropped; observed remote acknowledgment separate from local acceptance; no claim that queued means delivered. Live/unconfirmed data remains supported independently of BASM. | S2, B3 / S03, S04, S06 |
| T28 Startup/failover | Overlay SQL unavailable/absent under Mongo profile; retained SQL profile; Mongo primary down/schema invalid/full disk; expired lease; Atlas failover/restore. | Mongo-only overlay boots with configured wallet abstraction; selected backend readiness truthful; no writes falsely acknowledged during durability failure; bounded recovery with observable backlog. | S1, S4, O2 / S07, R02 |
| T29 Migration/cutover | Duplicated legacy records, unknown/unrepresentable record, proofs/anchors/unconfirmed history, quiescent export/delta cutoff, restart migration. | No silent drop; manifests/digests/counts match; imports idempotent; canonical/history distinction and data payloads retained; restart safe. | S4 / R01 |
| T30 Rollback | Mongo ACKs new admissions, evictions, proofs, reorg state after cutover; payload/index delta; incompatible old schema. | Switch to SQL only after zero Mongo-only ACKs or complete replay/reconciliation through final fenced cutoff. Otherwise remain read-only/forward-fix; old readers reject incompatible schema. | S4 / R01 |

Local test replica sets establish deterministic fault behavior. Atlas tests measure operational RPO/RTO, majority latency and recovery for the selected tier/topology; this plan makes no RPO/RTO commitment and does not authorize a live failover. Derive runbook thresholds from those measurements.

## BASM and operator matrix

| Case | Fixture / failure injection | Acceptance invariant | Requirements / packages |
| --- | --- | --- | --- |
| T40 Root/TAC conformance | Zero/singleton/even/odd admitted counts, unsorted txids in canonical block order, byte-order vectors, empty heights and topic genesis. | Current Bitcoin Merkle construction and contiguous TAC identical across languages; no superseded sparse tree; no txid lexical sorting. | B1, X1 / W01, B01, B03 |
| T41 Forward range | Peer >1,024 heights ahead, empty blocks, incomplete/overlapping/missing/reordered pages, same-height changing tip TAC, range cap. | Explicit target, continuity and snapshot fencing; no skipped height/cursor; more work queued when bounded; common prefix isn't caught-up completion. | B2 / B01, B02, B04 |
| T42 Historical divergence | Equal-height mismatch, local-ahead mismatch, same-block late missing admission, multiple mismatching intervals. | Bounded localization against cumulative TAC after known equal prefix, replay-safe repair, topic-history revision invalidates downstream TAC, recomputation through target and durable comparison; no manual-only early return. | B2 / B02, B04 |
| T43 Local extras/conflict | Local strict superset, remote superset, independently valid distinct sets, different topic policy/history and incomplete peer. | Retain local admitted data; pull valid missing data; classify peer-behind/reciprocal repair or bounded unresolved conflict; never delete to manufacture agreement. | B2, B3 / B02, B04 |
| T44 Peer proof attacks | Wrong canonical block hash/height, valid BUMP for wrong position, duplicate txid/index, wrong root/count, proof missing tx, raw bytes mismatch, oversized proof/list. | Independent chain, position, txid, root/count and local admission predicate checks; no progress or green on invalid/incomplete evidence. | B1, B2 / B01–B04 |
| T45 Restart/reorg/history revision | Crash at fetch/stage/admission/anchor/cursor/comparison; reorg during each and after success; own repair versus competing late admission in the same canonical block while recovery/green exists; deep reorg; timer/SSE interruption. | Separate chainEpoch and topicHistoryGeneration fence anchors, cursors and comparisons; same-block historical change invalidates downstream TAC and prior green. Own repair atomically advances its job/checkpoint to the new revision without a restart loop; unexpected competing changes rewind safely. Stale workers cannot publish; no mixed generation; fresh durable comparison required. | B2, O1 / B02, B04, B05 |
| T46 Capability/error isolation | Legacy endpoint lacks metadata, unsupported Go peer, configured compatible legacy manifest, policy mismatch, one tracker/peer/topic fails, scheduler contention. | Additive negotiation or explicit pinned compatibility; no breaking required fields; unsupported/unknown distinct; one failed peer cannot abort all topic work. | B1, B2, X1 / B01–B04 |
| T47 Status aggregation | One peer matches, another fresh canonical mismatch; Mongo write failure with old success; lagging common prefix; stale/no prior evidence; disabled/unsupported. | Per-topic precedence prevents false green; common height/hash/age/lag shown; storage failure and unresolved divergence visible; each topic row has accessible badge and reason. | O1, O2 / B05 |
| T48 Status/protocol access | Public vs authenticated admin status, arbitrary-origin browser protocol requests, private diagnostic fields. | Status redacts credentials/topology/raw proof payload; ordinary BRC protocol still serves specified txids/proofs/raw transactions publicly under existing cross-origin policy. Admin recovery control remains authorized. | O2, X1 / B01, B05 |
| T49 Historical vs current view | Equal anchors with local serving ban, shared peer omission, new unconfirmed transaction only in GASP, delayed projection. | Labels do not claim global completeness, identical lookup results, unspentness or freshness; historical admission remains intact; separate live/index health visible. | B3, O1 / S05, S06, B05 |

## Benchmark method and ratification

Measure the entire path from query start through tracker discovery, host response headers/body completion, parsing, queue wait, transaction verification, output/certificate verification, wallet event and UI paint. Report first useful **verified** result, later unique useful additions, attempt settlement, CPU/worker utilization, longest main-thread task, resident/decoded/queued bytes, cache hit reasons and actual transaction verification job count. Never substitute first raw HTTP byte for first useful result.

Use fixed cohorts: small confirmed proofs; one transaction with many outputs; duplicate hosts; missing-first/valid-later proofs; overlapping ancestry; deep/wide unconfirmed graphs; oversized raw transaction; cold/warm WASM/header/cache; slow-region/tracker delays; typeahead at several concurrent-user loads. Record p50/p95 (and tails where sample count supports them), sample count, variance, hardware/network throttling and warm-up policy. Compare current source to secured baseline C01 and optimized implementation separately: mandatory verification adds real work, so comparing only with the insecure old parser is misleading.

The specification's 100 ms added first-useful overhead and 50 ms main-thread proposal apply only after fixture/hardware ratification. Network, graph-size, policy and resource-cap outliers remain separately reported. Sweep concurrency and budgets, then choose finite per-runtime defaults in W02/C08 before activation. Do not use verifast README's local benchmark claims as measurements of this workload. Acceptance requires no correctness regression, bounded resource use and measurable progressive delivery under heterogeneous peers; any numerical release gate must identify its exact cohort.

## Requirement-to-task traceability

| Requirement | Owning packages | Acceptance evidence |
| --- | --- | --- |
| P1 | C04, C05 | T01, T02 |
| P2 | C05–C07, C09 | T01, T13, T15 and UI recording |
| P3 | C02, C04, C05, C08 | T03, T11, T14 and memory/latency report |
| P4 | C04–C07 | T02, T03, T12 and reputation regression |
| V1 | C01–C03, C09 | T04, T07, T15 |
| V2 | C02, C09 | T04, T05, T09 |
| V3 | C02, C09 | T06 |
| V4 | C03, C06 | T05, T08, T10 |
| V5 | C01, C02, C06 | T07, T09, T10 |
| V6 | C08 | T14 and target-workload benchmark |
| S1 | S01–S05, S07 | T20–T23, T28 |
| S2 | S01–S06 | T20–T23, T26, T27 |
| S3 | S02 | T24, T25 |
| S4 | S07, R01, R02 | T28–T30 |
| B1 | B01, B03 | T40, T44, T46 |
| B2 | B02, B04 | T41–T46 |
| B3 | S05, S06, B02, B04, B05 | T26, T27, T43, T49 |
| O1 | B05 | T45, T47, T49 |
| O2 | S07, B05 | T23, T28, T47, T48 |
| X1 | W00–W02, C06, C09, S06, B01, B03, R01–R03 | All required profile runs, T13–T15, T26, T30, T40, T46, T48 and repository gates |

An implementation PR attaches its subset of this ledger with actual results, plus authoritative repository checks appropriate to changed code. The parent reviewer checks that every requirement has concrete evidence before calling implementation complete. Unrun/manual/deployed checks stay explicitly unverified; documentation review cannot mark them passed.
