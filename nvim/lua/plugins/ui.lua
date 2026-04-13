return {
	{
		"rebelot/kanagawa.nvim",
		name = "kanagawa", -- Wajib ada nama ini buat Lazy
		priority = 1000, -- Load paling pertama biar gak nge-blink
		config = function()
			require("kanagawa").setup({
				compile = true, -- CRACKED TIP: Compile cache biar startup nvim kenceng
				undercurl = true, -- Garis keriting buat error
				commentStyle = { italic = true },
				functionStyle = {},
				keywordStyle = { italic = true },
				statementStyle = { bold = true },
				typeStyle = {},
				transparent = true, -- Ubah true kalau mau background ikut Alacritty (transparan)
				dimInactive = false, -- Redupkan window yang gak aktif
				terminalColors = true, -- Ganti warna terminal bawaan nvim (:terminal)

				colors = {
					theme = {
						all = {
							ui = {
								bg_gutter = "none", -- Biar kolom nomor baris nyatu sama background
							},
						},
					},
				},

				overrides = function(colors)
					return {}
				end,

				theme = "dragon", -- Pilihan: wave (default), dragon (hitam), lotus (terang)
			})

			-- Perintah eksekusi tema
			vim.cmd("colorscheme kanagawa")
		end,
	},

	{
		"bluz71/vim-moonfly-colors",
		name = "moonfly",
		lazy = true,
		event = "VeryLazy",
		config = function()
			-- ==========================================
			-- 1. MAXIMALIST BUILT-IN OPTIONS
			-- ==========================================

			-- Menentukan apakah kursor akan diwarnai atau tidak (defaultnya tidak diwarnai).
			vim.g.moonflyCursorColor = true

			-- Menentukan apakah menggunakan italics untuk komentar dan elemen HTML tertentu.
			vim.g.moonflyItalics = true

			-- Menentukan apakah menggunakan warna background dan foreground moonfly di popup menu.
			vim.g.moonflyNormalPmenu = true
			-- Menentukan apakah menggunakan warna background dan foreground moonfly di floating windows Neovim.
			vim.g.moonflyNormalFloat = true
			-- Sangat direkomendasikan untuk mengaktifkan border floating window jika opsi moonflyNormalFloat disetel.
			vim.o.winborder = "single"

			-- Menentukan apakah menggunakan palet warna moonfly di window :terminal.
			vim.g.moonflyTerminalColors = true

			-- Menentukan apakah menggunakan background yang opaque atau transparan.
			vim.g.moonflyTransparent = true

			-- Menentukan apakah menggunakan undercurls untuk error spelling dan linting.
			vim.g.moonflyUndercurls = true

			-- Menentukan apakah akan memberikan garis bawah (underline) pada tanda kurung yang berpasangan.
			vim.g.moonflyUnderlineMatchParen = true

			-- Menentukan apakah akan menampilkan teks virtual diagnostik dengan warna.
			vim.g.moonflyVirtualTextColor = true

			-- Menentukan gaya pemisah window (angka 2 akan menampilkan pemisah berupa garis).
			vim.g.moonflyWinSeparator = 2
			-- Konfigurasi ini akan memperbaiki tampilan pemisah garis dengan memilih karakter yang lebih tebal untuk pemisahnya.
			vim.opt.fillchars = {
				horiz = "━",
				horizup = "┻",
				horizdown = "┳",
				vert = "┃",
				vertleft = "┫",
				vertright = "┣",
				verthoriz = "╋",
			}

			-- ==========================================
			-- 2. KANAGAWA-STYLE FUNCTIONAL HIGHLIGHTS
			-- ==========================================
			-- Jika suatu highlight tertentu dari tema ini dirasa kurang pas, direkomendasikan untuk menggunakan autocmd untuk menimpanya.

			local custom_highlight = vim.api.nvim_create_augroup("CustomHighlight", {})
			vim.api.nvim_create_autocmd("ColorScheme", {
				pattern = "moonfly",
				callback = function()
					-- Membuat highlight fungsi menjadi tebal (bold) menggunakan warna khusus.
					vim.api.nvim_set_hl(0, "Function", { fg = "#74b2ff", bold = true })

					-- Membuat keyword (seperti 'local', 'return', 'if') menjadi miring (italic).
					vim.api.nvim_set_hl(0, "Keyword", { italic = true })

					-- Membuat statement logika menjadi tebal (bold).
					vim.api.nvim_set_hl(0, "Statement", { bold = true })

					-- Membuat tipe data (string, number, table) menjadi miring (italic).
					vim.api.nvim_set_hl(0, "Type", { italic = true })
				end,
				group = custom_highlight,
			})
		end,
	},
}
