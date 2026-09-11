# TODO

## Goal

Upgrade workflow WSL Neovim dari `0.12.1` ke `0.13-dev/nightly`, mengganti
autoreload buatan sendiri dengan native filesystem watcher Neovim, lalu
menambahkan satu UI AI native yang dapat memakai OpenCode atau Pi sebagai
backend secara bergantian.

## Scope And Guardrails

- [x] Pi dan OpenCode tidak dijalankan bersamaan pada project/session yang sama.
- [x] Neovim normal menjadi UI utama; `nvim --headless` bukan fondasi UI.
- [x] Agent headless tetap boleh dipakai: `opencode acp`/`serve` dan `pi --mode rpc`.
- [x] Native Neovim autoread menjadi owner file watcher setelah smoke test lulus.
- [x] Pertahankan `vim.opt.autoread = true`.
- [x] Pertahankan `lua/raisal/autosave.lua`; autosave berbeda dari external reload.
- [x] Jangan menyalin seluruh kapabilitas OpenCode ke Pi sebelum transport Pi tervalidasi.
- [x] Jangan mengaktifkan auto-approve tanpa permission policy yang eksplisit.
- [x] Satu write-capable agent per project/session; gunakan worktree terpisah bila nanti membutuhkan parallel work.

## Current Findings

- [x] Config saat ini memiliki custom `AutoReload` di `init.lua` untuk `FocusGained`, `BufEnter`, `TermClose`, `TermLeave`, dan `FileChangedShell`.
- [x] Config saat ini sudah mengaktifkan `vim.opt.autoread = true` di `lua/raisal/options.lua`.
- [x] Tidak ada CodeCompanion atau Avante di plugin spec saat ini.
- [x] `lazy.nvim` mengimpor seluruh spec dari `lua/plugins/`.
- [x] `<leader>a` sudah dipakai Harpoon dan `<leader>ca` dipakai LSP code action; keymap AI harus menghindari konflik.
- [x] OpenCode memiliki ACP native.
- [x] Pi menyediakan RPC/SDK, tetapi belum menyediakan ACP native penuh.
- [x] CodeCompanion lebih cocok untuk dual backend dan custom adapter.

## Decisions To Make Before Implementation

- [x] Pilih UI AI: CodeCompanion (rekomendasi) atau Avante.
- [x] Pilih transport Pi: `pi-acp` sebagai jalur pragmatis atau direct RPC/SDK untuk fidelity Pi yang lebih tinggi.
- [x] Pilih channel Neovim: nightly/dev binary yang dipin atau build dari commit tertentu.
- [x] Tentukan apakah pergantian backend harus mempertahankan session masing-masing.
- [x] Tentukan permission default: `ask` untuk edit/tool atau policy lain yang eksplisit.
- [x] Tentukan layout utama: floating window, vertical split, atau tab terpisah.

## Phase 0: Baseline

- [x] Catat `nvim --version`, commit config, dan lokasi binary WSL.
- [x] Jalankan `:checkhealth` sebelum upgrade.
- [x] Catat startup time, plugin error, dan keymap yang sudah digunakan.
- [x] Pastikan fallback Neovim `0.12.5` tersedia sebelum memasang dev build.

### Baseline Notes

- Current binary: `/opt/nvim-linux-x86_64/bin/nvim` at `v0.12.1`.
- Config path: `/home/raisal/.config/nvim`; repository config: `/home/raisal/dotfiles/nvim`.
- Baseline commit: `07f95a1`; WSL2 kernel `6.6.87.2-microsoft-standard-WSL2`.
- Headless startup baseline: about `0.24s` with the current config.
- Fallback binary: `/home/raisal/.local/opt/nvim-0.12.5/bin/nvim`.
- Health baseline: core config, LSP, Treesitter, Telescope, and providers load; Lazy reports missing optional `luarocks`, and provider warnings exist for Node, Python, Perl, and Ruby.
- Existing AI-relevant mappings include `<leader>a` (Harpoon), `<leader>ca` (LSP code action), `<leader>m*` (.NET), and `<leader>t*` (structure/static typing).

## Phase 1: Neovim Upgrade

