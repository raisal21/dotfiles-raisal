local opt = vim.opt

-- Tampilan Interface (UI)
opt.number = true             -- Tampilkan nomor baris
opt.relativenumber = true     -- Tampilkan nomor relatif (Wajib buat lompat baris cepat '10j' atau '5k')
opt.cursorline = true         -- Highlight baris tempat kursor berada (fokus visual)
opt.termguicolors = true      -- Wajib untuk tema modern (Catppuccin, Tokyonight)
opt.signcolumn = "yes"        -- Selalu sediakan kolom di kiri (biar layar ga goyang pas ada git sign/error)

-- Tab & Indentasi (Standar Coding Modern)
opt.tabstop = 4               -- 1 Tab = 4 Spasi (Visual)
opt.shiftwidth = 4            -- Auto indent = 4 Spasi
opt.expandtab = true          -- Ubah Tab jadi Spasi (Standar Python/JS modern biar ga error beda OS)
opt.smartindent = true        -- Neovim menebak indentasi baru dengan cerdas

-- Perilaku Editing
opt.wrap = false              -- Jangan turunkan teks panjang ke bawah (biar kode tetap rapi horizontal)
opt.ignorecase = true         -- Search 'hello' akan ketemu 'Hello'
opt.smartcase = true          -- Tapi kalau search 'Hello', dia strict case sensitive
opt.updatetime = 50           -- Percepat update UI (default 4000ms terlalu lambat buat plugin git/LSP)
opt.scrolloff = 8             -- **PENTING**: Biarkan 8 baris sisa di atas/bawah kursor saat scroll (Jaga konteks)

-- System Integration (WSL2 Specific)
opt.clipboard = "unnamedplus" -- Hubungkan clipboard Neovim dengan Windows (via xclip di WSL)
opt.mouse = "a"               -- Mouse tetap aktif (kadang berguna buat resize window split)
opt.splitright = true         -- Vertical split muncul di kanan
opt.splitbelow = true         -- Horizontal split muncul di bawah

-- Swap & Backup (Biar direktori kerja bersih)
opt.swapfile = false          -- Jangan buat file .swp sampah
opt.backup = false
opt.undofile = true           -- Simpan history undo di file (biar bisa undo meski neovim sudah ditutup)

-- Leader Key (Tombol Paling Penting)
vim.g.mapleader = ' '	      -- Space bar sebagai leader
vim.g.maplocalleader = "\\"
