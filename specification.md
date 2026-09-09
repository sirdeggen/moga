# Overlay reliability specification

Status: user-approved specification, 8 September 2026; local implementation is in progress. The [execution ledger](execution-status.md) is authoritative for current source/test deliveries and originating-root acceptance; acceptance of a bounded delivery does not complete the whole specification or authorize deployment. Requirement IDs below remain binding scope; proposed API names, schemas, budgets, rollout gates and estimates remain engineering proposals until implementation reviews establish them.

## 1. Outcome and boundaries

A generic overlay consumer should see the first independently verified useful outputs promptly, then receive verified additions from slower hosts and hosts discovered later. Identity discovery must carry this behavior through the wallet and into the UI without weakening transaction verification, certificate validation, wallet permissions, or trusted-certifier policy. Operators should be able to run overlay-owned persistence on MongoDB alone and see evidence of each topic's historical synchronization health. TypeScript and Go must interoperate, with the TypeScript-client/Go-server combination the leading integration case.

SHIP is Service Host Interconnect Protocol. SLAP is Service Lookup Availability Protocol. SLAP trackers advertise hosts for a lookup service; a tracker need not serve that service. Topic admission, lookup selection, network propagation, and synchronization are separate responsibilities. BASM anchors confirmed historical admissions; GASP and immediate propagation remain necessary for recent and unconfirmed data.

### Required contracts

| ID | Requirement |
| --- | --- |
| P1 | Discover from all configured eligible trackers under bounded handling; query newly discovered eligible hosts during the active session. First tracker, fastest host, and response size confer no authority or completeness. |
| P2 | Deliver independently verified useful results incrementally through generic resolver, wallet/identity capability, and UI; retain existing final APIs and portable protocols. |
| P3 | Bound concurrency, bytes, queues, verification work, time, and retained state; cancel/supersede cleanly, isolate late results, and define ownership of shared work. |
| P4 | Describe completion relative to this bounded attempt. Distinguish successful empty answers, no qualifying verified records, semantic rejection, invalid evidence, partial success, and availability failure. Retain existing temporary host backoff. |
| V1 | Verify transactions independently before overlay-derived results become useful. Verify all required unconfirmed ancestry/scripts; use the canonical-header Merkle fast path for confirmed transactions. Never use `scripts only` to establish overlay trust. |
| V2 | Bind transaction ID to parsed immutable bytes. Deduplicate outputs by validated outpoint and share successful and in-flight transaction verification by transaction ID within a compatible trust context. |
| V3 | Keep receipt, evidence candidates, in-flight work, verified results, and contextual failures distinct. A bad/incomplete first proof cannot suppress a later valid candidate. |
| V4 | Bind cache verdicts to network, verification policy, canonical headers and dependencies; invalidate on reorganization, changed policy/trust, or expiry. Reuse valid shared ancestry/proofs. |
| V5 | Verify output existence and service semantics separately. Identity requires successful certificate verification, field/key binding, decryption and trusted-certifier checks. Inclusion alone proves neither unspentness nor freshness. |
| V6 | Reuse and benchmark existing `@bsv/verifast` BDK/WASM and SDK verification; keep heavy parsing/verification off the UI thread or cooperatively bounded where workers are unavailable. |
| S1 | Offer coherent Mongo-only overlay persistence in TS and Go, including all overlay-owned records listed below, while preserving existing adapters and deployments. |
| S2 | Define replay-safe admission, indexing, durable acknowledgment, propagation recovery, unique keys, transaction boundaries, retry and restart behavior. |
| S3 | Support shared transactions, proof variants, large BEEF and oversized individual raw transactions with bounded storage/transport handling and safe blob publication/recovery. |
| S4 | Provide versioned migrations, selected-backend startup/readiness, data-preserving cutover and rollback rehearsal; prefer Atlas replica-set durability. |
| B1 | Complete current BRC-136 recovery in TS and implement compatible Go BASM, using the current admitted-transaction Merkle construction. |
| B2 | Localize and repair equal-height and other history divergence with bounded resumable work, validated proofs/canonical anchors, durable progress, peer isolation and reorg/restart recovery. |
| B3 | Preserve independent GASP/live propagation, moderation policy and honest limits on what anchor agreement proves. |
| O1 | Show a visual status beside each topic in the overlay frontend. Green requires fresh evidence at a common canonical height and successful durable work. |
| O2 | Expose actionable synchronization/recovery diagnostics to operators with a redacted public projection; distinguish readiness/liveness from BASM agreement. |
| X1 | Keep TS/Go portable conformance, additive public/wallet/wire compatibility, credential-free public cross-domain access, and staged rollout with independently reviewed evidence. |

