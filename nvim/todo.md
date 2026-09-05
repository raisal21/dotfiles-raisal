# TODO

## Planning Guardrails

- Fitur bawaan plugin diperlakukan sebagai acceptance criteria, bukan selalu satu perubahan konfigurasi per checkbox.
- Eksekusi dilakukan per vertical slice yang langsung bisa dipakai dan diuji pada satu solution .NET nyata.
- Satu capability hanya memiliki satu owner: `roslyn.nvim` untuk C# LSP, Conform untuk orchestration formatting, ProjX untuk project files, Aerial untuk document outline, Telescope untuk pencarian sesaat, dan Trouble untuk hasil persisten.
- Foundation, project selection, build, dan run diselesaikan sebelum testing, package management, scaffolding, atau debugging.
- Setiap slice harus memiliki smoke test, pemeriksaan konflik keymap, dan pemeriksaan noise/performance sebelum lanjut.

## Recommended Execution Order

1. Perbaiki aktivasi Treesitter dan indentasi C#.
2. Konsolidasikan Conform dan pastikan jalur formatting Roslyn benar.
3. Selesaikan snippet, comment workflow, dan kebijakan autosave.
4. Tambah indent/scope guides dan batasi sticky context.
5. Tuning symbol usage, Aerial, type hierarchy, dan call hierarchy.
6. Pasang foundation easy-dotnet lalu validasi project selection, build, dan run.
7. Aktifkan test runner, NuGet, EF, dan scaffolding per kebutuhan project nyata.
8. Evaluasi DAP, Razor, lualine, serta explorer integration terakhir.

## Pre-list: C# Neovim Workflow

Daftar kandidat pekerjaan. Belum diprioritaskan dan belum dieksekusi.

- [x] Tambah snippet C# repo-owned di `snippets/` untuk filetype `cs` dan `csharp`.
- [x] Isi snippet modern C# untuk class, record, property, constructor, async method, DI, ASP.NET endpoint, dan test.
- [x] Tambah `<C-b>` sebagai trigger menu Blink snippet-only tanpa auto-accept; callback dan provider tervalidasi headless.
- [x] Tambah command `:CommentClean` untuk menghapus marker komentar seperti `//` tanpa menghapus baris.
- [x] Tambah shortcut untuk `:CommentClean`, kandidat `<leader>cu`.
- [x] Tambah insert mapping `<S-CR>` untuk membuat baris baru tanpa meneruskan komentar.
- [x] Pertahankan perilaku Enter biasa pada baris komentar.
- [x] Uji encoding `<S-CR>` di terminal dan tmux; sesuaikan `ttimeoutlen` bila diperlukan.
- [x] Konsolidasikan dua konfigurasi `conform.nvim` menjadi satu konfigurasi.
- [x] Migrasikan `lsp_fallback` ke API `lsp_format = "fallback"`.
- [x] Pastikan format C# memakai fallback LSP Roslyn tanpa memanggil executable formatter yang belum terpasang.
- [x] Migrasikan `nvim-ts-autotag` ke layout opsi baru tanpa mengubah close/rename/close-on-slash.
- [x] Implementasikan autosave native dengan debounce 1 detik dan ukur dampaknya terhadap format-on-save.
- [x] Pastikan autosave juga menyimpan saat pindah buffer atau kehilangan fokus.
- [x] Batasi autosave pada buffer file yang writable dan memiliki perubahan.
- [x] Pastikan autosave tetap memicu format-on-save.

## Open Decisions

- [x] Pilih strategi partial untuk `easy-dotnet.nvim`.
- [x] Pertahankan `roslyn.nvim` sebagai owner LSP C#.
- [x] Nonaktifkan LSP internal easy-dotnet agar tidak ada dua Roslyn client.
- [x] Pilih kebijakan autosave: debounce setelah 1 detik idle, lalu flush saat `BufLeave`, `FocusLost`, dan `VimLeavePre`.
- [x] Tentukan cakupan snippet lanjutan: core C#, ASP.NET Minimal API, xUnit, dan Moq; EF Core ditunda.

## Decisions: C# Formatting Strategy

- [x] Gunakan `roslyn.nvim` melalui Conform LSP fallback untuk formatting editor dan on-save.
- [x] Gunakan `dotnet format` secara manual atau di CI untuk formatting solution-wide, style, dan analyzer fixes.
- [x] Jangan pasang CSharpier untuk sementara karena akan redundant sebagai formatter on-save dengan Roslyn.
- [x] Pertahankan Roslyn untuk diagnostics, completion, navigation, refactoring, dan code actions.
- [x] Biarkan ProjX menjadi owner formatting XML project file saat integrasi easy-dotnet diaktifkan.
- [ ] Buat workflow atau dokumentasi command `dotnet format` untuk validasi project/solution.
- [ ] Re-evaluasi CSharpier hanya jika membutuhkan layout opinionated seperti Prettier.

