// Pure guard rules for the psikotes extension. No pi imports, so `node --test`
// can exercise them directly (see guards.test.ts).
import { dirname, isAbsolute, join, relative, resolve, sep } from "node:path"

export type Repo = {
  root: string
  tools: string
  psychometric: string
}

export type Decision =
  | { action: "allow" }
  | { action: "block"; reason: string }
  | { action: "confirm"; reason: string }

const ALLOW: Decision = { action: "allow" }

// Subtest folders whose items only a generator may write (plan: V3, key never hand-written).
const GENERATOR_ONLY = new Set(["06-zr", "07-fa", "08-wu"])

export function findRepo(start: string, toolsDir: string, exists: (path: string) => boolean): Repo | undefined {
  let dir = resolve(start)
  while (true) {
    const tools = join(dir, toolsDir)
    if (exists(join(tools, "pyproject.toml"))) {
      return { root: dir, tools, psychometric: dirname(tools) }
    }
    const parent = dirname(dir)
    if (parent === dir) return undefined
    dir = parent
  }
}

function withinPsychometric(repo: Repo, cwd: string, path: string): string | undefined {
  const absolute = isAbsolute(path) ? path : resolve(cwd, path)
  const rel = relative(repo.psychometric, absolute)
  if (rel.startsWith("..") || isAbsolute(rel)) return undefined
  return rel.split(sep).join("/")
}

const STATUS_OR_VERIFICATION = /^\s*(status:\s*(checked|reviewed)\b|verification:|content_hash:)/m

export function checkFileWrite(repo: Repo, cwd: string, path: string, newText: string): Decision {
  const rel = withinPsychometric(repo, cwd, path)
  if (rel === undefined) return ALLOW
  if (rel.startsWith("sessions/")) {
    return { action: "block", reason: "Hasil sesi hanya ditulis aplikasi sesi; agent tidak boleh mengubahnya." }
  }
  if (/^question-tools\/taxonomy\//.test(rel)) {
    return { action: "confirm", reason: `Agent ingin mengubah taksonomi (${rel}). Nilai yang sudah dipakai tidak boleh dihapus.` }
  }
  if (/^[a-z]+-question-bank\/id-tombstones\.yaml$/.test(rel)) {
    return { action: "block", reason: "Daftar ID yang dihapus hanya diubah user." }
  }
  if (/^[a-z]+-question-bank\/[^/]+\/items\.md$/.test(rel)) {
    return { action: "block", reason: "items.md dibangkitkan dari YAML. Ubah items/*.yaml, lalu jalankan bank_views." }
  }
  if (/^[a-z]+-question-bank\/[^/]+\/figures\//.test(rel)) {
    return { action: "block", reason: "Gambar dibangkitkan dari spec. Ubah lewat bank_generate, lalu bank_render; jangan edit SVG atau PNG." }
  }
  const item = rel.match(/^([a-z]+)-question-bank\/([^/]+)\/items\/[^/]+\.yaml$/)
  if (!item) return ALLOW
  if (item[1] === "cfit" || (item[1] === "ist" && GENERATOR_ONLY.has(item[2]))) {
    return { action: "block", reason: `Soal ${item[2]} hanya dibuat dan diubah lewat bank_generate dan bank_check.` }
  }
  if (STATUS_OR_VERIFICATION.test(newText)) {
    return {
      action: "block",
      reason: "Status checked hanya dari bank_check, reviewed hanya dari user, dan blok verification tidak ditulis tangan.",
    }
  }
  return ALLOW
}

const PROTECTED_IN_BASH =
  /(question-bank\/[^\s'"]*(items|figures)[/.\s'"]|(^|[\s'"/])items\/[A-Z]{2}-\d{3}\.yaml|id-tombstones\.yaml|question-tools\/taxonomy\/|psychometric-tests\/sessions\/)/
const WRITES_IN_BASH =
  /(^|[\s;&|(])(sed\s+(-[a-zA-Z]*\s+)*-i|perl\s+-[a-zA-Z]*i|tee|mv|cp|rm|truncate|dd|install|touch|python3?|node|ruby|yq\s+-i)\b|(^|[^\d&=<>-])>{1,2}(?!&)/
const BANK_CLI = /^\s*(rtk\s+(proxy\s+)?)?uv\s+run\b[^;&|]*\bbank\b[^;&|>]*$/

export function checkBash(command: string): Decision {
  if (!PROTECTED_IN_BASH.test(command) || !WRITES_IN_BASH.test(command)) return ALLOW
  if (BANK_CLI.test(command)) return ALLOW
  return {
    action: "block",
    reason:
      "Perintah shell ini menulis ke berkas bank soal, sesi, atau taksonomi. Pakai tool bank_* atau write/edit supaya aturan status dan kunci bisa diperiksa.",
  }
}