- [x] Pasang Neovim `0.13-dev/nightly` side-by-side tanpa menghapus fallback.
- [x] Validasi `:version`, runtime path, LuaJIT/Lua API, dan `:checkhealth`.
- [x] Validasi `lazy.nvim`, Treesitter main branch, LSP Roslyn, Conform, and Noice.
- [x] Validasi `:restart` mengembalikan session/window layout.
- [x] Validasi `:restart!` tetap melakukan hard restart.
- [x] Validasi plugin hooks tidak rusak saat start reason adalah restart.
- [x] Catat rollback command untuk kembali ke Neovim `0.12.5`.
- [x] Pindahkan default interactive `nvim`/`v` ke nightly melalui `~/.zshrc`.

### Phase 1 Notes

- Nightly binary: `/home/raisal/.local/opt/nvim-nightly-2026-09-09/bin/nvim` at `v0.13.0-dev-1558+g8d5ebdf986`.
- Runtime: `/home/raisal/.local/opt/nvim-nightly-2026-09-09/share/nvim/runtime`.
- `:restart` restored the `todo.md` and `init.lua` split layout; `v:startreason=restart` was confirmed.
- `:restart!` returned to one empty window; `v:startreason=restart!` was confirmed.
- Lazy, Treesitter, Conform, Noice, native LSP configurations, and Roslyn `ft=cs` loading passed smoke checks.
- Dotfiles repository has no .NET solution, so Roslyn was additionally tested on `/home/raisal/workspace/csharp-playground/Program.cs`.
- Real project smoke test passed: `filetype=cs`, `roslyn_enabled=true`, client `roslyn`, root `/home/raisal/workspace/csharp-playground`.
- `dotnet build` in that playground fails with pre-existing `CS5001` because `Program.cs` intentionally contains only comments; this is unrelated to Neovim/nightly.
- Nightly health reported no configuration error. Remaining findings are a terminal graphics error under tmux and a `vim.F.if_nil` deprecation warning from existing dependencies.
- Rollback command: `/home/raisal/.local/opt/nvim-0.12.5/bin/nvim`; legacy `/opt/nvim-linux-x86_64/bin/nvim` remains available at `v0.12.1`.

## Phase 2: Native Autoread Migration

- [x] Uji native watcher pada file bersih yang diubah oleh shell.
- [x] Uji perubahan file saat Neovim tidak kehilangan focus.
- [x] Uji atomic rename/write yang umum dilakukan agent.
- [x] Uji buffer dirty yang juga diubah dari luar; pastikan tidak ada silent data loss.
- [x] Uji buffer unnamed, terminal, help, generated, dan file yang sudah dihapus.
- [x] Hapus custom `AutoReload` block dari `nvim/init.lua` setelah smoke test native lulus.
- [x] Hapus `FocusGained`/`BufEnter`/`TermClose`/`TermLeave` `checktime` workaround.
- [x] Hapus callback custom `FileChangedShell` yang memanggil `edit!`.
- [x] Pastikan reload native tidak menghasilkan duplicate notification atau reload loop.
- [x] Pastikan autosave tetap aman saat agent mengubah file.
- [x] Dokumentasikan perilaku conflict handling native dan batasan buffer dirty.

### Phase 2 Notes

- Fixture sementara `/tmp/nvim-autoread-phase2` dipakai agar source project tidak berubah; fixture sudah dibersihkan.
- Native watcher dijalankan oleh runtime `plugin/autoread.lua`, memakai debounce 100 ms dan `:checktime`.
- Clean external edit dan edit saat UI tidak focus ter-reload otomatis.
- Atomic rename terdeteksi, buffer ter-reload, dan watcher dibuat ulang.
- Dirty buffer mempertahankan isi lokal, tidak mengalami silent overwrite, lalu `busy` kembali ke `0` setelah cycle selesai.
- Unnamed, help, dan terminal buffer tidak diawasi. Regular generated-looking file tetap diawasi karena native watcher tidak mengenal kategori generated.
- File yang dihapus melepaskan watcher tanpa reload loop.
- Setelah migration: `AutoReload` custom memiliki `0` autocmd; group `nvim.autoread` memiliki `6` autocmd.
- Autosave menyimpan perubahan lokal; external edit setelah autosave kemudian ter-reload native.
- Native watcher hanya aktif pada nightly/dev Neovim. Default interactive `nvim`/`v` sekarang resolve ke nightly; legacy binary tetap tersedia untuk rollback.

## Phase 3: AI UI Foundation

