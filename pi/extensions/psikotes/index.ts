// Psychometric question-bank integration (job-hunting repo, question-generator-plan.md 6.11).
// Registers typed `bank_*` tools over the `bank` CLI and guards bank files against
// hand edits that would bypass verification. Everything is inert outside a repo
// that contains the question-tools project.
import { existsSync, readFileSync } from "node:fs"
import { join } from "node:path"
import { getAgentDir, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent"
import { Type } from "typebox"
import { checkBash, checkFileWrite, findRepo, type Decision, type Repo } from "./guards.ts"

type Config = {
  toolsDir: string
}

const DEFAULT_CONFIG: Config = { toolsDir: "documents/research/psychometric-tests/question-tools" }
const MAX_OUTPUT = 40_000
const BANK_TIMEOUT_MS = 300_000

function loadConfig(): Config {
  try {
    const raw = readFileSync(join(getAgentDir(), "extensions", "psikotes", "config.json"), "utf8")
    return { ...DEFAULT_CONFIG, ...(JSON.parse(raw) as Partial<Config>) }
  } catch {
    return DEFAULT_CONFIG
  }
}

const config = loadConfig()

function repoFor(cwd: string): Repo | undefined {
  return findRepo(cwd, config.toolsDir, existsSync)
}

function truncate(text: string): string {
  if (text.length <= MAX_OUTPUT) return text
  return `${text.slice(0, MAX_OUTPUT)}\n… dipotong ${text.length - MAX_OUTPUT} karakter; jalankan perintah bank lewat bash untuk output lengkap.`
}

export default function (pi: ExtensionAPI) {
  async function runBank(ctx: ExtensionContext, args: string[], signal: AbortSignal | undefined) {
    const repo = repoFor(ctx.cwd)
    if (!repo) {
      throw new Error(`Tidak ada ${config.toolsDir} di atas ${ctx.cwd}; tool bank hanya bekerja di repo job-hunting.`)
    }
    const result = await pi.exec("uv", ["run", "--project", repo.tools, "bank", "--json", ...args], {
      cwd: repo.root,
      timeout: BANK_TIMEOUT_MS,
      signal,
    })
    const output = result.stdout.trim()
    let parsed: unknown
    try {
      parsed = JSON.parse(output)
    } catch {
      throw new Error(`bank ${args[0]} gagal (exit ${result.code}): ${(result.stderr || output).trim()}`)
    }
    return {
      content: [{ type: "text" as const, text: truncate(output) }],
      details: { command: ["bank", ...args].join(" "), exitCode: result.code, result: parsed },
    }
  }

  pi.registerTool({
    name: "bank_report",
    label: "Bank report",
    description:
      "Coverage of the psychometric question bank: items per mechanism × level against the target, and status counts. Use before creating items to pick under-filled cells.",
    parameters: Type.Object({
      subtest: Type.Optional(Type.String({ description: "Subtest code or prefix, e.g. zr or ist-se" })),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      return runBank(ctx, ["report", ...(params.subtest ? ["--subtest", params.subtest] : [])], signal)
    },
  })

  pi.registerTool({
    name: "bank_taxonomy",
    label: "Bank taxonomy",
    description: "Valid facet values (mechanisms, content, distractors, radicals) for a subtest.",
    parameters: Type.Object({
      subtest: Type.Optional(Type.String({ description: "Subtest code or prefix" })),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      return runBank(ctx, ["taxonomy", ...(params.subtest ? ["--subtest", params.subtest] : [])], signal)
    },
  })

  pi.registerTool({
    name: "bank_next_id",
    label: "Bank next ID",
    description: "Next free item ID and file path for a subtest. Use it for every hand-written item.",
    parameters: Type.Object({ subtest: Type.String({ description: "Subtest code or prefix" }) }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      return runBank(ctx, ["next-id", params.subtest], signal)
    },
  })

  pi.registerTool({
    name: "bank_generate",
    label: "Bank generate",
    description:
      "Generate verified items for a subtest that has a generator (currently ZR). Without write it only previews. With write=true items are saved, verified, marked checked, and items.md is regenerated.",
    parameters: Type.Object({
      subtest: Type.String({ description: "Subtest code or prefix, e.g. zr" }),
      mechanism: Type.String({ description: "Mechanism code from bank_taxonomy" }),
      level: Type.Optional(Type.Integer({ minimum: 1, maximum: 3 })),
      n: Type.Optional(Type.Integer({ minimum: 1, maximum: 50, description: "Number of items (default 1)" })),
      seed: Type.Optional(Type.Integer({ minimum: 0 })),
      write: Type.Optional(Type.Boolean({ description: "Save and verify the items (default false)" })),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const args = ["generate", params.subtest, "--mechanism", params.mechanism]
      if (params.level !== undefined) args.push("--level", String(params.level))
      if (params.n !== undefined) args.push("--n", String(params.n))
      if (params.seed !== undefined) args.push("--seed", String(params.seed))
      if (params.write) args.push("--write")
      return runBank(ctx, args, signal)
    },
  })

  pi.registerTool({
    name: "bank_check",
    label: "Bank check",
    description:
      "Run the automatic verifier for item IDs or whole subtests and update checked/draft status. Subtests without a verifier are reported as skipped.",
    parameters: Type.Object({
      targets: Type.Optional(Type.Array(Type.String(), { description: "Item IDs or subtest codes" })),
      all: Type.Optional(Type.Boolean({ description: "Check every subtest that has a verifier" })),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const args = params.all ? ["check", "--all"] : ["check", ...(params.targets ?? [])]
      return runBank(ctx, args, signal)
    },
  })

  pi.registerTool({
    name: "bank_lint",
    label: "Bank lint",
    description: "Structural lint for every item. Run after writing or changing items; fix all errors.",
    parameters: Type.Object({}),
    async execute(_id, _params, signal, _onUpdate, ctx) {
      return runBank(ctx, ["lint"], signal)
    },
  })

  pi.registerTool({
    name: "bank_views",
    label: "Bank views",
    description: "Regenerate each subtest's items.md from its YAML item files.",
    parameters: Type.Object({}),
    async execute(_id, _params, signal, _onUpdate, ctx) {
      return runBank(ctx, ["views"], signal)
    },
  })

  pi.on("tool_call", async (event, ctx) => {
    const repo = repoFor(ctx.cwd)
    if (!repo) return undefined

    let decision: Decision = { action: "allow" }
    if (event.toolName === "write") {
      const input = event.input as { path: string; content: string }
      decision = checkFileWrite(repo, ctx.cwd, input.path, input.content)
    } else if (event.toolName === "edit") {
      const input = event.input as { path: string; edits: { newText: string }[] }
      decision = checkFileWrite(repo, ctx.cwd, input.path, input.edits.map((edit) => edit.newText).join("\n"))
    } else if (event.toolName === "bash") {
      decision = checkBash((event.input as { command: string }).command)
    }

    if (decision.action === "allow") return undefined
    if (decision.action === "confirm") {
      if (ctx.hasUI && (await ctx.ui.confirm("Izinkan perubahan?", decision.reason))) return undefined
      return { block: true, reason: `${decision.reason} Ditolak atau tidak ada UI untuk konfirmasi.` }
    }
    if (ctx.hasUI) ctx.ui.notify(`psikotes: ${decision.reason}`, "warning")
    return { block: true, reason: decision.reason }
  })
}
