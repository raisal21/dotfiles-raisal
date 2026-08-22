# Napkin — Nvim config decisions

## 2026-05-18 — Triage + cleanup plan dari roast 46-plugin config

**Konteks:** Roast nvim config keluar 10-item priority fix list. Grill session resolve scope per-item lintas tiga domain (over-engineering, security, maintainability). Catatan decisions di bawah ini = output stress-test, siap dijadikan execution plan terpisah.

---

### Decision 1 — Strategi scope: triage, bukan mega-PR

**Decision:** Pisah fix jadi tiga gelombang:
1. **Footgun (urgent, commit terpisah):** `FileChangedShell` guard `&modified`.
2. **Cleanup mekanis (single chore commit):** dedup `nvim-autopairs`, dedup `<leader>rn`, mason list dedup loop, `keyse` typo md-render, hapus `completion.lua.orig` + `completion.lua.rej`.
3. **Architectural (decide-now, execute-later):** theme switch refactor, prune markdown plugin, drop dead deps.

**Rationale:** Mega-PR 10-item unreviewable + un-bisectable. Bug regression susah dilacak. Triage = `git bisect` tetap berguna.

**Rejected alternatives:** Apply all 10 sekaligus dalam satu commit.

---

### Decision 2 — Cutlass `cut_key = "m"` dibiarkan (mark register dikorbankan sadar)

**Decision:** Tidak diubah. `m` tetap = cutlass cut.

**Rationale:** User aware trade-off. Workflow yank-paste lebih kuat daripada kebutuhan mark register.

**Rejected alternatives:** Pindah `cut_key` ke `<leader>x` atau matiin `cut_key` total.

---

### Decision 3 — `FileChangedShell` callback guard `&modified`

**Decision:** Patch init.lua:24, tambah guard sebelum `vim.cmd("edit!")`:

```lua
callback = function(args)
  vim.schedule(function()
    if vim.bo[args.buf].modified then
      vim.notify(
        "Buffer " .. vim.fn.bufname(args.buf) .. " modified externally + lokal — reload skip",
        vim.log.levels.WARN
      )
      return
    end
    vim.api.nvim_buf_call(args.buf, function()
      vim.cmd("edit!")
    end)
  end)
end,
```

**Rationale:** Buffer kotor + external change = potensi kerjaan ilang. Probability rendah tapi cost guard = 4 baris. Workflow agent edit (use case awal autocmd) tetap jalan untuk buffer bersih.

**Rejected alternatives:** Biarin destructive (asumsi never-overlap dengan agent).

---

### Decision 4 — `<leader>rn` dup: buang versi global di keymaps.lua

**Decision:** Hapus `keymaps.lua:12` `keymap("n", "<leader>rn", vim.lsp.buf.rename)`. Pertahankan versi `LspAttach` di `lsp.lua:29`.

**Rationale:** Rename = operasi LSP. LspAttach lebih scoped, cuma aktif di buffer dengan server. Global mapping = no-op silent di buffer non-LSP.

**Rejected alternatives:** Buang LspAttach, keep global.

---

### Decision 5 — Theme switch refactor pakai autocmd `ColorScheme` + persist

**Decision:** Hapus cabang `if theme == "moonfly" elseif kanagawa` di init.lua. Ganti dengan autocmd table-driven + persist last choice via state file:

```lua
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("WinBarTheme", { clear = true }),
  callback = function()
    local palettes = {
      kanagawa = { fg = "#c8c093", fg_nc = "#727169", bg = "#181616" },
      moonfly  = { fg = "#bdbdbd", fg_nc = "#7c7c7c", bg = "#1c1c1c" },
    }
    local p = palettes[vim.g.colors_name]
    if not p then return end
    vim.api.nvim_set_hl(0, "WinBar",   { fg = p.fg,    bg = p.bg, bold = true })
    vim.api.nvim_set_hl(0, "WinBarNC", { fg = p.fg_nc, bg = p.bg })
    -- persist
    vim.fn.writefile({ vim.g.colors_name }, vim.fn.stdpath("state") .. "/last_theme")
  end,
})

-- restore at startup (after lazy setup, whitelist + pcall — lihat Decision 8)
```

Plus ubah `ui.lua` plugin moonfly: hapus `event = "VeryLazy"`, biarin `lazy = true` saja → defer sampai `:colorscheme moonfly` dipanggil.

**Rationale:** Swap real-time via `<leader>fc` (telescope colorscheme picker existing). Persist lintas session. Scalable buat tema ke-3.

