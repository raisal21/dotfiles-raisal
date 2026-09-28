// Run with: node --test ~/dotfiles/pi/extensions/psikotes/launch.test.ts
// Uses a temporary copy of the bank through PSIKOTES_ROOT; never opens a browser.
import assert from "node:assert/strict"
import { cpSync, mkdtempSync, rmSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { test } from "node:test"
import { parseInventoryArgs, parseSessionArgs, startServer } from "./launch.ts"

const REPO = process.env.PSIKOTES_REPO ?? `${process.env.HOME}/workspace/job-hunting`
const PSY = join(REPO, "documents/research/psychometric-tests")

test("parseSessionArgs builds bank session arguments", () => {
  assert.deepEqual(parseSessionArgs("zr").args, ["session", "zr", "--mode", "ujian"])
  assert.deepEqual(parseSessionArgs("se latihan 10 --draft").args, ["session", "se", "--mode", "latihan", "--n", "10", "--draft"])
  assert.deepEqual(parseSessionArgs("zr latihan 4 --mekanisme beda-progresif").args, [
    "session", "zr", "--mode", "latihan", "--n", "4", "--mechanism", "beda-progresif",
  ])
  assert.deepEqual(parseSessionArgs("--mekanisme rasio-tetap zr --draft").args, [
    "session", "zr", "--mode", "ujian", "--mechanism", "rasio-tetap", "--draft",
  ])
  assert.ok(parseSessionArgs("zr --mekanisme").error)
  assert.ok(parseSessionArgs("").error)
})

test("startServer reports ready and finished events", { timeout: 60_000 }, async () => {
  const root = mkdtempSync(join(tmpdir(), "psikotes-"))
  cpSync(join(PSY, "ist-question-bank"), join(root, "ist-question-bank"), { recursive: true })
  process.env.PSIKOTES_ROOT = root
  try {
    let url = ""
    const server = startServer(join(PSY, "question-tools"), REPO, ["review", "zr"], (ready) => (url = String(ready.url)))
    while (!url) await new Promise((resolve) => setTimeout(resolve, 100))
    const items = await (await fetch(`${url}api/items`)).json()
    assert.equal(items.items.length > 0, true)
    await fetch(`${url}api/close`, { method: "POST", headers: { "Content-Type": "application/json" }, body: "{}" })
    const result = await server.done
    assert.equal(result.code, 0)
    assert.equal(result.finished?.event, "finished")
  } finally {
    delete process.env.PSIKOTES_ROOT
    rmSync(root, { recursive: true, force: true })
  }
})

test("parseInventoryArgs builds the inventory session command", () => {
  assert.deepEqual(parseInventoryArgs("epps").args, ["inventory", "session", "epps"])
  assert.deepEqual(parseInventoryArgs("papi pendek --pratinjau").args, ["inventory", "session", "papi", "--pendek", "--pratinjau"])
  assert.ok(parseInventoryArgs("").error)
  assert.ok(parseInventoryArgs("epps 30").error)
})
