import { readFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { createInterface } from "node:readline";
import path from "node:path";
import { BM25 } from "fast-bm25";

const rl = createInterface({ input: process.stdin });
let buffer = "";
let initialized = false;

function send(id, result) {
  process.stdout.write(JSON.stringify({ jsonrpc: "2.0", id, result }) + "\n");
}

function sendError(id, code, message) {
  process.stdout.write(JSON.stringify({ jsonrpc: "2.0", id, error: { code, message } }) + "\n");
}

rl.on("line", async (line) => {
  if (!line.trim()) return;
  try {
    const msg = JSON.parse(line);
    const { id, method, params } = msg;

    if (method === "initialize") {
      initialized = true;
      send(id, {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        serverInfo: { name: "bm25-mcp", version: "1.0.0" },
      });
    } else if (method === "notifications/initialized") {
      // no-op
    } else if (method === "tools/list") {
      send(id, {
        tools: [
          {
            name: "bm25_search",
            description: "Search codebase using BM25 ranking via ripgrep + fast-bm25. Finds candidates with ripgrep then ranks by Okapi BM25 relevance.",
            inputSchema: {
              type: "object",
              properties: {
                query: { type: "string", description: "Natural-language search query" },
                pattern: { type: "string", description: "Ripgrep regex pattern (default: query tokenized with OR)" },
                glob: { type: "string", description: "File glob, e.g. '*.ts'" },
                topK: { type: "number", description: "Number of top results (default: 10)" },
                path: { type: "string", description: "Directory to search (default: cwd)" },
              },
              required: ["query"],
            },
          },
        ],
      });
    } else if (method === "tools/call") {
      const { name, arguments: args } = params;
      if (name === "bm25_search") {
        try {
          const result = await bm25Search(args);
          send(id, { content: [{ type: "text", text: result }] });
        } catch (e) {
          sendError(id, -1, e.message);
        }
      } else {
        sendError(id, -32601, `Unknown tool: ${name}`);
      }
    } else {
      sendError(id, -32601, `Unknown method: ${method}`);
    }
  } catch (e) {
    // ignore malformed messages
  }
});

async function bm25Search(params) {
  const { query, pattern, glob, topK = 10, path: searchPath } = params;
  const cwd = searchPath || process.cwd();

  const rgPattern = pattern || query.split(/\s+/).filter(t => t.length > 2).join("|");
  if (!rgPattern) return "Query too short, need at least one term longer than 2 characters.";

  let candidateFiles;
  try {
    const rgArgs = ["--line-number", "--color=never", "--files-with-matches"];
    if (glob) rgArgs.push("--glob", glob);
    rgArgs.push(rgPattern, cwd);
    const result = spawnSync("rg", rgArgs, { encoding: "utf-8", maxBuffer: 10 * 1024 * 1024 });
    if (result.error) throw new Error(`ripgrep failed: ${result.error.message}`);
    if (result.status === 1) return "No matches found";
    if (result.status !== 0) throw new Error(`ripgrep failed with status ${result.status}`);
    candidateFiles = result.stdout.trim().split("\n").filter(Boolean);
  } catch (err) {
    throw new Error(`ripgrep failed: ${err.message}`);
  }

  if (candidateFiles.length === 0) return "No matches found";

  const docs = [];
  const lineSources = [];
  const MAX_FILES = 200;

  for (const file of candidateFiles.slice(0, MAX_FILES)) {
    try {
      const absolutePath = path.resolve(cwd, file);
      const content = await readFile(absolutePath, "utf-8");
      const lines = content.split("\n");
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].toLowerCase().includes(query.toLowerCase())) {
          docs.push({ text: lines[i], filename: path.basename(file), path: file });
          lineSources.push({ file, line: i + 1 });
        }
      }
    } catch { /* skip unreadable */ }
  }

  if (docs.length === 0) return "No matching lines found";

  const bm25 = new BM25(docs, { k1: 1.5, b: 0.75, fieldBoosts: { text: 1.0, filename: 0.5, path: 0.3 } });
  const results = bm25.search(query, topK);

  let output = results.map((r, i) => {
    const src = lineSources[r.index];
    return `${i + 1}. [${src.file}:${src.line}] (score: ${r.score.toFixed(3)})\n   ${docs[r.index].text.trim().slice(0, 300)}`;
  }).join("\n\n");

  if (output.length > 50000) output = output.slice(0, 50000) + "\n\n[truncated]";
  return output;
}
