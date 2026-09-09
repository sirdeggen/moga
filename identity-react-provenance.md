# identity-react 1.1.14 provenance — W00/C07

Verified 8 September 2026 by a bounded Luna review and independent lead checks. The source/package discrepancy is resolved for the C07 hook/helper baseline; C07 implementation, release and deployment remain unstarted by this work.

The official [npm 1.1.14 metadata](https://registry.npmjs.org/%40bsv%2Fidentity-react/1.1.14) names `gitHead` [`73c9ec8d0009fb716cfeff7b9af40112982af8d6`](https://github.com/bsv-blockchain/identity-react/commit/73c9ec8d0009fb716cfeff7b9af40112982af8d6). This commit exists upstream and is the direct child of inventoried `master` `c42f4a474330c3029c6671306b71828075a6c177`. Its [complete commit diff](https://github.com/bsv-blockchain/identity-react/commit/73c9ec8d0009fb716cfeff7b9af40112982af8d6) changes only `package.json` and `package-lock.json`: version 1.1.13 → 1.1.14, SDK dependency `^2.0.3` → `^2.0.4`, and UHRP React `^1.0.5` → `^1.0.6`, with corresponding lock entries. No 1.1.13/1.1.14 version tag was advertised; use the exact commit, not an inferred release tag or `master` manifest.

## Artifact and installed-byte identity

Desktop's [lockfile at `21061f3`](https://github.com/bsv-blockchain/bsv-desktop/blob/21061f3841640624245dfb14ad984422bd787e64/package-lock.json#L1052) resolves the official [1.1.14 tarball](https://registry.npmjs.org/@bsv/identity-react/-/identity-react-1.1.14.tgz). The downloaded 10,620-byte archive matches both npm digests and the Desktop lock SRI:

- SHA-256: `3669ec255194b7110290e0065d1917971c3f3596b0499bef2a267be331dd9793`
- npm SHA-1: `d17f294dd2e434bf9aa3c5303f00514187ff4f90`
- npm/Desktop SRI: `sha512-Wt6Z2OHe8ijklcNphz6SXxLOQZ1YiynP3YQLLsPsljnkVBIEtd1ArBQlGhEFgAM0wQ3WehtBVVcXPy15dzrypA==`

The existing `/Users/personal/git/ts/bsv-desktop/node_modules/@bsv/identity-react` manifest and these four files are byte-identical to the archive. The packed manifest also exactly matches the upstream `gitHead` manifest (SHA-256 `a45153e2dd0cd1e2d351a20544c0ac966b834e619ad8c513ddcd12ca4680e69a`).

| Released/installed file | SHA-256 |
| --- | --- |
| `dist/hooks/useIdentitySearch.js` | `9d5b5447d327d0e690ee5fd03e83caf2e0222abc54e9b4b588c91ee336d773d8` |
| `dist/utils/identityUtils.js` | `cf0386c800189b6ddca5e2d63906e2f8dd4a84716363a5b3a668dca2a7f15072` |
| `dist/types/hooks/useIdentitySearch.d.ts` | `f47cff6f44428caf2696e342f0249b2b753e8168b93fd101bb8aad824a879a41` |
| `dist/types/utils/identityUtils.d.ts` | `8e3301d6c143c191bdaaaa75b82c94a3d986d6d3d384e61df60924f342a51202` |

## Source comparison and implementation baseline

The pinned [`useIdentitySearch.ts`](https://github.com/bsv-blockchain/identity-react/blob/73c9ec8d0009fb716cfeff7b9af40112982af8d6/src/hooks/useIdentitySearch.ts) and [`identityUtils.ts`](https://github.com/bsv-blockchain/identity-react/blob/73c9ec8d0009fb716cfeff7b9af40112982af8d6/src/utils/identityUtils.ts) are byte-identical at `c42f4a4` and `73c9ec8`: their SHA-256 values are respectively `5c3ab575faac29d697311c683c0cb3a6805548eb878ec54800dd0cab47f97c9d` and `d49c364eb55e47c9088748e6f7d03db3f0253d98f464893b3f6508466597ad77`. In-memory `transpileModule` using Desktop's existing TypeScript 5.6.3 and the pinned repository `tsconfig.json` reproduces both released JavaScript files byte-for-byte. There are no hook/helper code differences to reconcile. The observed 400 ms timer, query-key cache, final-Promise APIs and abort race therefore also describe these installed files.

Use `73c9ec8d0009fb716cfeff7b9af40112982af8d6` as the explicit C07 source baseline and retain its manifest dependency changes. Review future hook changes against the frozen 1.1.14 bytes and test the selected SDK/Desktop integration before accepting a replacement artifact. This comparison covers two emitted JavaScript files, their source and installed declarations; it is not a complete package rebuild, dependency-behavior equivalence claim or publisher build attestation. The archive has no source maps, and npm `gitHead` alone would not prove emitted-byte provenance.

Only this note and links in the ownership report were changed. No package scripts, installations, app/source edits, dependency updates or publication were performed. All delegated inventory reviewers finished; the originating task owns acceptance.
