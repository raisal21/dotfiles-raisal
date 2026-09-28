import { execFile } from "node:child_process"
import { promisify } from "node:util"
import { Plugin } from "@opencode/plugin"

const execFileAsync = promisify(execFile)

// RTK OpenCode plugin — rewrites commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH.
//
// This is a thin delegating plugin: all rewrite logic lives in `rtk rewrite`,
// which is the single source of truth (src/discover/registry.rs).
// To add or change rewrite rules, edit the Rust registry — not this file.

export default Plugin.define({
  id: "raisal.rtk",
  async setup(ctx) {
    try {
      await execFileAsync("which", ["rtk"])
    } catch {
      console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
      return
    }

    await ctx.tool.hook("execute.before", async (event) => {
      if (event.tool !== "bash" && event.tool !== "shell") return
      if (!event.input || typeof event.input !== "object") return

      const input = event.input as { command?: unknown }
      if (typeof input.command !== "string" || !input.command) return

      try {
        const result = await execFileAsync("rtk", ["rewrite", input.command])
        const rewritten = String(result.stdout).trim()
        if (rewritten && rewritten !== input.command) {
          input.command = rewritten
        }
      } catch {
        // rtk rewrite failed — pass through unchanged
      }
    })
  },
})