### Explicit exclusions

The advertiser's wallet-storage provider remains abstracted and is future work. This project does not rewrite wallet-toolbox storage, advertiser SQL/GORM wallets, wallet sessions/payments, external chain services or broadcast services. Mongo-only refers to the overlay database deployment/cluster, not elimination of replica sets or every external dependency. Existing SQL adapters are retained. User approval authorizes local source implementation and testing through the originating task. Publication, push, deployment, live database migration, feature activation and default switches remain unauthorized; this planning task retains its bounded documentation/ledger assignment.

New record framing, server-side streaming within one lookup response, and new lookup-record pagination are optional later optimizations. Required bounded BASM range/list/proof continuation and GASP no-skip cursor handling are in scope now. Global overlay completeness, peer-majority truth, globally identical lookup results and automatic deletion of local historical admissions to match a peer are not guarantees.

## 2. Verified baseline and engineering uncertainties

The table below records the original inspected baseline before the accepted implementation slices. The focused [source evidence](evidence-client-go.md) and baseline sections of [Mongo storage](mongo-storage.md) and [BASM recovery/status](basm-recovery-status.md) carry precise links and inspection scope; the [execution ledger](execution-status.md) records subsequent corrections and validation. Source code presence and local acceptance do not establish activation or deployed behavior.

| Area | Confirmed baseline | Design consequence |
| --- | --- | --- |
| Resolver | `queryDetailed` waits for selected hosts by default; `query$` emits cumulative responses after fixed `rankedHosts` discovery; first usable tracker resolves discovery snapshot. | Make discovery an ongoing source for a bounded scheduler; preserve old result contracts. |
| Transport | Each HTTP response is buffered before JSON/binary/BEEF processing. | Cross-host progression needs no wire change; per-record transport progression is a separate capability. |
| Trust | Resolver merge uses first-wins outpoint dedup and accepts any nonempty supplied txid string without binding it to bytes in that helper. Identity parser does not establish transaction/SPV validity. | Place trusted dedup after byte binding and transaction verification; repair final identity path as well as progressive path. |
| Certificate | Parser awaits `Certificate.verify()` without checking its returned boolean; the internally constructed ProtoWallet throws on an invalid signature. | Require explicit success in the planned contract; this is not a confirmed invalid-certificate acceptance bug in the current concrete path. |
| Wallet | Public discovery returns a Promise result object with `limit`/`offset`; toolbox validates these but does not forward them on the overlay path. Interface prose and validators disagree on `seekPermission` default. Trust/result caches and local-contact paths exist. | Characterize and preserve current behavior pending focused compatibility decisions; use additive authorized capabilities and label local provenance. |
| Verifier | SDK already supports Merkle-path fast path and graph bookkeeping per call; verifast supplies BDK/WASM/worker/batch facilities. | Extend compatible sharing and measure this workload; do not start a new C++ integration. |
| Server | TS engine storage/startup directly depends on Knex; Mongo already backs many lookup/discovery indexes. | An adapter alone cannot make runtime Mongo-only. |
| BASM | TS has substantial helpers, persistence, endpoints and wiring; automatic synchronization defaults off. Equal/ahead divergence returns without historical repair. | Complete recovery and explicit scheduling; do not relabel existing polling as full peer reconciliation. |
| Go | Bounded inspected trees have engine storage interfaces and Mongo discovery indexes; no BASM or production implementation of engine Storage was found there. | Establish adapter ownership/version before implementation; absence is limited to inspected sources. |