**Rejected alternatives:** Hardcode kanagawa + drop moonfly plugin. Autocmd tanpa persist.

---

### Decision 6 — Markdown stack: keep `render-markdown` + `obsidian` (UI off), drop `md-render`

**Decision:**
- **Drop** `md-render.nvim` (plus typo `keyse` baris 8 = bukti nggak pernah ke-trigger).
- **Keep** `render-markdown.nvim` handle semua rendering inline.
- **Keep** `obsidian.nvim`, tambah `ui = { enable = false }` di opts → render-markdown handle penuh, no overlap.

**Rationale:** Tiga plugin overlap di render. Obsidian feature-distinct (vault, link, daily note) wajib keep tapi UI module-nya redundant.

**Rejected alternatives:** Keep semua tiga. Drop dua dan keep cuma render-markdown.

---

### Decision 7 — Telescope `tag = "v0.2.2"` dipertahankan (status quo)

**Decision:** Keep pin v0.2.2. Re-evaluate kalau bug nyata muncul atau telescope rilis fitur kritis.

**Rationale:** Migrasi `fzf-lua`/`snacks.picker` = effort jam-jaman (rewrite custom multigrep, harpoon append). Unpin ke `version = "*"` = ambil risiko API regression tanpa benefit konkret.

**Rejected alternatives:** Unpin ke `version = "*"`. Migrasi ke fzf-lua atau snacks.picker.

---

### Decision 8 — Security: `last_theme` readback whitelist + pcall

**Decision:** Wrap restore dengan validasi:

```lua
local allowed = { kanagawa = true, moonfly = true }
local f = vim.fn.stdpath("state") .. "/last_theme"
if vim.uv.fs_stat(f) then
  local ok, lines = pcall(vim.fn.readfile, f)
  if ok and lines[1] and allowed[lines[1]] then
    pcall(vim.cmd.colorscheme, lines[1])
  end
end
```

**Rationale:** Threat model lokal/single-user (risk RCE = nol), tapi guard cegah startup error noise kalau file corrupt/typo. Cost = 3 baris.

**Rejected alternatives:** Trust isi file mentah (asumsi cuma user yang nulis).

---

### Decision 9 — Clipboard `unnamedplus` dibiarkan (workflow > security)

**Decision:** `opt.clipboard = "unnamedplus"` tetap. Tidak migrasi ke `win32yank`. Tidak scope manual.

**Rationale:** User accept risk leak yank-token ke Windows global clipboard. Friction `<leader>y` vs `y` dianggap nggak worth.

**Rejected alternatives:** Scope manual `<leader>y` + drop autoclip. Ganti provider `win32yank.exe`.

---

### Decision 10 — Mason supply chain: accept default trust

**Decision:** Tidak pin LSP version. Tidak migrasi ke `apt`.

**Rationale:** Mason-registry curated. Risk profile = sama dengan dev biasa `npm install`. Pin = maintenance pajak tinggi tanpa benefit kecuali targeted attack.

**Rejected alternatives:** Pin tiap LSP version via mason-tool-installer. Migrasi ke apt-installed servers.

**Mitigasi murah:** `:Mason` audit bulanan.

---

### Decision 11 — Tambah Roslyn (C# LSP) + treesitter `c_sharp`

**Decision:** Server pilihan = **`roslyn`** (Microsoft official, .NET 8/9 modern). Implementasi butuh plugin `seblj/roslyn.nvim` atau setup manual `vim.lsp.start`. Tambah parser `c_sharp` di treesitter.

**Rationale:** Engine sama dengan VS/Rider, paling akurat untuk pure .NET 8+ workflow. Lo kerja di `witsml-socket-cs` (ASP.NET Core .NET 8 server) — Roslyn fit.

**Rejected alternatives:** `omnisharp` (cocok kalau Unity/legacy, slow di .NET 8+). `csharp_ls` (ringan tapi feature subset).

**Caveat implement:** Roslyn di Mason = manual setup config + nuget restore. Detail di-resolve pas execution.

---

### Decision 12 — Obsidian workspace path = env var via zshrc

**Decision:** Ubah `obsidian.lua:11`:

```lua
path = vim.env.NOTEBOOK_PATH or vim.fn.expand("~/notebook"),
```

Set di `.zshrc`:

```bash
export NOTEBOOK_PATH=/mnt/c/Users/PC-Windows/Documents/wsl-notebook
```