- [x] Tambah satu plugin spec AI baru di `lua/plugins/codecompanion.lua`.
- [x] Konfigurasi layout yang cocok dengan panel/tab workflow saat ini.
- [x] Integrasikan theme, border, notification, dan split behavior dengan Noice/Nui.
- [x] Tambah keymap AI tanpa mengambil `<leader>a`, `<leader>ca`, `<leader>m*`, atau `<leader>t*`.
- [x] Tambah command untuk membuka/menutup chat dan melihat diff.
- [x] Tambah context buffer, visual selection, diagnostics, git diff, dan current file.
- [x] Pastikan perubahan agent tampil sebagai diff dan dapat disetujui sebelum apply.

### Phase 3 Notes

- CodeCompanion `v19.23.0` terpasang dan tercatat di `lazy-lock.json`.
- Panel chat vertical di kanan, full-height, lebar `0.38`, border `single` terbuka di project C# nyata.
- `:CodeCompanion`, `:CodeCompanionChat`, dan `:CodeCompanionActions` tervalidasi; diff memakai built-in UI dan keymap `gv`, `g1`, `g2`, `g3`, `q`.
- Completion provider `blink` menampilkan context `#buffer`, `#diagnostics`, `#diff`, `#selection`, serta file spesifik seperti `#buffer:Program.cs`.
- Native Neovim autoread tetap menjadi satu-satunya watcher; `interactions.opts.watcher.enabled = false`.
- Tool edit/delete/command dikonfigurasi meminta approval; standalone diff smoke test menampilkan perubahan tanpa mengubah source project.
- `:checkhealth codecompanion` tidak memiliki error; `sqlite3` hanya warning optional untuk token Copilot.
- Validasi prompt, streaming, tool call, permission ACP, dan apply edit dicatat pada Phase 4 Notes.

## Phase 4: OpenCode Backend

- [x] Integrasikan OpenCode melalui `opencode acp` sebagai backend pertama.
- [x] Validasi prompt, streaming response, tool call, permission request, dan abort.
- [x] Validasi edit file, diff review, apply, undo/revert bila tersedia melalui adapter.
- [x] Validasi session resume tanpa menjalankan Pi.
- [x] Validasi skills, instructions, MCP, agents, dan permissions tetap berasal dari OpenCode.
- [x] Pastikan server/network binding WSL tetap loopback dan tidak membuka akses tanpa password.

### Phase 4 Notes

- CodeCompanion memakai adapter ACP bawaan dengan command `opencode acp`; OpenCode runtime terpasang pada `1.18.29`.
- Prompt read-only berhasil melakukan tool call `Read: README.md` dan menerima streaming response satu kalimat.
- Pada fixture disposable, edit menghasilkan proposed diff, meminta approval, berhasil di-apply setelah `g2`, dan ditolak tanpa perubahan setelah `g3`.
- Setelah apply, native autoread memuat isi file baru ke buffer dan `modified=false`; tidak ada silent overwrite.
- `q` menghentikan request panjang sebelum response selesai; `current_request=false` setelah abort.
- ACP melaporkan `loadSession=true` dan `session/list=true`; `session/load` berhasil dan restore mengembalikan 16 session updates tanpa menjalankan Pi.
- Resolved OpenCode config mempertahankan agents, MCP (`bm25`, `context7`), plugins, skills, instructions, serta permission `edit/write/bash=ask`.
- Project config standalone tetap memakai agent `explore`; bridge CodeCompanion menambahkan `OPENCODE_CONFIG_CONTENT={"default_agent":"build"}` agar session ACP dapat coding. Standalone OpenCode tidak berubah.
- Instruction global yang meminta akses ke path di luar fixture memicu approval; approval ditolak dan akses tidak dilanjutkan.
- `ss` saat ACP aktif hanya menunjukkan binding loopback `127.0.0.1:4096`; fixture, session test process, dan files sudah dibersihkan.

## Phase 5: Pi Backend

- [x] Pilih dan dokumentasikan `pi-acp` atau direct Pi RPC/SDK.
- [ ] Validasi session Pi, resume, steer/follow-up, abort, dan streamed events.
- [ ] Validasi context buffer, selection, diagnostics, cwd, dan git diff.
- [ ] Validasi edit/diff workflow tanpa menimpa buffer dirty secara silent.
- [ ] Validasi skills, extensions, model switching, dan project trust Pi.
- [x] Dokumentasikan kapabilitas yang tidak tersedia jika memakai `pi-acp` MVP.
- [ ] Jika direct RPC dipilih, buat adapter minimal tanpa mencoba meniru seluruh OpenCode.
- [ ] Pastikan backend sebelumnya berhenti/abort sebelum backend lain dimulai.