The original documentation baseline did not include target workload benchmarks or executed fault tests; subsequent local checks and their limits are recorded in the execution ledger. Deployment configuration, live databases and runtime activation remain unverified. Source SHAs can advance; implementation PRs must revalidate their baseline. Existing cache invalidation and transaction/index callback behaviors need focused implementation audits, not assumptions that all adapters already satisfy this specification.

## 3. Progressive lookup architecture

### 3.1 Layering and discovery

The proposed pipeline is `DiscoverySession → bounded HostScheduler → evidence intake → shared VerificationCoordinator → service validator → consumer session`. The generic resolver understands lookup answers and outpoints. Identity interpretation remains in an identity adapter operating through the wallet's authorized discovery boundary.

1. Capture immutable query, service, network/genesis identity, verification policy, originator/trust context and consumer generation. Validate query and endpoint policy before work starts.
2. Subscribe to shared discovery keyed by network, service and discovery configuration. Yield cached hosts immediately with age/provenance, and continue bounded tracker refresh. Preserve ordinary cache freshness policy; each active query listens to any refresh already in flight, and a stale/uncached query starts one. A cached list must never cause late tracker additions from its refresh to be lost.
3. Process every eligible tracker's successful advertisements as they arrive. Trackers are routing sources; only their advertised eligible hosts are queried for the requested service. Decode and validate SLAP service/network data and validate advertisement transaction/output evidence before treating it as verified routing metadata. Until validated it may be a bounded untrusted routing hint, never proof of service authority. Endpoint validation and fetch bounds apply to every hint.
4. Normalize host identity using existing URL semantics without merging distinct paths/ports accidentally; retain tracker provenance separately. New eligible hosts enter a fair queue immediately. Reputation determines scheduling priority, not exclusive authority. Coalesce identical host requests only within compatible query/security contexts.
5. Each completed HTTP response becomes evidence intake independently. Validate framing/size/record shape before parse, then bind bytes, validate transactions and validate outputs. Emit useful results without waiting for slower hosts or unrelated queued verification. Continue merging within the session bounds.
6. Close discovery only when its configured sources settle or its bounded budget ends; drain already admitted host/verification work within the session budget. Record excluded/backed-off/overflow hosts and truncation as coverage metadata. Emit one terminal event, release subscriptions, and reject all later delivery to that consumer.

Preserve existing supported network, origin, CORS and public-access semantics. Arbitrary host advertisements must not turn a Node/server-side resolver into an unrestricted internal-network fetch primitive; the implementation gate inventories current endpoint policy, redirects, schemes and DNS handling, preserving intentional local-network operation through explicit deployment configuration. This is request-boundary work, not an origin allowlist default.

### 3.2 Additive API sketch

Names are proposals. Do not silently reinterpret existing `query$` outputs as cryptographically verified. Introduce an explicitly verified generic capability, and reuse its machinery for the secured identity final path. Existing raw/freeform resolver APIs remain available with accurate guarantees.

```ts
interface VerifiedLookupOptions {
  signal?: AbortSignal
  verification: VerificationContext  // network, canonical chain source, policy, backend
  limits?: Partial<LookupLimits>
}

interface VerifiedLookupSession {
  readonly id: string
  events: AsyncIterable<LookupEvent>
  final: Promise<LookupAttemptSummary>
  cancel(reason?: 'superseded' | 'user' | 'disposed'): void
}

type LookupEvent =
  | { kind: 'progress'; sessionId: string; revision: number; progress: Progress }
  | { kind: 'delta'; sessionId: string; revision: number;
      added: VerifiedOutput[]; updated: VerifiedOutput[];
      removed: Array<{ outpoint: string; reason: string }>; progress: Progress }
  | { kind: 'settled'; sessionId: string; revision: number; summary: LookupAttemptSummary }
```

