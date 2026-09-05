local opt = vim.opt

-- Tampilan Interface (UI)
opt.number = true -- Tampilkan nomor baris
opt.relativenumber = true -- Tampilkan nomor relatif (Wajib buat lompat baris cepat '10j' atau '5k')
opt.cursorline = true -- Highlight baris tempat kursor berada (fokus visual)
opt.termguicolors = true -- Wajib untuk tema modern (Catppuccin, Tokyonight)
opt.signcolumn = "yes" -- Selalu sediakan kolom di kiri (biar layar ga goyang pas ada git sign/error)

-- Tab & Indentasi (Standar Coding Modern & Prettier)
opt.tabstop = 2 -- 1 Tab = 2 Spasi (Visual)
opt.shiftwidth = 2 -- Auto indent = 2 Spasi
opt.expandtab = true -- Ubah Tab jadi Spasi (Standar web dev modern)
opt.smartindent = true -- Neovim menebak indentasi baru dengan cerdas

-- Perilaku Editing
opt.wrap = false -- Jangan turunkan teks panjang ke bawah (biar kode tetap rapi horizontal)
opt.ignorecase = true -- Search 'hello' akan ketemu 'Hello'
opt.smartcase = true -- Tapi kalau search 'Hello', dia strict case sensitive
opt.updatetime = 250 -- responsive untuk gitsigns/LSP CursorHold, tidak boros syscall
vim.opt.shortmess:append("Wsa") -- skip "written"/search/abbrev messages (replace noice route filters)
vim.o.ttimeoutlen = 100 -- Beri waktu untuk CSI terminal seperti <S-CR>
opt.scrolloff = 8 -- **PENTING**: Biarkan 8 baris sisa di atas/bawah kursor saat scroll (Jaga konteks)
opt.smoothscroll = true
opt.textwidth = 120
opt.confirm = true
opt.showtabline = 0 -- hide tabline (tmux handle windows/tabs)
opt.path = ".,**" -- gf recursive dari cwd

-- System Integration (WSL2 Specific)
opt.clipboard = "unnamedplus" -- Hubungkan clipboard Neovim dengan Windows (via xclip di WSL)
opt.mouse = "a" -- Mouse tetap aktif (kadang berguna buat resize window split)
opt.splitright = true -- Vertical split muncul di kanan
opt.splitbelow = true -- Horizontal split muncul di bawah

-- Auto-reload when file changed externally (agent edits, git checkout, etc.)
opt.autoread = true

-- Swap & Backup (Biar direktori kerja bersih)
opt.swapfile = false -- Jangan buat file .swp sampah
opt.backup = false
opt.undofile = true -- Simpan history undo di file (biar bisa undo meski neovim sudah ditutup)

-- Leader Key (Tombol Paling Penting)
vim.g.mapleader = " " -- Space bar sebagai leader
vim.g.maplocalleader = "\\"

-- Highlight teks sejenak saat di-yank (copy)
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight teks saat yank",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch", -- Warna highlight (bisa diganti "Visual" kalau mau beda)
      timeout = 200, -- Durasi highlight dalam milidetik
    })
  end,
})
