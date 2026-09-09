# Local overlay validation

Prove the unmerged overlay branches together on this machine. Nothing here is a merge, npm publish, live migration, or Mongo/BASM default.

Stacked sources (not pushed):

- Go host worktree: `/Users/personal/git/go/worktrees/go-overlay-local` (`local/overlay-validation` = S04 admission + identity topic)
- Go SDK BEEF: `/Users/personal/git/go/worktrees/go-sdk-beef-compatibility`
- TS resolver: `/Users/personal/.codex/worktrees/22a2/ts-stack` (C04)

## Bring Mongo up

Docker Desktop:

```sh
docker compose -f local/docker-compose.yml up -d
```

Or a disposable local replica set (no Docker):

```sh
./local/mongo-rs.sh
```

## Run the host

```sh
cd /Users/personal/git/go/worktrees/go-overlay-local
go run ./examples/localhost
```

Listens on `http://127.0.0.1:18080/api/v1`.

## Smoke

```sh
./local/smoke.sh
```

## Optional public URL

Reserved domain:

```sh
ngrok http 18080 --url deggen.ngrok.app
```

Public origin: `https://deggen.ngrok.app/api/v1`. Browser clients may need the `ngrok-skip-browser-warning: true` header. SHIP/SLAP advertisement is not required for the first smoke: call `/lookup` directly.

## What this does not prove

C05 progressive API, wallet/UI (C06/C07), GASP, BASM recovery jobs, Atlas failover, or production activation. The chain tracker in the example always accepts roots and is local-only.