`VerifiedOutput` contains a derived txid and integer in-range output index, immutable/ref-counted transaction/evidence handle, verified-at context, output-validator version and explicit provenance. Host context data stays untrusted until the service validator binds it to the verified output. Internal caches do not expose mutable transactions/proofs. A generic freeform answer has separate service-defined validation and aggregation; it cannot be labeled SPV verified or coerced into an empty output list. Preserve the existing freeform/final API behavior.

`Progress` uses counts for trackers discovered/settled/failed, hosts queued/in-flight/settled/empty/rejected/failed, candidate outputs, transactions pending/verified/invalid/retryable, useful outputs, and resources consumed. Counts distinguish attempts from distinct entities. Hosts discovered after the first event increase totals; UI must not show a percentage based on a permanently fixed denominator. Network receipt is not validation completion.

The terminal summary has orthogonal fields, not one overloaded success flag:

| Field | Proposed values/meaning |
| --- | --- |
| `reason` | `settled`, `deadline`, `resource-limit`, `cancelled`, `superseded`, `fatal-local-error` |
| `availability` | `answered`, `partially-answered`, `unavailable`, `rejected`; host-empty and tracker-empty counts retained |
| `result` | `verified-results`, `answered-empty`, `no-qualifying-verified-results`, `invalid-evidence-only`, `no-answer` |
| `coverage` | discovery closure reason, observed/requested/settled/skipped host counts, limits hit, unresolved candidates; scope is this attempt only |
| `validationContext` | network/policy/chain epoch and snapshot validity status; no raw identity query in telemetry |

`answered-empty` means at least one host returned a structurally successful empty output list and no accepted outputs; it does not authenticate global absence. If hosts also supplied unusable evidence, retain those counts and show uncertainty. Trusted-certifier filters yielding nothing are `no-qualifying-verified-results`, not network outage. A deadline can accompany verified partial results or no answer. Existing throwing/final-array adapters preserve documented error identities while richer metadata is additive.

Normal completion requires discovery closed, all scheduled requests settled or cancelled, and all admitted validation/output queues drained or explicitly marked unresolved at a bound. `final` resolves exactly once with a summary, including cancellation; fatal construction/argument errors can reject before session creation. A consumer may stop iteration; `return()` detaches/cancels that consumer and settles its summary. Promise-only callers drain internally. No hidden endless work continues after ownership is released.

### 3.3 Identity and wallet boundary

Add optional progressive discovery capability interfaces alongside `WalletInterface`, followed by corresponding `IdentityClient` progressive methods. An example is `discoverByAttributesProgressive(args, originator, options)` returning events plus a final `DiscoverCertificatesResult`. Exact naming/capability negotiation must pass BRC-100/API review; do not change `discoverByAttributes` or `discoverByIdentityKey` into iterators, add unrecognized RPC fields, or bypass permission mediation with an app-side resolver.

For an in-process capable wallet, both final and progressive methods run the same argument validation, authentication, originator permission handling, trust-settings snapshot and identity validation. The permission layer must mediate the new capability explicitly before discovery or events start. Unsupported remote/browser wallet transports fall back to the existing authorized Promise method and report `progressMode: final-only`; a later negotiated wire extension is a separate compatibility-reviewed work package. A legacy wallet result without transaction evidence is marked `wallet-attested`, not independently verified by the app; the mandatory transaction fix must run inside supporting wallets. Acceptance of the primary UX requires an end-to-end progressive-capable wallet path, not only this fallback.

Each overlay identity record must pass transaction verification, output existence/script parsing, certificate/output field binding, decryption validation, certificate signature result `=== true`, trusted certifier filtering and the existing identity mapping rules before display. A false verdict and a thrown verification error both reject the candidate. Local contacts and user overrides retain their existing wallet policy and are marked `local-contact`/`local-override`; synthetic contact results cannot acquire an overlay-proof badge. Contact matching, trust-cache and result-cache behavior remain compatibility test cases.