**Rationale:** Portable lintas mesin. Bootstrap mesin baru = set env var saja, config jalan.

**Rejected alternatives:** Hardcoded path. Symlink dari WSL ke Windows path.

---

### Decision 13 — Dotfiles linking: `ln -s` + bootstrap.sh

**Decision:** Replace bind mount dengan symlink. Bikin `scripts/bootstrap.sh` di repo dotfiles:

```bash
#!/usr/bin/env bash
set -e
ln -sfn "$HOME/dotfiles/nvim" "$HOME/.config/nvim"
# ... per-tool entry
```

**Rationale:** No root, portable, reversible. `stow` = overkill untuk current scale (~3-5 tool). Bind mount = invisible + bootstrap mystery.

**Rejected alternatives:** GNU Stow (perlu restructure repo mirror `$HOME`). Bind mount + dokumentasi (butuh root + fstab edit, WSL caveat).

---

### Decision 14 — Plugin audit: drop `mason-tool-installer`, keep `smear-cursor`, scope `nvim-colorizer`

**Decision:**
- **Drop** `mason-tool-installer.nvim` — di lockfile tapi nggak ada `require()` di mana pun. Dead dep.
- **Keep** `smear-cursor.nvim` — cosmetic preference user.
- **Scope** `nvim-colorizer` filetypes:

```lua
filetypes = {
  "css", "scss", "sass", "less",
  "html", "vue", "svelte",
  "javascript", "typescript", "javascriptreact", "typescriptreact",
  "lua",
  "cs", "xaml",   -- defensive untuk WPF/MAUI nanti
  "json", "yaml", -- design tokens, theme config
},
```