## Pre-list: easy-dotnet.nvim Partial Integration

Ambil semua fitur workflow easy-dotnet yang tidak mengambil alih Roslyn. Eksekusi tetap satu task per satu.

### Foundation

- [x] Tambah plugin `GustavEikaas/easy-dotnet.nvim` dengan loading hanya untuk command atau buffer .NET.
- [x] Gunakan dependency `nvim-lua/plenary.nvim` yang sudah tersedia melalui Telescope.
- [x] Install dan validasi global tool `EasyDotnet` versi 3.4.24.
- [x] Konfigurasi Telescope sebagai picker easy-dotnet dan `<leader>mm` sebagai command picker.
- [x] Nonaktifkan easy-dotnet built-in Roslyn LSP, in-process LSP, dan preload Roslyn.
- [x] Pastikan `roslyn.nvim` tetap menjadi satu-satunya Roslyn client pada buffer C#; ProjX tetap client terpisah untuk XML project.
- [x] Jalankan `:checkhealth easy-dotnet`; seluruh dependency wajib lulus, warning tersisa hanya fitur sengaja ditunda/dinonaktifkan.

### Project And Solution

- [x] Aktifkan deteksi `.sln`, `.slnx`, `.csproj`, dan `.fsproj`; fixture runtime menemukan seluruh format.
- [x] Aktifkan pemilihan solution aktif; project/profile aktif dipilih oleh workflow run/build.
- [x] Aktifkan persistensi solution aktif per working directory dan validasi cache berdasarkan cwd.
- [x] Tambah workflow add project ke solution; tervalidasi untuk project C# dan F#.
- [x] Tambah workflow remove project dari solution; tervalidasi untuk project C# dan F#.
- [x] Aktifkan ProjX untuk formatting XML project file; formatting edit tervalidasi pada `.csproj` dan `.fsproj`.
- [x] Aktifkan completion package/version di `.csproj` dan `.fsproj`; kedua request LSP menghasilkan kandidat.
- [x] Aktifkan code action project reference; ProjX menawarkan expand dan remove reference.
- [x] Tambah mapping buffer-local `<leader>ar` untuk file `.csproj` dan `.fsproj`.

### Build And Run

- [ ] Tambah command dan shortcut untuk `dotnet run`.
- [ ] Tambah pemilihan project/profile untuk run.
- [ ] Tambah command dan shortcut untuk `dotnet build`.
- [ ] Tambah opsi build project, solution, dan quickfix.
- [ ] Tambah workflow `dotnet watch`.
- [ ] Tambah workflow `dotnet restore`.
- [ ] Tambah workflow `dotnet clean`.
- [ ] Tambah workflow `dotnet pack`.
- [ ] Tambah workflow `dotnet push`.
- [ ] Konfigurasi terminal panel managed easy-dotnet.
- [ ] Validasi integrasi error build ke quickfix.

### Testing

- [ ] Aktifkan built-in easy-dotnet test runner.
- [ ] Validasi test discovery untuk solution, project, namespace, class, dan method.
- [ ] Tambah workflow run test current buffer.
- [ ] Tambah workflow run semua test.
- [ ] Tambah workflow cancel dan refresh test discovery.
- [ ] Aktifkan tampilan stacktrace dan navigasi failure.
- [ ] Aktifkan build-error view dari test runner.
- [ ] Tambah pemilihan `runsettings`.
- [ ] Review dan sesuaikan default mapping test runner agar tidak konflik.
- [ ] Putuskan apakah Neotest tetap tidak diperlukan.

### NuGet And Entity Framework

- [ ] Aktifkan add package NuGet.
- [ ] Aktifkan remove package NuGet.
- [ ] Aktifkan upgrade package di bawah cursor.
- [ ] Aktifkan upgrade semua package.
- [ ] Aktifkan virtual text untuk package outdated.
- [ ] Validasi dukungan `Directory.Packages.props`, `Packages.props`, dan `Directory.Build.props`.
- [ ] Evaluasi install global tool `dotnet-ef`.
- [ ] Tambah workflow EF database update.
- [ ] Tambah workflow EF database drop.
- [ ] Tambah workflow EF migrations add/remove/list.
- [ ] Aktifkan workflow user secrets.

### Scaffolding And Code Generation

