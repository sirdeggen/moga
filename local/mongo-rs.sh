#!/bin/sh
# Disposable single-member Mongo replica set on :27017 for local overlay validation.
set -eu
DIR=${OVERLAY_MONGO_DIR:-/tmp/overlay-mongo-rs}
PORT=${OVERLAY_MONGO_PORT:-27017}
mkdir -p "$DIR"
if ! pgrep -f "mongod.*--port $PORT" >/dev/null 2>&1; then
  mongod --replSet rs0 --port "$PORT" --bind_ip 127.0.0.1 --dbpath "$DIR" --fork --logpath "$DIR/mongod.log"
fi
for i in 1 2 3 4 5 6 7 8 9 10; do
  if mongosh --quiet --port "$PORT" --eval 'db.runCommand({ping:1}).ok' >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done
mongosh --quiet --port "$PORT" --eval 'try { rs.status().ok } catch (e) { rs.initiate({_id:"rs0", members:[{_id:0, host:"127.0.0.1:'"$PORT"'"}]}) }' >/dev/null
echo "mongo replicaSet rs0 on 127.0.0.1:$PORT"