Use immutable originator and trust-policy version in identity result cache keys. Shared public transaction verification may span consumers, but decrypted records, searches, permission results and trust-filtered results cannot cross identities/originators. Cached identity hits must carry/revalidate transaction and certificate/trust evidence; a prior two-minute result cache alone is insufficient after reorg or trust changes. Permission revocation/disposal cancels events immediately. Do not log name/email/phone/certificate contents.

Pagination remains service/wallet contract-specific. Preserve characterized current behavior for legacy `limit`, `offset`, result objects and total counts using compatibility fixtures; do not assume the toolbox overlay path conforms to interface pagination documentation, since it currently does not forward those validated fields. Any correction is a separately reviewed compatibility decision in W00/W02, not a silent side effect of progressive work. Progressive events show provisional verified candidates with a session-local stable sequence and outpoint key; they do not promise global sorted order or total count before settlement. A proposed progressive view keeps user selection keyed by identity/outpoint, adds verified candidates without disruptive reshuffling, and applies characterized service final ordering/window behavior at settlement. If an adapter cannot establish compatible pagination semantics, expose progress counters plus only a final page, explicitly `final-page-only`, rather than silently inventing global pagination. New lookup record framing/pagination is optional and cannot block cross-host progression.

The UI shows verified rows immediately, a subdued “Looking for more results” indicator while work continues, and an attempt-scoped terminal state. Empty and unavailable states differ. Typeahead creates a new generation, detaches the old one, and guards every awaited completion/callback by session ID and generation. An old query cannot update the new list, loading state, errors or final promise. A reorganization or trust change during a session produces an invalidation/removal update and revalidation; verified results are not irrevocably monotonic.

### 3.4 Ownership, backpressure and proposed tuning

Reference-count discovery, host requests and transaction jobs independently. One consumer cancelling never cancels work still owned by another. The last owner aborts fetch/parse/cooperative validation; a non-interruptible WASM operation runs only within its worker budget and its output is discarded if owner/context is gone. Completion callbacks are guarded even when an underlying library cannot abort. Bound and dispose idle worker pools at coordinator/application lifecycle boundaries; do not terminate a shared verifier per query.

Backpressure applies to bytes as well as item counts: cap in-flight HTTP response bytes, decoded BEEF bytes, graph nodes/depth, proof candidates per bound txid, output candidates and verification queue bytes. Enforce response byte limits while reading bodies even though parsing remains whole-response; `Content-Length` is only an early check. Worker queue saturation pauses new host scheduling, while tracker intake retains only a bounded normalized host set. Coalesce progress events and maintain a bounded current snapshot so a slow subscriber cannot accumulate unbounded deltas. A snapshot resynchronization/revision protocol must preserve result removals and the terminal event.

| Parameter | Proposal to measure, not accepted commitment | Resolution/gate |
| --- | --- | --- |
| Host/tracker request deadlines | Retain observed 2 s lookup / 5 s tracker defaults initially; permit explicit per-session tuning. | Delay/size cohorts; include queue wait separately from request time. |
| Whole attempt deadline | Initial 10 s experimental budget; never extends indefinitely when new hosts arrive. | Measure slow-region usefulness and abandonment; bounded final settlement tests. |
| Parallel host requests | Start benchmark sweep at 4, 8 and 16 per session plus global fairness limit. | Memory, bandwidth and first-useful latency under concurrent typeahead. |
| Verification workers | Benchmark 1/2/4, reuse verifast constraints and mobile fallback. | Frame responsiveness, cold/warm costs, peak memory, verdict parity. |
| Payload/graph/cache limits | No universal byte cap chosen yet; derive per runtime from measured valid large-ancestry and oversized-tx corpus before enabling. | Implementation cannot ship without documented finite defaults and resource-limit diagnostics; limits are operational acceptance limits, not consensus invalidity. |
| UX targets | Propose p95 first-useful overhead ≤100 ms after the first useful host response is fully received on the reference small confirmed cohort; no avoidable main-thread task >50 ms. | Ratify hardware/cohort and collect baseline distributions; this is not a network SLA. |

