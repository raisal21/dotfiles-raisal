/**
 * BM25 Search Tool for pi coding agent
 *
 * Uses ripgrep to retrieve candidate lines, then ranks them with BM25
 * (Okapi BM25 algorithm via fast-bm25 npm package).
 *
 * Provides:
 *   - `bm25_search` tool (for the LLM)
 *   - `/bm25` command (interactive)
 *   - `/rg` command (interactive ripgrep shortcut)
 */

import { execFileSync } from "node:child_process";
import path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  formatSize,
  keyHint,
  truncateHead,
} from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { BM25 } from "fast-bm25";
import { Type } from "typebox";

const DEFAULT_TOP_K = 10;
const DEFAULT_MAX_CANDIDATES = 1000;
const DEFAULT_TIMEOUT_MS = 15_000;
const RG_MAX_BUFFER = 20 * 1024 * 1024;
const DEFAULT_EXCLUDE_GLOBS = [
  "!**/.git/**",
  "!**/node_modules/**",
  "!**/dist/**",
  "!**/build/**",
  "!**/out/**",
  "!**/coverage/**",
  "!**/target/**",
  "!**/.next/**",
  "!**/.turbo/**",
  "!**/.cache/**",
];

type Bm25Doc = Record<string, string>;
type LineSource = { file: string; line: number };
type RankedResult = { index: number; score: number };

type SearchOptions = {
  query: string;
  pattern?: string;
  searchPath?: string;
  glob?: string;
  topK?: number;
  maxCandidates?: number;
  timeoutMs?: number;
  cwd: string;
};

function escapeRegExp(value: string): string {
  return value.replace(/[\\^$.*+?()[\]{}|]/g, "\\$&");
}

