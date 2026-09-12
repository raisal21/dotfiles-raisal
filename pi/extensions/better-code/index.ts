import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { highlightCode as piHighlightCode } from "@earendil-works/pi-coding-agent";
import { execFileSync, spawn } from "node:child_process";

/**
 * Code block rendering with bat/batcat for terminal syntax highlighting.
 *
 * This is intentionally defensive:
 * - only runs when an interactive UI exists
 * - never shells out through a shell string
 * - probes `batcat` then `bat`, with a built-in highlighter/plain fallback
 * - uses a fenced-code parser instead of one large regex
 * - enforces per-block, total, timeout, output, and count limits
 */

const RESET = "\x1b[0m";
const BAR_RAW = "▎";
const BAR = `\x1b[38;2;110;120;140m${BAR_RAW}\x1b[0m`;
const CHIP = "\x1b[38;2;120;200;220m";
const SEP = "\x1b[38;2;75;80;95m";
const FALLBACK_FG = "\x1b[38;2;180;190;200m";
const SEP_WIDTH = 30;

const MAX_BLOCKS = 12;
const MAX_BLOCK_BYTES = 120 * 1024;
const MAX_TOTAL_CODE_BYTES = 500 * 1024;
const MAX_BAT_OUTPUT_BYTES = 2 * 1024 * 1024;
const BAT_TIMEOUT_MS = 2_000;

type FenceBlock = {
  start: number;
  end: number;
  lang: string;
  code: string;
};

const EXT_MAP: Record<string, string> = {
  typescript: "ts", ts: "ts", tsx: "tsx",
  javascript: "js", js: "js", jsx: "jsx", mjs: "js", cjs: "js",
  python: "py", py: "py",
  rust: "rs", rs: "rs",
  go: "go",
  java: "java",
  kotlin: "kt", kt: "kt",
  swift: "swift",
  c: "c", cpp: "cpp", "c++": "cpp",
  csharp: "cs", cs: "cs",
  ruby: "rb", rb: "rb",
  php: "php",
  bash: "sh", sh: "sh", shell: "sh", zsh: "sh",
  fish: "fish",
  powershell: "ps1", ps1: "ps1",
  sql: "sql",
  html: "html", htm: "html",
  css: "css", scss: "scss", sass: "sass", less: "less",
  json: "json", jsonc: "json",
  yaml: "yaml", yml: "yaml",
  toml: "toml",
  xml: "xml",
  dockerfile: "dockerfile",
  makefile: "makefile",
  lua: "lua",
  perl: "perl",
  r: "r",
  julia: "jl", jl: "jl",
  scala: "scala",
  elixir: "ex", ex: "ex", exs: "exs",
  erlang: "erl",
  haskell: "hs",
  ocaml: "ml",
  vim: "vim",
  graphql: "graphql",
  protobuf: "proto",
  hcl: "hcl", tf: "hcl",
  latex: "tex", tex: "tex",
  diff: "diff", patch: "diff",
  markdown: "md", md: "md",
};

let cachedBatCommand: string | null | undefined;

function header(lang: string): string {
  const tag = lang || "text";
  const sepLine = "┈".repeat(SEP_WIDTH);
  return `${BAR} ${CHIP}[ ${tag} ]${RESET}\n${BAR} ${SEP}${sepLine}${RESET}`;
}

function normalizeLang(lang: string): string {
  const raw = (lang || "").trim().toLowerCase();
  const ext = EXT_MAP[raw] || raw || "txt";
  return /^[a-zA-Z0-9_+-]+$/.test(ext) ? ext : "txt";
}

function getBatCommand(): string | null {
  if (cachedBatCommand !== undefined) return cachedBatCommand;

  for (const candidate of ["batcat", "bat"]) {
    try {
      execFileSync(candidate, ["--version"], {
        encoding: "utf-8",
        stdio: ["ignore", "pipe", "ignore"],
        timeout: 500,
      });
      cachedBatCommand = candidate;
      return candidate;
    } catch {
      // try next candidate
    }
  }

  cachedBatCommand = null;
  return cachedBatCommand;
}

function runBat(command: string, code: string, ext: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn(
      command,
      ["--color=always", "--style=plain", "--paging=never", `--language=${ext}`],
      { stdio: ["pipe", "pipe", "pipe"] },
    );

    const stdoutChunks: Buffer[] = [];
    const stderrChunks: Buffer[] = [];
    let stdoutBytes = 0;
    let stderrBytes = 0;
    let settled = false;

    const timer = setTimeout(() => {
      if (settled) return;
      settled = true;
      child.kill("SIGTERM");
      reject(new Error(`bat timed out after ${BAT_TIMEOUT_MS}ms`));
    }, BAT_TIMEOUT_MS);

    const fail = (error: Error) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      child.kill("SIGTERM");
      reject(error);
    };

    child.stdout.on("data", (chunk: Buffer) => {
      stdoutBytes += chunk.length;
      if (stdoutBytes > MAX_BAT_OUTPUT_BYTES) {
        fail(new Error("bat output exceeded max buffer"));
        return;
      }
      stdoutChunks.push(chunk);
    });

    child.stderr.on("data", (chunk: Buffer) => {
      stderrBytes += chunk.length;
      if (stderrBytes <= 64 * 1024) stderrChunks.push(chunk);
    });

    child.on("error", fail);
    child.on("close", (codeNum) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);

      if (codeNum !== 0) {
        const stderr = Buffer.concat(stderrChunks).toString("utf-8").trim();
        reject(new Error(stderr || `bat exited with code ${codeNum}`));
        return;
      }

      resolve(Buffer.concat(stdoutChunks).toString("utf-8"));
    });

    child.stdin.end(code);
  });
}

