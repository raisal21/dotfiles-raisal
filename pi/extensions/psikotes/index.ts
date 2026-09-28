// Psychometric question-bank integration (job-hunting repo, question-generator-plan.md 6.11).
// Registers typed `bank_*` tools over the `bank` CLI and guards bank files against
// hand edits that would bypass verification. Everything is inert outside a repo
// that contains the question-tools project.
import { existsSync, readFileSync } from "node:fs"
import { join } from "node:path"
import {
  getAgentDir,
  type ExtensionAPI,
  type ExtensionCommandContext,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent"
import { Type } from "typebox"
import { checkBash, checkFileWrite, findRepo, type Decision, type Repo } from "./guards.ts"
import { openBrowser, parseSessionArgs, SESSION_USAGE, startServer, type LaunchConfig, type Server } from "./launch.ts"

type Config = {
  toolsDir: string
  browser: LaunchConfig
}

const DEFAULT_CONFIG: Config = {
  toolsDir: "documents/research/psychometric-tests/question-tools",
  browser: {
    session: {
      type: "chrome-app",
      path: "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe",
      profileDir: "psikotes\\chrome-profile",
      windowSize: "1100,860",
    },
    review: { type: "default" },
    dashboard: { type: "default" },
  },
}
const MAX_OUTPUT = 40_000
const BANK_TIMEOUT_MS = 300_000

function loadConfig(): Config {
  try {
    const raw = readFileSync(join(getAgentDir(), "extensions", "psikotes", "config.json"), "utf8")
    const loaded = JSON.parse(raw) as Partial<Config>
    return { ...DEFAULT_CONFIG, ...loaded, browser: { ...DEFAULT_CONFIG.browser, ...loaded.browser } }
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
  // One local server at a time: a practice session or a review page.
  let active: { kind: string; server: Server } | undefined

  function stopActive() {
    if (active && active.server.child.exitCode === null) active.server.child.kill("SIGINT")
    active = undefined
  }

  // The dashboard is separate: it may stay open next to a session, and stops itself when idle.
  let dashboard: { server: Server; url?: string } | undefined

  function stopDashboard() {
    if (dashboard && dashboard.server.child.exitCode === null) dashboard.server.child.kill("SIGINT")
    dashboard = undefined
  }

  pi.on("session_shutdown", () => {
    stopActive()
    stopDashboard()
  })

  async function launch(
    ctx: ExtensionCommandContext,
    kind: "latihan" | "review",
    args: string[],
    after: (finished: Record<string, unknown> | undefined) => Promise<void>,
  ) {
    const repo = repoFor(ctx.cwd)
    if (!repo) {
      ctx.ui.notify(`Perintah ini hanya bekerja di repo yang punya ${config.toolsDir}.`, "warning")
      return
    }
    if (active) {
      ctx.ui.notify(`Masih ada ${active.kind} yang berjalan. Tutup dulu dari browser.`, "warning")
      return
    }
    const browser = kind === "latihan" ? config.browser.session : config.browser.review
    const server = startServer(repo.tools, repo.root, args, (ready) => {
      void openBrowser(String(ready.url), browser).then((where) => {
        ctx.ui.setStatus("psikotes", `${kind} berjalan`)
        ctx.ui.notify(`${kind === "latihan" ? "Sesi" : "Halaman review"} dibuka di ${where}: ${ready.url}`, "info")
      })
    })
    active = { kind, server }
    const result = await server.done
    active = undefined
    ctx.ui.setStatus("psikotes", undefined)
    if (result.code !== 0) {
      ctx.ui.notify(`bank ${args[0]} berhenti dengan kode ${result.code}: ${result.stderr.trim().split("\n").slice(-3).join(" ")}`, "error")
      return
    }
    await after(result.finished)
  }

  pi.registerCommand("latihan", {
    description: `Sesi latihan psikotes di browser. ${SESSION_USAGE}`,
    handler: async (raw, ctx) => {
      const { args, error } = parseSessionArgs(raw)
      if (error) {
        ctx.ui.notify(error, "warning")
        return
      }
      void launch(ctx, "latihan", args, async (finished) => {
        if (!finished || finished.event === "discarded") {
          ctx.ui.notify("Sesi ditutup sebelum dimulai; tidak ada yang disimpan.", "info")
          return
        }
        const score = finished.score as { raw: number; max: number; not_reached: number } | undefined
        const line = score
          ? `${finished.subtest_name}: ${score.raw} dari ${score.max} poin, ${score.not_reached} tidak sempat.`
          : `Sesi ${finished.id} selesai.`
        ctx.ui.notify(line, "info")
        if (ctx.hasUI && (await ctx.ui.confirm("Debrief sekarang?", line))) {
          pi.sendUserMessage(`/debrief ${finished.id}`, { expandPromptTemplates: true })
        }
      })
    },
  })

  pi.registerCommand("review-soal", {
    description: "Tinjau soal checked di browser: /review-soal [subtes ...]",
    handler: async (raw, ctx) => {
      const subtests = raw.trim().split(/\s+/).filter(Boolean)
      void launch(ctx, "review", ["review", ...subtests], async (finished) => {
        const decisions = (finished?.decisions as { id: string; status: string }[] | undefined) ?? []
        ctx.ui.notify(
          decisions.length ? `${decisions.length} keputusan: ${decisions.map((d) => `${d.id} ${d.status}`).join(", ")}` : "Tidak ada keputusan.",
          "info",
        )
      })
    },
  })

  pi.registerCommand("dashboard", {
    description: "Rekap kemajuan psikotes di browser: /dashboard [stop]",
    handler: async (raw, ctx) => {
      if (raw.trim() === "stop") {
        ctx.ui.notify(dashboard ? "Dashboard dihentikan." : "Dashboard tidak sedang berjalan.", "info")
        stopDashboard()
        return
      }
      const repo = repoFor(ctx.cwd)
      if (!repo) {
        ctx.ui.notify(`Perintah ini hanya bekerja di repo yang punya ${config.toolsDir}.`, "warning")
        return
      }
      if (dashboard?.url) {
        const where = await openBrowser(dashboard.url, config.browser.dashboard)
        ctx.ui.notify(`Dashboard sudah berjalan; dibuka lagi di ${where}: ${dashboard.url}`, "info")
        return
      }
      if (dashboard) return
      const current: { server: Server; url?: string } = {
        server: startServer(repo.tools, repo.root, ["dashboard"], (ready) => {
          current.url = String(ready.url)
          void openBrowser(current.url, config.browser.dashboard).then((where) =>
            ctx.ui.notify(`Dashboard dibuka di ${where}: ${current.url}. Hentikan dengan /dashboard stop.`, "info"),
          )
        }),
      }
      dashboard = current
      void current.server.done.then((result) => {
        // After /dashboard stop the slot is already cleared; the exit code then means nothing.
        if (dashboard !== current) return
        dashboard = undefined
        if (result.code !== 0) {
          ctx.ui.notify(`bank dashboard berhenti dengan kode ${result.code}: ${result.stderr.trim().split("\n").slice(-3).join(" ")}`, "error")
        }
      })
    },
  })

  pi.registerTool({
    name: "bank_dashboard_data",
    label: "Bank dashboard data",
    description:
      "Practice recap computed from all sessions: the recommended next practice (with the exact /latihan command), alternatives, restock notes, problem items, and thresholds. Without `subtest` it returns per-subtest status counts only; pass a subtest for per-mechanism accuracy, 95% intervals, mastery checks, session history, and mistake patterns.",
    parameters: Type.Object({
      subtest: Type.Optional(Type.String({ description: "Subtest code or prefix for full detail, e.g. zr" })),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const scope = params.subtest ? ["--subtest", params.subtest] : ["--brief"]
      return runBank(ctx, ["dashboard", "--data", ...scope], signal)
    },
  })

  pi.registerTool({
    name: "bank_session_result",
    label: "Bank session result",
    description:
      "Summary of a practice session: score, per-mechanism counts, and every mistake with the chosen distractor, the user's reason, and the key. Use for debriefs; `latest` by default.",
    parameters: Type.Object({
      session: Type.Optional(Type.String({ description: "Session ID or latest" })),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      return runBank(ctx, ["session-result", params.session ?? "latest"], signal)
    },
  })

  pi.registerTool({
    name: "bank_session_grade",
    label: "Bank session grade",
    description:
      "Record the score for an answer that is pending grading (GE free text). Propose the score to the user first; the tool asks the user to confirm before writing.",
    parameters: Type.Object({
      session: Type.String({ description: "Session ID" }),
      position: Type.Integer({ minimum: 1 }),
      score: Type.Integer({ minimum: 0, maximum: 2 }),
      reason: Type.String({ description: "Why this score, in one sentence" }),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const question = `Catat nilai ${params.score} untuk soal ${params.position} sesi ${params.session}?`
      if (!ctx.hasUI || !(await ctx.ui.confirm(question, params.reason))) {
        throw new Error("Nilai tidak dicatat: user tidak menyetujui atau tidak ada UI.")
      }
      return runBank(ctx, ["session-grade", params.session, String(params.position), String(params.score)], signal)
    },
  })

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
      "Generate verified items for a subtest that has a generator (ZR, WU). Without write it only previews. With write=true items are saved, verified, marked checked, figures are rendered (WU), and items.md is regenerated. ZR needs a mechanism. WU without a mechanism builds an exam-like mix; each WU call makes a new set of five reference cubes unless `set` names an existing one.",
    parameters: Type.Object({
      subtest: Type.String({ description: "Subtest code or prefix, e.g. zr or wu" }),
      mechanism: Type.Optional(Type.String({ description: "Mechanism code from bank_taxonomy (required for ZR)" })),
      level: Type.Optional(Type.Integer({ minimum: 1, maximum: 3 })),
      n: Type.Optional(Type.Integer({ minimum: 1, maximum: 50, description: "Number of items (default 1)" })),
      seed: Type.Optional(Type.Integer({ minimum: 0 })),
      set: Type.Optional(Type.String({ description: "WU only: add to an existing set, e.g. WU-S01" })),
      write: Type.Optional(Type.Boolean({ description: "Save and verify the items (default false)" })),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const args = ["generate", params.subtest]
      if (params.mechanism) args.push("--mechanism", params.mechanism)
      if (params.level !== undefined) args.push("--level", String(params.level))
      if (params.n !== undefined) args.push("--n", String(params.n))
      if (params.seed !== undefined) args.push("--seed", String(params.seed))
      if (params.set) args.push("--set", params.set)
      if (params.write) args.push("--write")
      return runBank(ctx, args, signal)
    },
  })

  pi.registerTool({
    name: "bank_render",
    label: "Bank render",
    description:
      "Re-render the SVG and PNG figures of figural items (WU) from their spec. Use after changing a spec, or to get a PNG to look at; never edit figures by hand.",
    parameters: Type.Object({
      targets: Type.Optional(Type.Array(Type.String(), { description: "Item IDs or subtest codes (default: all figural subtests)" })),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      return runBank(ctx, ["render", ...(params.targets ?? [])], signal)
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
