// Run with: node --test ~/dotfiles/pi/extensions/psikotes/guards.test.ts
import assert from "node:assert/strict"
import { test } from "node:test"
import { checkBash, checkFileWrite, findRepo, type Repo } from "./guards.ts"

const repo: Repo = {
  root: "/r",
  tools: "/r/documents/research/psychometric-tests/question-tools",
  psychometric: "/r/documents/research/psychometric-tests",
}
const bank = "/r/documents/research/psychometric-tests/ist-question-bank"

test("findRepo walks up to the tools project", () => {
  const found = findRepo(`${bank}/06-zr`, "documents/research/psychometric-tests/question-tools", (p) =>
    p === `${repo.tools}/pyproject.toml`,
  )
  assert.deepEqual(found, repo)
  assert.equal(findRepo("/elsewhere", "x", () => false), undefined)
})

test("generator-only items are blocked", () => {
  assert.equal(checkFileWrite(repo, "/r", `${bank}/06-zr/items/ZR-030.yaml`, "id: ZR-030").action, "block")
})

test("verbal items may be written as draft", () => {
  assert.equal(checkFileWrite(repo, "/r", `${bank}/01-se/items/SE-025.yaml`, "status: draft\n").action, "allow")
})

test("agents cannot mark items checked or reviewed", () => {
  for (const text of ["status: reviewed\n", "id: x\nstatus: checked\n", "verification:\n  verifier: x\n"]) {
    assert.equal(checkFileWrite(repo, "/r", `${bank}/02-wa/items/WA-030.yaml`, text).action, "block")
  }
})

test("relative paths resolve against cwd", () => {
  assert.equal(checkFileWrite(repo, `${bank}/06-zr`, "items/ZR-001.yaml", "").action, "block")
})

test("sessions, tombstones, and generated views are protected; taxonomy needs confirmation", () => {
  const psy = repo.psychometric
  assert.equal(checkFileWrite(repo, "/r", `${psy}/sessions/2026-10-01.json`, "{}").action, "block")
  assert.equal(checkFileWrite(repo, "/r", `${bank}/id-tombstones.yaml`, "").action, "block")
  assert.equal(checkFileWrite(repo, "/r", `${bank}/01-se/items.md`, "").action, "block")
  assert.equal(checkFileWrite(repo, "/r", `${repo.tools}/taxonomy/ist.yaml`, "").action, "confirm")
  assert.equal(checkFileWrite(repo, "/r", "/r/README.md", "").action, "allow")
})

test("shell writes to bank files are blocked, reads and the bank CLI are allowed", () => {
  const blocked = [
    "sed -i 's/draft/reviewed/' documents/research/psychometric-tests/ist-question-bank/02-wa/items/WA-001.yaml",
    "echo x > items/ZR-001.yaml",
    "rm -rf documents/research/psychometric-tests/sessions/",
    "python3 fix.py documents/research/psychometric-tests/ist-question-bank/06-zr/items/ZR-002.yaml",
  ]
  for (const command of blocked) assert.equal(checkBash(command).action, "block", command)

  const allowed = [
    "cat documents/research/psychometric-tests/ist-question-bank/06-zr/items/ZR-001.yaml",
    "grep -rn status ist-question-bank/01-se/items/ 2>&1 | head",
    "uv run --project documents/research/psychometric-tests/question-tools bank check zr",
    "rtk uv run bank generate zr --mechanism komposit --write",
    "git diff -- documents/research/psychometric-tests/ist-question-bank",
    "ls -la",
  ]
  for (const command of allowed) assert.equal(checkBash(command).action, "allow", command)
})

test("figures are rendered, never hand-edited", () => {
  assert.equal(checkFileWrite(repo, "/r", `${bank}/08-wu/figures/WU-015.svg`, "<svg/>").action, "block")
  assert.equal(checkBash(`sed -i s/a/b/ ${bank}/08-wu/figures/WU-015.svg`).action, "block")
  assert.equal(checkBash("uv run --project q bank render wu").action, "allow")
})