Use the existing temporary reputation/backoff behavior for never-finishing and unavailable peers. Current ordinary failures have a two-failure grace, then 1 s backoff doubling to 60 s; certain connection failures back off immediately and success clears it. Do not redesign it. Cancellation, queue overflow, local verification limits and semantic rejection must not masquerade as network failure. Cryptographic invalidity is a separate diagnostic dimension; a structurally healthy response is not cryptographic approval, and no new permanent host-ban rule is part of this plan.

## 4. Verification coordinator and trust model

### 4.1 Keys and candidate state

Intake first uses a bounded content digest of received evidence for cheap identical-byte suppression. That receipt key never suppresses a different proof bundle or establishes transaction identity. Parse with bounds, derive the target txid from immutable raw transaction bytes, compare any host hint, and reject a mismatch. Resolve output index against that transaction, not an untrusted hinted transaction. Different encodings/proof bundles for the same transaction remain separate evidence candidates until safely canonicalized.

The coordinator key is conceptually `(network/genesis, derivedTxid, verificationPolicyVersion, chainContext)`. It is transaction-scoped, not outpoint-scoped. Shared ancestor jobs use the same rules. Maintain a bounded candidate set and a single coordinating job per key; every output in that transaction subscribes to it. Verified-output keys add output index and service-validation context. Identical outpoints with conflicting untrusted context are not first-wins: validate each distinct context needed by the service, reject inconsistent binding, and keep provenance without overwriting valid data.

```text
received bytes → parsed/ID-bound candidate → pending evidence → verifying
                                               ↑                 ├→ verified
                                               └─ retryable ──────┤
                                                                 └→ candidate-invalid
verified → invalidated/stale → pending revalidation
```

Malformed serialization, an invalid Merkle proof or a host-ID mismatch invalidate that candidate. Missing ancestry, unavailable/stale headers, cancellation and a local budget limit do not permanently invalidate the transaction. Even an invalid script/transaction verdict must be scoped to immutable bytes and exact policy/consensus context; proof and header failures cannot be promoted to permanent txid negatives. Distinguish unavailable evidence from objectively invalid evidence.

If candidate A starts verification and B supplies additional/alternative evidence, attach B to the same job. On A's failure, try the best validly merged or alternate candidate under remaining budget. Do not resolve all subscribers as permanently failed merely because A's promise rejected. New sufficient evidence increments evidence generation and can restart a settled retryable job. Merge only matching raw transaction identities and compatible proof/header context; keep mutually conflicting paths separate. Bound repeated adversarial variants per txid with fair candidate replacement so a first-malformed flood cannot monopolize all slots. When bounded out, report unresolved work rather than global invalidity.

### 4.2 Positive verification and invalidation

For a confirmed transaction, derive its txid, validate Merkle-path structure and linkage to a canonical header at its claimed height with the independently maintained chain tracker. For an unconfirmed transaction, resolve and validate every necessary input edge, script/value rule and ancestor until valid canonical inclusion anchors terminate the graph. Existing SDK/BDK consensus context is authoritative; an optimization cannot replace graph verification with script-only verification or host assurance.

A positive cache entry includes network/genesis, raw-tx identity, policy/backend semantic version, proof/header dependencies `(height, blockHash/root)`, verified-at chain epoch and expiry/revalidation policy. A new canonical tip does not invalidate unrelated confirmed history automatically; a reorg invalidates affected anchors and dependent unconfirmed descendants, and in-flight results from an obsolete epoch are checked before publication. Unconfirmed script validity can be reused only with its dependency/context validity; absence of an observed conflicting spend is not unspentness proof. Policy or network changes use a new namespace. If a chain adapter cannot expose reliable epoch/invalidation events, recheck canonical dependencies before use and expire conservatively; never assume a height→root cache follows reorganizations automatically.

