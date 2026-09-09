# Planning review and verification record

As of 8 September 2026 this is a reviewed design draft for the originating task, not a production-ready implementation. Changes are Markdown files in this planning checkout only. Its Git HEAD is unborn; no commit/worktree initialization was performed to work around that unrelated setup. The source repositories and databases were not changed.

## Work performed

- Read the authoritative TS repository instructions, contribution/security guidance and relevant SDK/wallet/overlay documentation; inspected focal code paths rather than repeating an exhaustive repository audit.
- Verified TS baseline `2bc799a8d8e535242e6de2d305f426ce3975ea7b`; checked Go repository versions and pre-existing deletions are recorded in [source evidence](evidence-client-go.md). No deployment activation or private-fork inventory was attempted. Earlier originating-task inspection of upstream Go and go-stack is prior evidence, not a fresh exhaustive absence claim by this planning task.
- Used `gpt-5.6-luna` for source inventory/reference checking; `gpt-5.6-terra` for Mongo design and separately for BASM/operator design. Both design agents performed follow-up integration reviews. The lead retained security/architecture integration; the originating task independently reviewed the delivered drafts and source claims as they arrived. All assignments reached terminal completion.
- Delegated reviewers checked the current official [BRC-136](https://github.com/bsv-blockchain/BRCs/blob/master/overlays/0136.md), [MongoDB limits](https://www.mongodb.com/docs/manual/reference/limits/), [GridFS](https://www.mongodb.com/docs/manual/core/gridfs/) and [transaction considerations](https://www.mongodb.com/docs/manual/core/transactions-production-consideration/). These establish protocol/storage facts, not deployed behavior. W01 will pin a specification revision for executable conformance fixtures.
- Checked Markdown whitespace, local target existence and source line bounds, relative document links, requirement-to-task/test references and cross-document consistency. The final command outputs in this task are the validation record; no implementation test success is implied.

## Material corrections incorporated

| Review finding | Result in the design |
| --- | --- |
| Certificate return value versus concrete behavior | The parser ignores the boolean, but its built-in ProtoWallet throws on invalid signatures. Missing transaction/Merkle verification is the confirmed security gap; explicit certificate success remains a proposed contract. |
| Txid hints and first-wins merge | Any nonempty hint is currently accepted by the helper without byte binding. Trusted outpoint dedup follows independent verification; alternate proofs cannot be suppressed by a failed first candidate. |
| Wallet API and permission/pagination drift | Progressive capability is additive and mediated. Characterized legacy pagination and permission defaults are preserved pending focused review, rather than assumed to match interface prose. |
| Go adapter inventory | `OverlayGASPStorage` implements the GASP adapter, not engine Storage. No production engine adapter/BASM was found in the bounded inspected source paths; no universal or deployed absence claim. |
| BRC-136 version and incomplete repair | Use ordinary admitted-subset Merkle roots; complete bounded equal-height/local-ahead recovery. Retain local extras and report unresolved conflicts rather than deleting admissions to match a peer. |
| Anchor revisions without reorg | Separate chainEpoch and topicHistoryGeneration; late same-block admission invalidates downstream TAC/comparisons. Own repair advances its durable job/checkpoint; competing changes rewind. |
| Topic status and public protocol | Fresh mismatch/storage failure/target lag overrides a match. Redaction applies to status; ordinary protocol endpoints retain public txid/proof/raw payloads and cross-domain access. |
| Mongo acknowledgment/retry | Distinguish transient abort retries from unknown commit outcome reconciliation; separate admission ACK from external index visibility and peer propagation. Existing plugins need explicit replay/rebuild capability. |
| GridFS and shared ancestry | Publish bytes before transactional references; serialize GC live→deleting with reference creation. Decompose BEEF into shared transaction/proof references, including oversized individual transactions and scripts. |
| Cursor and rollback safety | Legacy GASP fallback requires proven tie-draining semantics or explicit limitation. SQL rollback requires all post-cutover acknowledged Mongo state replayed through a fenced cutoff, or zero Mongo-only acknowledged writes. |

## Not performed / implementation gates

No production code, tests, benchmarks, package builds, source-repository CI, database migration, live failover, deployment inspection, publication, push or communication to third parties occurred. Mongo driver/topology choices, finite payload/graph defaults, latency targets and work estimates remain proposals; they are resolved through W00/W01/W02 and the benchmark/failure evidence, not additional product clarification. The advertiser wallet remains excluded.

The originating task still owns final acceptance of this documentation. Future implementation must satisfy its own authoritative repository checks and the [verification plan](verification-plan.md). A passing documentation/link check cannot stand in for transaction, durability, interoperability or deployment evidence.