### Phase 5 Notes

- Transport yang dipilih adalah `pi-acp@0.0.33`, yang menjembatani ACP ke `pi --mode rpc`; direct RPC/SDK tidak dipakai sebagai adapter kedua.
- Pi `0.83.0` dan `pi-acp` berjalan dengan Node `24.12.0`; `pi-acp` dipasang global sehingga command `pi-acp` harus tersedia di `PATH`.
- ACP smoke test disposable lulus untuk initialize, session creation, prompt, tool call, streaming, session list, dan fixture integrity. `session/load`, steer/follow-up, abort, serta context injection belum diuji.
- Pi auth lokal masih stale dan perlu login ulang. Smoke test API memakai credential OpenCode sementara di direktori `/tmp`, bukan credential Pi.
- Actual CodeCompanion UI chat dengan Pi, buffer dirty/native autoread, project-root guard, dan backend switch process check masih pending.

## Phase 6: Shared Workflow And Safety

- [ ] Gunakan shared `AGENTS.md`, `CLAUDE.md`, `.agents/skills`, dan `.claude/skills` hanya untuk context/instructions.
- [ ] Jangan menganggap shared files berarti shared live session.
- [ ] Serialize prompt dan write operation pada satu session.
- [ ] Tampilkan permission request secara jelas di UI Neovim.
- [ ] Tambah guard untuk project root dan file di luar workspace.
- [ ] Uji interaksi AI edit dengan native autoread dan autosave.
- [ ] Uji abort saat agent sedang menulis file.
- [ ] Uji session switch OpenCode -> Pi -> OpenCode tanpa proses concurrent.

## Verification Matrix

- [x] Startup bersih pada Neovim `0.13-dev/nightly`.
- [x] Tidak ada error `:messages` setelah load plugin AI.
- [x] `:checkhealth` lulus untuk Neovim, lazy, LSP, dan plugin AI.
- [x] Native autoread mendeteksi external edit tanpa FocusGained/BufEnter workaround.
- [x] Buffer dirty tidak kehilangan perubahan lokal.
- [x] `:restart` dan `:restart!` berfungsi setelah plugin AI aktif.
- [x] OpenCode ACP dapat chat, meminta permission, menampilkan diff, dan apply edit.
- [ ] Pi dapat chat melalui transport yang dipilih dan mempertahankan session sesuai keputusan.
- [ ] Backend dapat diganti tanpa menjalankan dua agent bersamaan.
- [x] Tidak ada konflik keymap dengan config existing.
- [x] Tidak ada reload loop, notification spam, atau startup regression yang signifikan.

## Definition Of Done

- [ ] Neovim 0.13 build yang dipilih stabil untuk workflow harian.
- [ ] Custom external reload autocmd sudah dihapus dan native watcher menjadi owner.
- [ ] CodeCompanion atau Avante menjadi satu UI AI yang dipilih.
- [ ] OpenCode dan Pi dapat dipakai bergantian melalui adapter yang terdokumentasi.
- [ ] Permission, diff review, session behavior, dan known capability gaps terdokumentasi.
- [ ] Rollback ke Neovim `0.12.5` tetap tersedia.
- [ ] Perubahan terverifikasi pada project nyata di WSL.

## References

- Neovim autoread: https://github.com/neovim/neovim/pull/37971
- Neovim restart: https://github.com/neovim/neovim/pull/40321
- CodeCompanion ACP: https://codecompanion.olimorris.dev/configuration/adapters-acp.html
- CodeCompanion OpenCode adapter: https://github.com/olimorris/codecompanion.nvim/blob/main/lua/codecompanion/adapters/acp/opencode.lua
- Avante OpenCode provider: https://github.com/yetone/avante.nvim/blob/main/lua/avante/config.lua
- OpenCode ACP: https://opencode.ai/docs/acp/
- Pi RPC: https://pi.dev/docs/latest/rpc
- Pi SDK: https://pi.dev/docs/latest/sdk
