import { readFileSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import {
  getAgentDir,
  type ExtensionAPI,
  type ExtensionContext,
  type ProjectTrustEventResult,
} from "@earendil-works/pi-coding-agent"

type PermissionMode = "auto" | "ask"

type PersistedState = {
  mode?: PermissionMode
}

const STATE_FILE = join(getAgentDir(), "auto-allow.json")
const DEFAULT_MODE: PermissionMode = "auto"
const READ_ONLY_TOOLS = new Set(["read", "grep", "find", "ls"])
const MAX_PREVIEW_LENGTH = 4_000

let mode = loadMode()

function loadMode(): PermissionMode {
  try {
    const parsed = JSON.parse(readFileSync(STATE_FILE, "utf8")) as PersistedState
    return parsed.mode === "ask" ? "ask" : "auto"
  } catch {
    return DEFAULT_MODE
  }
}

function saveMode(next: PermissionMode): string | undefined {
  try {
    writeFileSync(STATE_FILE, `${JSON.stringify({ mode: next }, null, 2)}\n`, "utf8")
    return undefined
  } catch (error) {
    return error instanceof Error ? error.message : String(error)
  }
}

function updateStatus(ctx: ExtensionContext) {
  ctx.ui.setStatus("auto-allow", mode === "auto" ? "permissions: auto" : "permissions: ask")
}

function setMode(next: PermissionMode, ctx: ExtensionContext) {
  mode = next
  const error = saveMode(next)
  updateStatus(ctx)
  if (error) {
    ctx.ui.notify(`Mode changed for this session, but could not save ${STATE_FILE}: ${error}`, "warning")
  }
}

function previewInput(input: unknown): string {
  let preview: string
  try {
    preview = JSON.stringify(input, null, 2) ?? String(input)
  } catch {
    preview = String(input)
  }

  if (preview.length <= MAX_PREVIEW_LENGTH) return preview
  return `${preview.slice(0, MAX_PREVIEW_LENGTH)}\n… [truncated]`
}

function isMode(value: string): value is PermissionMode {
  return value === "auto" || value === "ask"
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("auto-allow", {
    description: "Toggle automatic tool/project permission approval",
    getArgumentCompletions: (prefix) => {
      const values = ["on", "off", "status", "toggle"]
      const matches = values
        .filter((value) => value.startsWith(prefix.toLowerCase()))
        .map((value) => ({ value, label: value }))
      return matches.length > 0 ? matches : null
    },
    handler: async (args, ctx) => {
      const value = args.trim().toLowerCase()

      if (value === "status" || value === "") {
        ctx.ui.notify(`Auto-allow is ${mode === "auto" ? "ON" : "OFF (ask before tools)"}.`, "info")
        updateStatus(ctx)
        return
      }

      const next = value === "toggle" ? (mode === "auto" ? "ask" : "auto") : value === "on" ? "auto" : value === "off" ? "ask" : undefined
      if (!next || !isMode(next)) {
        ctx.ui.notify("Usage: /auto-allow on|off|toggle|status", "warning")
        return
      }

      setMode(next, ctx)
      ctx.ui.notify(`Auto-allow ${next === "auto" ? "ON" : "OFF — tool calls now require approval"}.`, "info")
    },
  })

  pi.registerShortcut("ctrl+shift+a", {
    description: "Toggle auto-allow mode",
    handler: async (ctx) => {
      const next: PermissionMode = mode === "auto" ? "ask" : "auto"
      setMode(next, ctx)
      ctx.ui.notify(`Auto-allow ${next === "auto" ? "ON" : "OFF — tool calls now require approval"}.`, "info")
    },
  })

  pi.on("session_start", (_event, ctx) => {
    updateStatus(ctx)
  })

  // Project trust is resolved before project-local resources load, so this
  // global extension can toggle the built-in project trust prompt as well.
  pi.on("project_trust", async (_event, _ctx): Promise<ProjectTrustEventResult> => {
    if (mode === "auto") return { trusted: "yes" }
    return { trusted: "undecided" }
  })

  pi.on("tool_call", async (event, ctx) => {
    if (mode === "auto" || READ_ONLY_TOOLS.has(event.toolName)) return

    if (!ctx.hasUI) {
      return {
        block: true,
        reason: `Blocked: auto-allow is OFF and no UI is available to approve ${event.toolName}`,
      }
    }

    const allowed = await ctx.ui.confirm(
      `Allow tool: ${event.toolName}?`,
      previewInput(event.input),
    )
    if (!allowed) {
      return { block: true, reason: `Blocked by user: ${event.toolName}` }
    }
  })
}