- [ ] Aktifkan browser template `dotnet new`.
- [ ] Aktifkan pembuatan file dari template .NET.
- [ ] Validasi auto-add project baru ke solution aktif.
- [ ] Validasi bootstrap namespace dan type declaration pada file C# baru.
- [ ] Aktifkan generator class, record, interface, dan enum dari file explorer bila relevan.
- [ ] Evaluasi generator JSON ke C# melalui clipboard.
- [ ] Konfirmasi apakah enhanced rename dapat dipakai tanpa LSP internal easy-dotnet; tandai out of scope jika membutuhkan Roslyn milik easy-dotnet.
- [ ] Konfirmasi apakah create type dari unresolved usage dapat dipakai tanpa LSP internal easy-dotnet; tandai out of scope jika membutuhkan Roslyn milik easy-dotnet.

### Diagnostics And Developer Tools

- [ ] Aktifkan workspace diagnostics easy-dotnet.
- [ ] Tambah shortcut diagnostics errors.
- [ ] Tambah shortcut diagnostics warnings.
- [ ] Pastikan diagnostics tetap tampil melalui sistem diagnostic Neovim dan Trouble.
- [ ] Evaluasi analyzer melalui project atau `roslyn.nvim`; jangan aktifkan LSP internal easy-dotnet hanya untuk Roslynator/easy-dotnet analyzer.
- [ ] Validasi source-generated document, code lens, semantic tokens, dan code action tetap berasal dari `roslyn.nvim`.
- [ ] Review default mapping easy-dotnet, terutama konflik `<leader>d` dengan diagnostics.

## Pre-list: C# Visual Structure And Navigation

Target tampilan: indent guides tipis pada setiap level, active scope guide yang lebih jelas, konteks class/method tetap terlihat, serta informasi type/reference yang informatif tanpa memenuhi layar.

### P0: Correctness Before Cosmetics

- [x] Pisahkan daftar parser Treesitter dari daftar Neovim filetype; petakan alias seperti `c_sharp` ke `cs`, `tsx` ke `typescriptreact`, dan `bash` ke `sh`.
- [x] Pastikan `vim.treesitter.start()` benar-benar aktif pada buffer C#.
- [x] Jangan paksa Treesitter `indentexpr` untuk C# selama query indent `c_sharp` tidak tersedia; pertahankan indent bawaan C# Neovim.
- [x] Hormati `.editorconfig` project dan gunakan fallback indent empat spasi untuk C# bila project tidak menentukan.
- [x] Validasi dengan `:InspectTree`, `:setlocal indentexpr?`, dan `:AerialInfo` pada project C# nyata.

### P1: Indent And Scope Guides

- [x] Tambah `lukas-reineke/indent-blankline.nvim` (`ibl`) untuk garis indent statis dan active scope guide di source buffer.
- [x] Gunakan guide putih yang selalu terlihat untuk semua level dan hijau bold hanya untuk scope aktif.
- [x] Jangan aktifkan `mini.indentscope`, `hlchunk.nvim`, atau scope-guide lain bersamaan dengan IBL.
- [x] Nonaktifkan guides pada help, terminal, Telescope, dashboard, quickfix, serta generated/large files.
- [x] Batasi `nvim-treesitter-context` ke sekitar 3-5 sticky lines agar class/method context tidak mengambil terlalu banyak ruang.
- [x] Evaluasi `colorcolumn = 121`; pertahankan nonaktif karena targetnya indent/scope guide, bukan ruler 120 karakter.

### P1: Selective Symbol Usage Lens

- [x] Buat `symbol-usage.nvim` lebih informatif khusus C#, bukan lebih verbose secara global.
- [x] Tampilkan reference count untuk Class, Interface, Struct, Constructor, dan Method.
- [x] Tampilkan implementation count hanya untuk Class, Interface, dan Method.
- [x] Tetap nonaktifkan definition count serta Property/Field/Variable count pada tahap awal untuk menghindari noise dan request LSP berlebih.
- [x] Perbaiki zero-count suppression agar `0 usage` tidak muncul akibat nilai implementation yang `nil`.
- [x] Hilangkan pending text `loading...` dan tampilkan lens hanya setelah hasil tersedia.
- [x] Bandingkan posisi CodeLens-like `above` dengan `end_of_line` pada signature C# panjang; pilih `end_of_line` agar signature panjang tidak menambah baris virtual.
- [x] Tambah toggle per buffer serta guard untuk generated files dan file besar.
- [x] Pastikan highlight `SymbolUsage*` dipasang ulang setelah pergantian colorscheme.
- [x] Jangan aktifkan native LSP CodeLens bersamaan jika informasinya menduplikasi `symbol-usage.nvim`.

### P1: OOP Navigation

