// Starting the local `bank session` / `bank review` servers and the browser (plan 6.8, D17).
import { spawn, type ChildProcess } from "node:child_process"
import { existsSync } from "node:fs"
import { createInterface } from "node:readline"

export type BrowserConfig =
  | { type: "chrome-app"; path: string; profileDir: string; windowSize?: string }
  | { type: "default" }

export type LaunchConfig = {
  session: BrowserConfig
  review: BrowserConfig
}

export type BankEvent = { event: string; [key: string]: unknown }

export type Server = {
  child: ChildProcess
  done: Promise<{ code: number | null; finished?: BankEvent; stderr: string }>
}

// Resolved once: C:\Users\<name>\AppData\Local, used for the Chrome profile outside dotfiles.
let localAppData: Promise<string | undefined> | undefined

function windowsLocalAppData(): Promise<string | undefined> {
  localAppData ??= new Promise((resolve) => {
    const child = spawn("cmd.exe", ["/c", "echo %LOCALAPPDATA%"], { cwd: "/mnt/c", stdio: ["ignore", "pipe", "ignore"] })
    let out = ""
    child.stdout.on("data", (chunk) => (out += chunk))
    child.on("error", () => resolve(undefined))
    child.on("close", () => resolve(out.trim().startsWith("%") ? undefined : out.trim() || undefined))
  })
  return localAppData
}

export async function openBrowser(url: string, browser: BrowserConfig): Promise<string> {
  if (browser.type === "chrome-app" && existsSync(browser.path)) {
    const base = await windowsLocalAppData()
    const args = [`--app=${url}`, "--no-first-run", "--no-default-browser-check"]
    if (base) args.push(`--user-data-dir=${base}\\${browser.profileDir}`)
    if (browser.windowSize) args.push(`--window-size=${browser.windowSize}`)
    spawn(browser.path, args, { detached: true, stdio: "ignore" }).unref()
    return "Chrome (jendela aplikasi)"
  }
  spawn("wslview", [url], { detached: true, stdio: "ignore" }).unref()
  return "browser default"
}

/** Run `bank <args> --json --open none`; `onReady` gets the URL as soon as the server listens. */
export function startServer(
  tools: string,
  cwd: string,
  args: string[],
  onReady: (event: BankEvent) => void,
): Server {
  const child = spawn("uv", ["run", "--project", tools, "bank", "--json", ...args, "--open", "none"], {
    cwd,
    stdio: ["ignore", "pipe", "pipe"],
  })
  let stderr = ""
  child.stderr?.on("data", (chunk) => (stderr = (stderr + chunk).slice(-4000)))
  let finished: BankEvent | undefined
  const lines = createInterface({ input: child.stdout! })
  lines.on("line", (line) => {
    let event: BankEvent
    try {
      event = JSON.parse(line)
    } catch {
      return
    }
    if (event.event === "ready") onReady(event)
    else if (event.event === "finished" || event.event === "discarded") finished = event
  })
  const done = new Promise<{ code: number | null; finished?: BankEvent; stderr: string }>((resolve) => {
    child.on("close", (code) => resolve({ code, finished, stderr }))
    child.on("error", (error) => resolve({ code: -1, finished, stderr: String(error) }))
  })
  return { child, done }
}

export function parseSessionArgs(raw: string): { args: string[]; error?: string } {
  const tokens = raw.trim().split(/\s+/).filter(Boolean)
  const subtest = tokens.find((token) => !token.startsWith("--") && !/^\d+$/.test(token) && token !== "ujian" && token !== "latihan")
  if (!subtest) return { args: [], error: "Pakai: /latihan <subtes> [ujian|latihan] [jumlah] [--draft]" }
  const args = ["session", subtest, "--mode", tokens.includes("latihan") ? "latihan" : "ujian"]
  const count = tokens.find((token) => /^\d+$/.test(token))
  if (count) args.push("--n", count)
  if (tokens.includes("--draft")) args.push("--draft")
  return { args }
}
