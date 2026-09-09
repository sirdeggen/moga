# W00 frontend ownership inventory (read-only)

Date: 2026-09-08. No source files were modified. No secrets were read. The lead verified/corrected these bounded agent notes; the [consolidated W00 report](w00-go-ownership.md) carries the authoritative target recommendations and immutable upstream links.

## Repository status / authority

| Repo | Local ref / SHA | Remote and maintenance evidence | Scope result |
|---|---|---|---|
| `/Users/personal/git/ts/bsv-desktop` | `master`, `21061f3841640624245dfb14ad984422bd787e64`, tag `v2.8.4`; clean; authoritative remote `BSV-Desktop` HEAD is the same SHA | `BSV-Desktop` -> `https://github.com/bsv-blockchain/bsv-desktop.git`; latest observed upstream tag `v2.8.4`; `package.json` version 2.8.4 | Maintained source with real Electron UI consumers below; deployed/store behavior unverified |
| `/Users/personal/git/ts/bsv-browser` | `master`, `5a962a490d3328cf1a6e7478651777c36f8d8ab1`, tag `v1.6.1`; clean; authoritative GitHub default branch is `master` and HEAD is the same SHA | `origin` -> `https://github.com/bsv-blockchain/bsv-browser.git`; latest observed upstream tag `v1.6.1`; README calls it the mobile React Native + Expo browser | Maintained source; deployed/store behavior unverified; identity helper/CWI plumbing, no rendered identity typeahead consumer found |
| `/Users/personal/git/ts-stack` | `main`, `2bc799a8d8e535242e6de2d305f426ce3975ea7b`; clean; authoritative `origin` HEAD is the same SHA | `origin` -> `https://github.com/bsv-blockchain/ts-stack.git`; current monorepo; latest observed main SHA is the local SHA | Library ownership plus Overlay Express embedded UI; deployment unverified |
| `/Users/personal/git/go/go-overlay-discovery-services` | `master`, `5f208f0f6b561625626a9907f929fa4e9124a63f`; clean; stale local snapshot | Old local README notice is historical; active standalone current upstream/master `13038bbc6af613587dd95c2b06cecfa5c856fe13` and release v0.3.7 are pinned in the consolidated report | Go overlay services only; no HTML/TSX/frontend/operator UI found |
| `/Users/personal/Documents/ChatGPT/Identity` | empty Git repo, no HEAD | no authoritative remote or committed source | planning only; no ownership pointer found |
| `/Users/personal/Documents/ChatGPT/bsv-wallet` | empty Git repo, only untracked PRFAQ `.docx` files | no authoritative remote or committed source | planning only; excluded wallet-storage scope |

## Progressive IdentityClient / wallet C07 consumers

### Primary existing source consumer: bsv-desktop

`src/lib/pages/Dashboard/Payments/index.tsx:64-73` creates `useIdentitySearch({ originator, wallet, onIdentitySelected })`; the same screen renders the actual recipient `<Autocomplete>` at `:188-260` and writes the selected `identityKey` into `recipient`. This is the clearest maintained source consumer for C07 identity/wallet search behavior; deployed/store behavior is unverified.

`src/lib/pages/Dashboard/Payments/RequestPaymentForm.tsx:25,~130-140` imports and creates the same `useIdentitySearch` hook, and its recipient autocomplete is rendered around `:380-430`. It is a second rendered recipient search consumer.

`src/lib/pages/Dashboard/Payments/IncomingRequestList.tsx:29,~95-120` creates `whitelistIdentitySearch`; the whitelist identity autocomplete is rendered at `:306-329`. This is a rendered operator/user identity picker used to allow/block incoming payment request senders.

`src/lib/components/IdentitySearchField.tsx:1-100` is a reusable extracted search field backed by `@bsv/identity-react` `useIdentitySearch`. It is a library/component candidate, but `rg` did not find a current import/use of `IdentitySearchField`; treat it as available demo/reuse code, not the only live consumer.

`src/lib/components/CounterpartyChip/index.tsx:90-99` constructs `new IdentityClient(managers.permissionsManager, undefined, adminOriginator)` and calls `resolveByIdentityKey` for displayed counterparties, caching the display result in `window.localStorage` at `:70-96`. This is a real rendered identity-label/avatar consumer but does not do attribute typeahead.

`src/lib/pages/Dashboard/CounterpartyAccess/index.tsx:130-151` constructs `IdentityClient` and calls `resolveByIdentityKey` for the counterparty details page; `:194-196` has a second call in the trust placeholder path. This is a rendered dashboard identity detail consumer. The trust-fetch path is explicitly TODO/placeholder, so do not treat it as a complete operator feature.

