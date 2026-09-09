#!/usr/bin/env node
// Minimal TS-shaped overlay client against a local or ngrok host.
const base = (process.env.OVERLAY_BASE_URL || 'http://127.0.0.1:18080/api/v1').replace(/\/$/, '')
const identityKey =
  process.env.OVERLAY_IDENTITY_KEY ||
  '02aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'

const question = { service: 'ls_identity', query: { identityKey, limit: 1 } }

const res = await fetch(`${base}/lookup`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(question)
})
if (!res.ok) {
  throw new Error(`lookup ${res.status}: ${await res.text()}`)
}
const body = await res.json()
console.log(JSON.stringify({ base, question, body }, null, 2))
if (body.type !== 'output-list') {
  throw new Error(`expected output-list, got ${body.type}`)
}
console.log('OK: Node client received an output-list from the local Go host')