Cache transaction and certificate decisions separately. Certificate keys include canonical certificate bytes, verification mechanism/policy and relevant trust version. Trust-filter changes do not require repeating unchanged transaction scripts, but do require refiltering identities. Cache budgets are bounded LRU/byte budgets with explicit disposal; persistent caches must re-establish canonical context after restart. Do not cache remote-provided verification verdicts as local truth.

Use existing SDK `Transaction.verify` and verifast integration and measure its `true`/`false`/throw behavior at the adapter boundary. Batch only ready work up to a bounded delay; never hold the first useful result for a large batch. Batch/worker output indexes and contexts must be checked against submitted jobs. Selected backend failure stays a failure; do not silently retry with weaker semantics. Transfer or share immutable bytes deliberately, account for copying/EF expansion, and retain portable browser/mobile fallbacks without introducing mandatory cross-origin isolation.

## 5. Server persistence and synchronization contracts

[Mongo storage](mongo-storage.md) defines collection/index proposals, atomicity, large-blob publication, indexing, outbox, migration and recovery. Its required scope includes transaction/raw/BEEF/proof data, outputs and consumption edges, historical admissions, lookup indexes, SHIP/SLAP records, GASP cursors, BASM anchors/recovery and operational/ban metadata. Durable acknowledgment means the documented local commit contract is satisfied; it cannot claim propagation or index visibility that remains pending. Publication, durable admission and peer delivery are separate observable states.

[BASM recovery/status](basm-recovery-status.md) defines canonical validation, bounded historical repair, scheduling and per-topic status. The current BRC-136 construction uses canonical-order admitted transactions with empty root zero, singleton root txid and ordinary odd-leaf duplication. Neither obsolete sparse roots nor peer anchor equality alone is an independent admission oracle.

Storage and BASM fence two distinct dimensions: `chainEpoch` changes on canonical reorganization, while `topicHistoryGeneration` changes when historical admissions change even in the same canonical block. Immutable anchor revisions/comparisons include the latter; a current canonical pointer is conditional on both. A missing historical admission invalidates downstream TAC and old comparison evidence from that height before any green status can be reused. Progress cursors advance only with their durable corresponding work. Reorg invalidation and repaired history publication cannot expose a mixed generation. Peer failures must not abort unrelated topics/peers; retry leases, durable checkpoints and operator diagnostics make unfinished work visible. Lookup moderation remains distinct from historical admission retention. Mainnet/testnet/other configured chain namespaces cannot share anchors or proof cache authority.

Multi-page BASM reads require a consistent remote topic history: use negotiated snapshot tokens where supported, or bounded repeat-tip plus per-anchor validation on the existing protocol; same-height TAC changes matter as well as block hashes. A changed fence restarts the affected work before cursor advance or completion. Local-only valid admissions remain retained; repair can pull locally admissible missing records, offer reciprocal repair, or finish the bounded attempt with unresolved divergence/peer-behind evidence. A fresh single-peer match cannot hide another unresolved canonical mismatch, current storage failure, stale evidence or unfinished target lag in the topic badge.

## 6. Compatibility, release and completion

Secure the existing final identity path first so a progressive optimization is not the only protected route. Raw generic resolver contracts remain accurately labeled; the new verified interface is explicit. Ship interface additions, consumers and conformance fixtures before activating optional behavior. Maintain old HTTP responses, wallet Promise return shapes, SQL adapters and default deployment selection. A Mongo profile removes overlay-owned SQL requirements only; advertiser-wallet abstraction remains unchanged. Adapt configuration validation, examples, containers and health contracts together.

The [implementation plan](implementation-plan.md) supplies dependency lanes and review gates; [verification plan](verification-plan.md) supplies requirement acceptance tests and evidence ownership. The work is complete only when TS and Go implementations, identity UX, operator badges, selected-storage startup, migration rehearsal and fault/interop evidence satisfy those gates. Documentation and local source/test acceptance authorize no production cutover. Numeric tuning is resolved by checked-in measurements and implementation review, without reopening the confirmed product scope.