`@bsv/identity-react` is a separate package from the BSV Blockchain Association repository [identity-react](https://github.com/bsv-blockchain/identity-react), whose verified master SHA is `c42f4a474330c3029c6671306b71828075a6c177`. Its source `src/utils/identityUtils.ts` calls the final Promise APIs `IdentityClient.resolveByIdentityKey` / `resolveByAttributes`; abort is implemented with `Promise.race`. Its `src/hooks/useIdentitySearch.ts` awaits `fetchIdentities`, uses a module-global `SearchCache` keyed by query with 5-minute/100-entry limits, and a 400ms timer. bsv-desktop imports `useIdentitySearch` in `src/lib/pages/Dashboard/Payments/index.tsx`, `RequestPaymentForm.tsx`, and `IncomingRequestList.tsx`. The source package version is `1.1.13`, while the desktop lockfile resolves npm `1.1.14` at `package-lock.json:1052`; provenance between that source checkout and the published lockfile artifact is unresolved.

Suggested exact C07 target boundary: first inspect or change `identity-react`'s `useIdentitySearch` API/package for progressive typeahead behavior, then update bsv-desktop's shared `src/lib/components/IdentitySearchField.tsx` and the three callers if needed. Preserve injected `wallet` and `originator`.

### bsv-browser: no rendered IdentityClient search consumer found

`utils/identity/resolveIdentity.ts:71-92` exports `resolveIdentity` (identity-key lookup) and `searchIdentities` (attribute lookup via `idClient.resolveByAttributes({ attributes: { any: text.trim() }, limit: 5, seekPermission: false })`); `:103-111` exports `makeIdentityClient`. These are reusable app helpers, but `rg` found no imports from app/components/context/hooks, so they are currently orphaned from a rendered picker.

`app/index.tsx:1398-1403` forwards CWI `discoverByIdentityKey` / `discoverByAttributes` calls. `utils/webview/cwiProvider.ts:17` lists those methods. This is wallet bridge plumbing for embedded web apps, not a native browser identity UI.

Suggested exact browser target only if product chooses browser ownership: add/locate the native screen component under `app/` or `components/` and wire `utils/identity/resolveIdentity.ts`; current evidence does not identify an existing contact-picker screen. Do not assume the browser helper is a live UI owner.

## SDK/library behavior relevant to C07

In the current root baseline `ts-stack/packages/sdk/src/identity/IdentityClient.ts`, `resolveByIdentityKey` and `resolveByAttributes` are final single-result Promise methods. Contacts are opt-in (`useContacts: true`) and short-circuit overlay lookup when a match exists, with optional `{ parallel: true }`; this is contacts precedence/caching, not a progressive streaming API. `packages/sdk/src/identity/ContactsManager.ts:40-115` reads the wallet `contacts` basket through `listOutputs`, decrypts records, and maintains an in-process cache. This is library behavior to consume from the desktop callers; it is not itself a UI.

## B05 operator per-topic UI

The maintained operator UI source is embedded in TypeScript `ts-stack/packages/overlays/overlay-express`; do not assign the existing B05 frontend to a Go backend-only repo. The actual hosted-topic UI is `src/makeUserInterface.ts:1112-1122`, which populates `manager_list` from `/listTopicManagers`, and markup `:1182-1184`, which renders the Topic Managers list. The admin overview’s hosted-topic summary is `:672-673` (`d.topicManagers.join(', ')`). `OverlayExpress.ts:1872-1881` serves it at `/`. The SHIP table `:680-742` is a secondary advertised-host/topic and health surface (`r.down`), not BASM topic agreement; `:744-806` is the analogous SLAP advertised-service table. Actual production deployment remains unverified.

`go-overlay-discovery-services` contains no HTML, React, Vue, Svelte, or other frontend source. Its Go `pkg/ship/*` code is backend discovery only and should not be selected as the B05 frontend owner.

The archived `go-stack` is not a maintained execution target. This source inventory identifies the TS frontend above; the generic Go backend has no equivalent per-topic console established here. Deployment ownership remains unverified.

## Unresolved consumer choices

1. C07 should likely land against bsv-desktop's three live `useIdentitySearch` callers and shared `IdentitySearchField`, but confirm whether the intended progressive behavior belongs in `@bsv/identity-react`, `@bsv/sdk` `IdentityClient`, or both.
2. bsv-browser has helper and CWI bridge code but no current native picker consumer; adding a UI there would be a new product surface rather than a direct ownership update.
3. B05 frontend ownership is the maintained `ts-stack/packages/overlays/overlay-express/src/makeUserInterface.ts` hosted-topic rows/summary plus `OverlayExpress.ts` serving path. The SHIP/SLAP tables are secondary advertised-host/service surfaces. Production deployment is still unverified. The Go repo remains backend-only for this question.