function tokenizeQuery(query: string): string[] {
  const seen = new Set<string>();
  const terms: string[] = [];
  for (const raw of query.split(/[\s|()[\]{}.,;:/"'`<>!?=+*&^%#@\\-]+/u)) {
    const term = raw.trim();
    if (term.length <= 2) continue;
    const key = term.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    terms.push(term);
  }
  return terms;
}

function buildRgPattern(query: string, explicitPattern?: string): string | null {
  const pattern = explicitPattern?.trim();
  if (pattern) return pattern;

  const terms = tokenizeQuery(query);
  if (terms.length === 0) return null;
  return terms.map(escapeRegExp).join("|");
}

function numericParam(value: unknown, fallback: number, min: number, max: number): number {
  const n = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(min, Math.min(max, Math.floor(n)));
}

function decodeRgText(field: any): string {
  if (!field) return "";
  if (typeof field.text === "string") return field.text;
  if (typeof field.bytes === "string") {
    try {
      return Buffer.from(field.bytes, "base64").toString("utf-8");
    } catch {
      return "";
    }
  }
  return "";
}

function displayPath(file: string, cwd: string): string {
  const rel = path.relative(cwd, file);
  if (rel && !rel.startsWith("..") && !path.isAbsolute(rel)) return rel;
  return file;
}

function parseRgJson(output: string, cwd: string, maxCandidates: number): {
  docs: Bm25Doc[];
  sources: LineSource[];
  totalMatches: number;
  totalFiles: number;
} {
  const docs: Bm25Doc[] = [];
  const sources: LineSource[] = [];
  const files = new Set<string>();
  let totalMatches = 0;

  for (const line of output.split("\n")) {
    if (!line.trim()) continue;

    let event: any;
    try {
      event = JSON.parse(line);
    } catch {
      continue;
    }

    if (event?.type !== "match") continue;
    totalMatches++;
    if (docs.length >= maxCandidates) continue;

    const file = decodeRgText(event.data?.path);
    const text = decodeRgText(event.data?.lines).trimEnd();
    const lineNumber = Number(event.data?.line_number) || 0;
    if (!file || !text || lineNumber <= 0) continue;

    const shownPath = displayPath(file, cwd);
    files.add(shownPath);
    docs.push({
      text,
      filename: path.basename(file),
      path: shownPath,
    });
    sources.push({ file: shownPath, line: lineNumber });
  }

  return { docs, sources, totalMatches, totalFiles: files.size };
}

function rankDocs(docs: Bm25Doc[], query: string, topK: number): RankedResult[] {
  if (docs.length === 0) return [];

  const bm25 = new BM25(docs, {
    k1: 1.5,
    b: 0.75,
    fieldBoosts: { text: 1.0, filename: 0.5, path: 0.3 },
  });

  const results = bm25.search(query, topK) as RankedResult[];
  if (results.length > 0) return results;

  // Fallback: rg found candidates, but BM25 produced no positive ranking.
  return docs.slice(0, topK).map((_, index) => ({ index, score: 0 }));
}

function formatResults(
  results: RankedResult[],
  docs: Bm25Doc[],
  sources: LineSource[],
): string {
  return results
    .map((r, i) => {
      const src = sources[r.index];
      const doc = docs[r.index];
      const score = Number.isFinite(r.score) ? r.score.toFixed(3) : "0.000";
      return `${i + 1}. [${src.file}:${src.line}] (score: ${score})\n   ${doc.text.trim().slice(0, 300)}`;
    })
    .join("\n\n");
}

function runBm25Search(options: SearchOptions): {
  text: string;
  details: Record<string, unknown>;
} {
  const query = options.query.trim();
  const topK = numericParam(options.topK, DEFAULT_TOP_K, 1, 100);
  const maxCandidates = numericParam(
    options.maxCandidates,
    DEFAULT_MAX_CANDIDATES,
    1,
    10_000,
  );
  const timeoutMs = numericParam(options.timeoutMs, DEFAULT_TIMEOUT_MS, 1_000, 120_000);
  const rgPattern = buildRgPattern(query, options.pattern);

  if (!query) {
    return {
      text: "Query is empty.",
      details: { query, matchCount: 0, error: "empty query" },
    };
  }

  if (!rgPattern) {
    return {
      text: "Query too short, need at least one term longer than 2 characters or an explicit pattern.",
      details: { query, matchCount: 0, error: "query too short" },
    };
  }

  const rgArgs = ["--json", "--line-number", "--color=never", "--smart-case"];
  for (const excludeGlob of DEFAULT_EXCLUDE_GLOBS) rgArgs.push("--glob", excludeGlob);
  if (options.glob) rgArgs.push("--glob", options.glob);
  rgArgs.push(rgPattern, options.searchPath || ".");

  let rgOutput: string;
  try {
    rgOutput = execFileSync("rg", rgArgs, {
      cwd: options.cwd,
      encoding: "utf-8",
      maxBuffer: RG_MAX_BUFFER,
      timeout: timeoutMs,
    });
  } catch (err: any) {
    if (err.status === 1) {
      return {
        text: "No matches found",
        details: { query, pattern: rgPattern, matchCount: 0 },
      };
    }
    if (err.signal === "SIGTERM" || err.code === "ETIMEDOUT") {
      throw new Error(`ripgrep timed out after ${timeoutMs}ms`);
    }
    if (err.code === "ENOBUFS") {
      throw new Error(
        `ripgrep output exceeded ${formatSize(RG_MAX_BUFFER)}; narrow query/path/glob or lower maxCandidates`,
      );
    }
    throw new Error(`ripgrep failed: ${err.message}`);
  }

  const { docs, sources, totalMatches, totalFiles } = parseRgJson(
    rgOutput,
    options.cwd,
    maxCandidates,
  );

  if (docs.length === 0) {
    return {
      text: "No matching lines found",
      details: { query, pattern: rgPattern, matchCount: 0, totalMatches },
    };
  }

  const results = rankDocs(docs, query, topK);
  let resultText = formatResults(results, docs, sources);

  const truncation = truncateHead(resultText, {
    maxLines: DEFAULT_MAX_LINES,
    maxBytes: DEFAULT_MAX_BYTES,
  });
  resultText = truncation.content;

  if (truncation.truncated) {
    resultText += `\n\n[Output truncated: ${truncation.outputLines}/${truncation.totalLines} lines]`;
  }

  return {
    text: resultText,
    details: {
      query,
      pattern: rgPattern,
      totalFiles,
      totalMatches,
      rankedCandidates: docs.length,
      topK: results.length,
      maxCandidates,
      timeoutMs,
      defaultExcludes: DEFAULT_EXCLUDE_GLOBS,
      fallbackRanking: results.some((r) => r.score === 0),
      truncation: truncation.truncated
        ? { outputLines: truncation.outputLines, totalLines: truncation.totalLines }
        : undefined,
    },
  };
}

function splitArgs(input: string): string[] {
  const args: string[] = [];
  let current = "";
  let quote: "'" | '"' | null = null;
  let escaped = false;

  for (const ch of input) {
    if (escaped) {
      current += ch;
      escaped = false;
      continue;
    }
    if (ch === "\\" && quote !== "'") {
      escaped = true;
      continue;
    }
    if ((ch === "'" || ch === '"') && !quote) {
      quote = ch;
      continue;
    }
    if (quote === ch) {
      quote = null;
      continue;
    }
    if (/\s/.test(ch) && !quote) {
      if (current) {
        args.push(current);
        current = "";
      }
      continue;
    }
    current += ch;
  }

  if (escaped) current += "\\";
  if (current) args.push(current);
  return args;
}

function getToolText(result: { content?: Array<{ type: string; text?: string }> }): string {
  return result.content
    ?.filter((block) => block.type === "text")
    .map((block) => block.text || "")
    .join("\n") || "";
}

function firstResultLine(text: string): string {
  const line = text.split("\n").find((candidate) => candidate.trim());
  if (!line) return "";
  return line.length > 140 ? `${line.slice(0, 137)}...` : line;
}

function formatBm25Summary(result: any, theme: any, expanded: boolean): string {
  const details = result.details || {};
  const text = getToolText(result);
  const isEmpty = !text || text === "No matches found" || text === "No matching lines found";
  const status = isEmpty ? theme.fg("warning", "BM25: no matches") : theme.fg("success", "BM25: results ready");

  const parts = [status];
  if (typeof details.topK === "number") parts.push(theme.fg("muted", `${details.topK} shown`));
  if (typeof details.totalMatches === "number") parts.push(theme.fg("muted", `${details.totalMatches} matches`));
  if (typeof details.totalFiles === "number") parts.push(theme.fg("muted", `${details.totalFiles} files`));
  if (details.query) parts.push(theme.fg("dim", `query: ${String(details.query)}`));

  if (!expanded) {
    const preview = firstResultLine(text);
    let out = parts.join(" · ");
    if (preview) out += `\n${theme.fg("dim", preview)}`;
    out += `\n${theme.fg("muted", keyHint("app.tools.expand", "to expand"))}`;
    return out;
  }

  return `${parts.join(" · ")}\n\n${text}`;
}

function parseBm25CommandArgs(args: string): Omit<SearchOptions, "cwd"> {
  const words = splitArgs(args);
  const queryParts: string[] = [];
  const options: Omit<SearchOptions, "cwd"> = { query: "" };

  for (let i = 0; i < words.length; i++) {
    const word = words[i];
    const next = () => words[++i];

    if (word === "--glob") options.glob = next();
    else if (word === "--pattern") options.pattern = next();
    else if (word === "--path") options.searchPath = next();
    else if (word === "--topK") options.topK = Number(next());
    else if (word === "--maxCandidates") options.maxCandidates = Number(next());
    else if (word === "--timeoutMs") options.timeoutMs = Number(next());
    else queryParts.push(word);
  }

  options.query = queryParts.join(" ").trim();
  return options;
}

export default function (pi: ExtensionAPI) {
  // ---------------------------------------------------------------------------
  // bm25_search tool — for the LLM
  // ---------------------------------------------------------------------------
  pi.registerTool({
    name: "bm25_search",
    label: "BM25 Search",
    description: `Search code with ripgrep candidate retrieval + BM25 ranking. Use query for relevance ranking; use pattern only when you need an explicit ripgrep regex. Output truncated to ${DEFAULT_MAX_LINES} lines or ${formatSize(DEFAULT_MAX_BYTES)}.`,
    parameters: Type.Object({
      query: Type.String({
        description:
          "Natural-language query used by BM25 ranking. Also tokenized into a safe ripgrep regex when pattern is omitted.",
      }),
      pattern: Type.Optional(
        Type.String({
          description:
            "Explicit ripgrep regex for candidate retrieval. If omitted, query tokens are escaped and OR-joined safely.",
        }),
      ),
      path: Type.Optional(
        Type.String({ description: "Directory or file to search (default: cwd)" }),
      ),
      glob: Type.Optional(
        Type.String({ description: "File glob, e.g. '*.ts'" }),
      ),
      topK: Type.Optional(
        Type.Number({
          description: "Number of ranked results to return (default: 10, max: 100)",
        }),
      ),
      maxCandidates: Type.Optional(
        Type.Number({
          description:
            "Maximum rg match lines to rank with BM25 (default: 1000, max: 10000)",
        }),
      ),
      timeoutMs: Type.Optional(
        Type.Number({
          description: "ripgrep timeout in milliseconds (default: 15000)",
        }),
      ),
    }),

    renderCall(args, theme, context) {
      const text = (context.lastComponent as Text | undefined) ?? new Text("", 0, 0);
      const query = typeof args?.query === "string" ? args.query : "";
      const searchPath = typeof args?.path === "string" ? args.path : ".";
      const glob = typeof args?.glob === "string" ? ` ${theme.fg("dim", `[${args.glob}]`)}` : "";
      const status = context.isPartial
        ? theme.fg("warning", "searching")
        : theme.fg("success", "done");
      text.setText(
        `${theme.fg("toolTitle", theme.bold("bm25_search"))} ${theme.fg("muted", searchPath)}${glob}\n${theme.fg("dim", query)} · ${status}`,
      );
      return text;
    },

    renderResult(result, options, theme, context) {
      const text = (context.lastComponent as Text | undefined) ?? new Text("", 0, 0);
      if (context.isError) {
        text.setText(theme.fg("error", getToolText(result) || "BM25 search failed"));
        return text;
      }
      text.setText(formatBm25Summary(result, theme, options.expanded));
      return text;
    },

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const {
        query,
        pattern,
        path: searchPath,
        glob,
        topK,
        maxCandidates,
        timeoutMs,
      } = params;

      const result = runBm25Search({
        query,
        pattern,
        searchPath,
        glob,
        topK,
        maxCandidates,
        timeoutMs,
        cwd: ctx.cwd,
      });

      return {
        content: [{ type: "text", text: result.text }],
        details: result.details,
      };
    },
  });

  // ---------------------------------------------------------------------------
  // /bm25 command — interactive search
  // ---------------------------------------------------------------------------
  pi.registerCommand("bm25", {
    description:
      "BM25 search: /bm25 <query> [--pattern <rg-regex>] [--glob *.ts] [--path src] [--topK 5]",
    handler: async (args, ctx) => {
      if (!args) {
        ctx.ui.notify(
          "Usage: /bm25 <query> [--pattern <rg-regex>] [--glob *.ts] [--path src] [--topK 5]",
          "error",
        );
        return;
      }

      try {
        const parsed = parseBm25CommandArgs(args);
        const result = runBm25Search({ ...parsed, cwd: ctx.cwd });
        ctx.ui.setEditorText(result.text);
        ctx.ui.notify("BM25 search complete", "success");
      } catch (err: any) {
        ctx.ui.notify(`BM25 search failed: ${err.message}`, "error");
      }
    },
  });

  // ---------------------------------------------------------------------------
  // /rg command — quick ripgrep shortcut
  // ---------------------------------------------------------------------------
  pi.registerCommand("rg", {
    description: "Run ripgrep safely: /rg <pattern> [path]",
    handler: async (args, ctx) => {
      if (!args) {
        ctx.ui.notify("Usage: /rg <pattern> [path]", "error");
        return;
      }

      const words = splitArgs(args);
      const pattern = words[0];
      const searchPath = words[1] || ".";
      if (!pattern) {
        ctx.ui.notify("Usage: /rg <pattern> [path]", "error");
        return;
      }

      try {
        const output = execFileSync(
          "rg",
          [
            "--line-number",
            "--color=never",
            "--smart-case",
            ...DEFAULT_EXCLUDE_GLOBS.flatMap((excludeGlob) => ["--glob", excludeGlob]),
            pattern,
            searchPath,
          ],
          {
            cwd: ctx.cwd,
            encoding: "utf-8",
            maxBuffer: RG_MAX_BUFFER,
            timeout: DEFAULT_TIMEOUT_MS,
          },
        );
        const lines = output.trim().split("\n").filter(Boolean);
        ctx.ui.setEditorText(output.slice(0, DEFAULT_MAX_BYTES));
        ctx.ui.notify(`${lines.length} matches`, "success");
      } catch (err: any) {
        if (err.status === 1) {
          ctx.ui.notify("No matches", "info");
        } else {
          ctx.ui.notify(`rg failed: ${err.message}`, "error");
        }
      }
    },
  });
}