- [x] Prioritaskan backend LSP Roslyn untuk Aerial pada filetype `cs`, dengan Treesitter sebagai fallback.
- [x] Buat filter Aerial khusus C# untuk Namespace, Class, Interface, Struct, Enum, Constructor, Method, Property, Field, Event, dan EnumMember.
- [x] Keluarkan local Variable dari outline C# agar struktur type tetap terbaca.
- [x] Tambah navigasi type hierarchy untuk supertypes dan subtypes memakai API LSP native.
- [x] Tambah navigasi incoming dan outgoing call hierarchy melalui Trouble atau API LSP native.
- [x] Pertahankan Telescope untuk references, implementations, type definitions, dan workspace symbols sekali-pakai (`<leader>tw`).
- [x] Tambah breadcrumb `Namespace > Type > Member` pada winbar menggunakan Aerial/LSP tanpa menghilangkan nama file.
- [x] Evaluasi Treesitter folds; tunda aktivasi karena query C# belum melipat pasangan `#region` secara utuh dan pertahankan folds terbuka.
- [x] Review pengambilalihan mapping `{` dan `}` oleh Aerial terhadap native paragraph motions.

### P2: Static Typing Feedback

- [x] Aktifkan inlay hints hanya untuk C# dengan toggle buffer `<leader>th`.
- [x] Mulai dari inferred `var` types dan lambda parameter types; pertahankan parameter-name hints nonaktif agar tidak terlalu ramai.
- [x] Tambah LSP document highlight pada `CursorHold` dan bersihkan pada `CursorMoved`, `InsertEnter`, atau `BufLeave`.
- [x] Gunakan diagnostic virtual line hanya pada current line dan nonaktifkan virtual text pada semua baris.
- [x] Audit semantic tokens Roslyn: type utama memakai highlight bawaan, field/static mempertahankan Treesitter, deprecated sudah strikethrough, sedangkan readonly/abstract dikirim sebagai keyword; tidak perlu override tema.
- [x] Gunakan `<leader>t*` untuk struktur/static typing, `<leader>x*` untuk diagnostics, dan cadangkan `<leader>m*` untuk workflow .NET; pindahkan Git blame ke `<leader>gb`.

### Explicit Non-goals

- [x] Jangan tambah outline plugin kedua selama Aerial masih memenuhi kebutuhan.
- [x] Jangan tambah diagnostics UI kedua selama Trouble masih memenuhi kebutuhan.
- [x] Jangan tambah rainbow delimiters atau dekorasi warna per indent sebelum IBL yang minimal dievaluasi.
- [x] Jangan tampilkan seluruh metadata type secara permanen; detail penuh tetap on-demand lewat hover, Telescope, atau Trouble.

## Pre-list: easy-dotnet Optional Integrations

- [ ] Tambah parser Treesitter `sql` untuk language injection.
- [ ] Tambah parser Treesitter `json` untuk language injection.
- [ ] Evaluasi parser/integrasi Razor dengan `vscode-html-language-server`.
- [ ] Evaluasi `nvim-dap` dan DAP UI untuk debug aplikasi .NET.
- [ ] Evaluasi `netcoredbg`, `dncdbg`, atau `sharpdbg`.
- [ ] Evaluasi debug berdasarkan launch profile.
- [ ] Evaluasi attach debugger ke process yang sedang berjalan.
- [ ] Evaluasi debug test dari test runner.
- [ ] Evaluasi integrasi Neotest jika built-in test runner belum cukup.
- [ ] Evaluasi komponen lualine untuk active project, job, dan run status.
- [ ] Evaluasi integrasi nvim-tree, neo-tree, mini.files, atau Snacks explorer.

## Verification Candidates

- [ ] Validasi startup Neovim setelah perubahan konfigurasi.
- [ ] Validasi Treesitter attach, indentasi, scope guide, dan sticky context pada buffer C#.
- [ ] Pastikan hanya satu Roslyn client yang attach melalui `:LspInfo`.
- [ ] Ukur responsiveness `symbol-usage.nvim` pada file C# kecil, besar, dan generated.
- [ ] Audit konflik keymap sebelum dan sesudah easy-dotnet aktif.
- [ ] Validasi Blink menemukan snippet untuk filetype `cs`.
- [ ] Uji `<C-b>` secara interaktif setelah restart Neovim; callback dan source snippet-only sudah lulus headless.
- [ ] Uji `:CommentClean`, `gcc`, dan `<S-CR>` pada komentar C#.
- [ ] Uji autosave dan pastikan format-on-save Roslyn tetap berjalan.
- [ ] Periksa `:ConformInfo` dan `:LspInfo` pada project C#.