function prefixLines(text: string, fallbackColor = false): string {
  return text
    .replace(/\n$/, "")
    .split("\n")
    .map((line) => {
      const safeLine = line || " ";
      if (fallbackColor) return `${BAR} ${FALLBACK_FG}${safeLine}${RESET}`;
      return `${BAR} ${safeLine}`;
    })
    .join("\n");
}

function plainHighlight(code: string, lang: string): string {
  try {
    const lines = piHighlightCode(code, normalizeLang(lang));
    return prefixLines(lines.join("\n"));
  } catch {
    return prefixLines(code, true);
  }
}

async function highlightCode(code: string, lang: string): Promise<string> {
  const ext = normalizeLang(lang);
  const head = header(lang || ext);

  if (Buffer.byteLength(code, "utf-8") > MAX_BLOCK_BYTES) {
    return `${head}\n${plainHighlight(code, lang)}\n${BAR} ${SEP}[large block: skipped bat highlighting]${RESET}`;
  }

  const batCommand = getBatCommand();
  if (!batCommand) return `${head}\n${plainHighlight(code, lang)}`;

  try {
    const stdout = await runBat(batCommand, code, ext);
    return `${head}\n${prefixLines(stdout)}`;
  } catch {
    return `${head}\n${plainHighlight(code, lang)}`;
  }
}

function splitLinesWithOffsets(text: string): Array<{ start: number; end: number; bodyEnd: number; text: string; body: string }> {
  const lines: Array<{ start: number; end: number; bodyEnd: number; text: string; body: string }> = [];
  let offset = 0;

  while (offset < text.length) {
    const nl = text.indexOf("\n", offset);
    const end = nl === -1 ? text.length : nl + 1;
    const raw = text.slice(offset, end);
    const body = raw.endsWith("\r\n") ? raw.slice(0, -2) : raw.endsWith("\n") ? raw.slice(0, -1) : raw;
    lines.push({ start: offset, end, bodyEnd: offset + body.length, text: raw, body });
    offset = end;
  }

  return lines;
}

function parseFenceOpen(line: string): { char: "`" | "~"; len: number; info: string } | null {
  const match = line.match(/^ {0,3}(`{3,}|~{3,})([^\r\n]*)$/);
  if (!match) return null;

  const fence = match[1];
  const info = (match[2] || "").trim();
  const char = fence[0] as "`" | "~";

  // CommonMark: backtick fence info strings cannot contain backticks.
  if (char === "`" && info.includes("`")) return null;
  return { char, len: fence.length, info };
}

function isFenceClose(line: string, char: "`" | "~", len: number): boolean {
  const escaped = char === "`" ? "`" : "~";
  const re = new RegExp(`^ {0,3}${escaped}{${len},}[ \\t]*$`);
  return re.test(line);
}

function parseFencedCodeBlocks(text: string): FenceBlock[] {
  const lines = splitLinesWithOffsets(text);
  const blocks: FenceBlock[] = [];

  for (let i = 0; i < lines.length; i++) {
    const open = parseFenceOpen(lines[i].body);
    if (!open) continue;

    for (let j = i + 1; j < lines.length; j++) {
      if (!isFenceClose(lines[j].body, open.char, open.len)) continue;

      const infoLang = open.info.split(/\s+/)[0] || "";
      blocks.push({
        start: lines[i].start,
        end: lines[j].end,
        lang: infoLang,
        code: text.slice(lines[i].end, lines[j].start),
      });
      i = j;
      break;
    }
  }

  return blocks;
}

async function processCodeBlocks(text: string): Promise<string> {
  if (!text.includes("```") && !text.includes("~~~")) return text;
  if (text.includes(BAR_RAW) && text.includes("[ ") && text.includes("┈")) return text;

  const allBlocks = parseFencedCodeBlocks(text);
  if (allBlocks.length === 0) return text;

  let totalBytes = 0;
  const blocks: FenceBlock[] = [];
  for (const block of allBlocks) {
    if (blocks.length >= MAX_BLOCKS) break;
    const size = Buffer.byteLength(block.code, "utf-8");
    if (totalBytes + size > MAX_TOTAL_CODE_BYTES) break;
    totalBytes += size;
    blocks.push(block);
  }

  if (blocks.length === 0) return text;

  const renderedBlocks = await Promise.all(
    blocks.map(async (block) => `\n${await highlightCode(block.code, block.lang)}\n`),
  );

  let result = text;
  for (let i = blocks.length - 1; i >= 0; i--) {
    const block = blocks[i];
    result = result.slice(0, block.start) + renderedBlocks[i] + result.slice(block.end);
  }

  return result;
}

export default function (pi: ExtensionAPI) {
  pi.on("message_end", async (event, ctx) => {
    if (event.message.role !== "assistant") return;
    if ((ctx as any).hasUI === false) return;
    if (process.env.BETTER_CODE_DISABLE === "1") return;

    const newContent = await Promise.all(
      event.message.content.map(async (block: any) => {
        if (block.type === "text" && typeof block.text === "string") {
          return { ...block, text: await processCodeBlocks(block.text) };
        }
        return block;
      }),
    );

    const changed = newContent.some((block: any, i: number) => {
      const original = event.message.content[i];
      return (
        block.type === "text" &&
        original.type === "text" &&
        block.text !== original.text
      );
    });

    if (changed) {
      return { message: { ...event.message, content: newContent } };
    }
  });
}