**Rationale:** Per real workflow:
- `realtime-monitoring` (TS/React + Tailwind v4 + CSS) = colorizer wajib.
- `witsml-socket-cs` (pure C# server, zero hex per grep) = attach aman, cost trivial. Defensive scope `cs`/`xaml` untuk project WPF/MAUI future.
- Buang `*` global = skip log/markdown buffer.

**Rejected alternatives:** Keep `*` global. Drop colorizer total. Drop smear-cursor.

---

### Decision 15 — Stylua config: Spaces 2

**Decision:** Bikin `~/dotfiles/nvim/.stylua.toml`:

```toml
indent_type = "Spaces"
indent_width = 2
column_width = 120
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
collapse_simple_statement = "Never"
```

Run sekali: `cd ~/dotfiles/nvim && stylua .`. Commit terpisah `chore: enforce stylua spaces-2` biar `git blame` ga rusak.

**Rationale:** Best practice ekosistem nvim Lua = Spaces 2 (LazyVim, NvChad, AstroNvim, folke/*, mini.nvim). Align dengan plugin authors yang lo depend on. Tabs cuma Neovim core (C-codebase legacy outlier). Stylua hanya format `.lua` — C# pakai `dotnet format`/`csharpier`, TS pakai prettier (existing conform.nvim).

**Rejected alternatives:** Tabs (current majority di repo). Biarin inkonsistent. Format manual per-file.

---

### Decision 16 — `lazy-lock.json` keep committed

**Decision:** Status quo. Lockfile tetap di-track git.

**Rationale:** Standard practice ekosistem lazy.nvim. Reproducibility lintas mesin. Noise per-update mitigated via batch update + commit message `chore(lazy): update N plugins`.

**Rejected alternatives:** Gitignore. Commit cuma di tag rilis.

---

## Mekanis cleanup (no branch decision needed, eksekusi langsung)

Catat di sini biar execution plan komplit:

1. Dedup `nvim-autopairs` di `editing.lua` (line 33–38 vs 110–116) → keep satu.
2. Mason `ensure_installed` + `vim.lsp.enable` loop satu kali atas list shared.
3. Fix typo `keyse` → `keys` di `md-render.lua:8` (lalu plugin drop per Decision 6, jadi moot).
4. `rm completion.lua.orig completion.lua.rej`.
5. Fix `nvim-ts-autotag` opts double-nested `opts = { opts = { ... } }` → flat.
6. Conform.nvim `format_on_save.lsp_fallback` — verify masih supported di conform.nvim terbaru (deprecated jadi `lsp_format = "fallback"`).

---

## Execution gelombang (referensi)

| Wave | Scope | Commit |
|------|-------|--------|
| 1 | Decision 3 (FileChangedShell guard) | `fix(nvim): guard FileChangedShell against unsaved buffers` |
| 2 | Decision 4 + 6 + 14 + cleanup mekanis | `chore(nvim): dedup keymaps, prune dead deps, scope colorizer` |
| 3 | Decision 5 + 8 (theme refactor + whitelist) | `refactor(nvim): table-driven theme switch with persist + whitelist` |
| 4 | Decision 11 (Roslyn + treesitter c_sharp) | `feat(nvim): add roslyn LSP + c_sharp treesitter` |
| 5 | Decision 12 + 13 (env var + bootstrap.sh) | `chore(dotfiles): obsidian env var path + bootstrap symlink script` |
| 6 | Decision 15 (stylua format) | `chore: enforce stylua spaces-2 across config` |
| 7 | Decision 17 + 18 + 19 (startup cherry-pick + runtime updatetime + noice shortmess) | `perf(nvim): defer obsidian/blink, raise updatetime, replace noice routes with shortmess` |
| 8 | Decision 20 + 21 + 22 (render-markdown guard + LSP diag config + treesitter size guard) | `perf(nvim): guard heavy rendering against big buffers` |

Decision 2, 7, 9, 10, 16 = no-op (status quo confirmed).

---

## 2026-05-18 — Performance audit addendum (post-roast)

**Konteks:** Baseline startup measurement = ~236ms (headless, kosong). Top offenders identified: obsidian eager-load (~45ms), telescope eager (~47ms), mason via lspconfig (~22ms), blink.cmp partial-eager (~10ms), harpoon double-load (~5ms). User workflow = single-session-lama (sekali buka nvim per hari), jadi runtime perf > cold-start perf untuk prioritas.

Cherry-pick = startup fix yang zero-effort high-impact. Defer heavy refactor (telescope/harpoon/mason restructure) sampai workflow berubah ke per-task editor.

---

### Decision 17 — Startup cherry-pick: defer obsidian + blink + compile kanagawa

**Decision:** Apply 3 fix one-liner:

**(a) `obsidian.lua` tambah `ft = "markdown"`:**
```lua
return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  ft = "markdown",
  ...
}
```

**(b) `completion.lua` tambah `event = { "InsertEnter", "CmdlineEnter" }`:**
```lua
return {
  "saghen/blink.cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  ...
}
```

**(c) Jalankan `:KanagawaCompile` manual sekali** (cache bytecode di `~/.local/share/nvim/kanagawa/`). Re-run kalau kanagawa opts diubah.

**Rationale:** Save ~56ms cold-start (24% improvement) tanpa refactor. Effort = 10 menit total.

**Rejected alternatives:**
- Apply semua 6 fix startup termasuk telescope/harpoon/mason restructure (effort 1-2 jam, nol benefit untuk session lama).
- Skip startup fix entirely (236ms tolerable tapi 56ms saving = free, ngapain skip).

---

### Decision 18 — Runtime: `updatetime = 250` + buang `CursorHold` dari autoreload

**Decision:**

`options.lua:20`:
```lua
opt.updatetime = 250  -- naik dari 50, default lazy.nvim recommended
```

`init.lua:14` ganti autocmd:
```lua
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "TermClose", "TermLeave" }, {
  group = autoreload_group,
  command = "silent! checktime",
})
```

Buang `CursorHold` dari trigger list.

**Rationale:** **Biggest runtime offender.** `updatetime=50` + autocmd CursorHold checktime = stat syscall 20×/detik per loaded buffer. Plus gitsigns/LSP juga listen CursorHold = mereka jalan 20×/detik. Pada WSL2 + cross-mount `/mnt/c/`, stat = expensive (cifs/9p semantics).

Real workflow: agent edit file → user pindah window/focus nvim → `FocusGained`/`BufEnter` fire → checktime → reload. Latency perceived = 0ms. Use case awal (auto-reload agent edit) tetap tercapai tanpa 20Hz polling.

**Rejected alternatives:**
- Keep `updatetime=50` (responsive tapi CPU/disk thrashing).
- Naikkan updatetime tapi pertahankan CursorHold checktime (still polling, cuma lebih jarang).
- Drop autoreload total (kehilangan use case agent edit).

---

### Decision 19 — Runtime: noice routes → `shortmess`

**Decision:**

`options.lua` tambah:
```lua
vim.opt.shortmess:append("Wsa")
-- W = no "written" message (save)
-- s = no search wrap message
-- a = abbreviate all generic messages
```

`noice.lua` baris 230-247: hapus seluruh `routes` filter untuk `yanked`/`written`/`fewer lines`/dst. Pertahankan cuma:
```lua
routes = {
  { filter = { event = "msg_show", kind = "search_count" }, opts = { skip = true } },
  { view = "split", filter = { event = "msg_show", min_height = 10 } },
},
```

**Rationale:** Tiap `msg_show` event tadinya jalan 9 filter pattern-match sequential. Replace dengan native vim `shortmess` flag = handled di vim core, bukan Lua callback. Save micro-overhead per message event + config 14 baris lebih ringkas.

**Rejected alternatives:**
- Keep noice routes (works tapi redundant).
- Drop semua noise filter (akan banjir "1L, 23B written" tiap save).

---

### Decision 20 — Runtime: render-markdown size guard

**Decision:** Tambah opts di `render-markdown.lua`:

```lua
opts = {
  pipe_table = { preset = "double", enabled = true, style = "full", cell = "overlay" },
  -- existing config
  on = {
    attach = function()
      local buf = vim.api.nvim_get_current_buf()
      local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))
      if size > 500 * 1024 then  -- 500KB
        require("render-markdown").buf_disable()
      end
    end,
  },
},
```

**Rationale:** Render-markdown re-render on `TextChanged`/`InsertLeave`. Markdown raksasa (note dump, log paste) = visible lag tiap edit. Guard skip render auto, manual `:RenderMarkdown enable` kalau perlu.

**Rejected alternatives:**
- Tanpa guard (jarang touch markdown gede tapi pas kena = pain).
- Disable render-markdown total untuk semua markdown (kontra Decision 6 yang udah pilih render-markdown).

---

### Decision 21 — Runtime: LSP diagnostic config eksplisit

**Decision:** `lsp.lua` ubah `vim.diagnostic.config({...})` jadi:

```lua
vim.diagnostic.config({
  update_in_insert = false,
  severity_sort = true,
  signs = {
    text = {
      [severity.ERROR] = " ",
      [severity.WARN] = " ",
      [severity.HINT] = "󰠠 ",
      [severity.INFO] = " ",
    },
  },
})
```

**Rationale:** `update_in_insert = false` adalah default tapi worth eksplisit (regression-proof). Skip diagnostic refresh tiap keystroke di insert mode = LSP nggak spam request per character. `severity_sort = true` = error muncul di atas hint dalam diag list.

**Rejected alternatives:**
- Trust default (default bisa berubah lintas neovim version).
- Enable `update_in_insert = true` (instant feedback tapi LSP roundtrip per keystroke = lag di server lambat seperti omnisharp/roslyn).

---

### Decision 22 — Runtime: treesitter highlight size guard

**Decision:** `treesitter.lua` opts:

```lua
highlight = {
  enable = true,
  disable = function(_, buf)
    local max = 100 * 1024  -- 100KB
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
    if ok and stats and stats.size > max then return true end
  end,
  additional_vim_regex_highlighting = false,
},
```

**Rationale:** File 50MB (log dump, minified bundle) tanpa guard = treesitter parse seluruh tree → scroll jerky/freeze. 100KB threshold = file kode normal aman, log/minified skipped to plain syntax.

**Rejected alternatives:**
- Tanpa guard (rare tapi kalau kejadian = nvim freeze).
- Threshold lebih ketat (50KB) — terlalu agresif, file kode normal kena.
- Disable treesitter total — kehilangan semua highlight power.

---

## Floor performance achievable

Setelah Decision 17-22 + Decision 14 (colorizer scope):

| Metric | Sebelum | Setelah | Save |
|--------|---------|---------|------|
| Cold start (headless) | ~236ms | ~180ms | ~56ms (24%) |
| Idle CPU per detik | 20 fire CursorHold × N buffer × (stat + gitsigns + LSP) | 0 fire (purely event-driven) | ~95% idle CPU |
| Big-file (>100KB) editing | freeze/jerky | normal (highlight off) | usable |
| Save event overhead | 9 noice route pattern-match | shortmess flag (vim core) | micro tapi cleaner |

**Real floor cold-start = ~140ms** kalau full refactor telescope/harpoon/mason eventually dieksekusi. Saat ini cap di ~180ms karena defer refactor.

**Runtime floor = effectively zero overhead di idle** post Decision 18. CursorHold otomatis ke-trigger plugin lain (gitsigns blame, LSP code-action) yang lebih reasonable di 250ms cadence vs 50ms.
