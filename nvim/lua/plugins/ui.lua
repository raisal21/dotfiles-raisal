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
		"kylesnowschwartz/cobalt-neon.nvim",
		lazy = true,
	},

	-- Katalog lengkap Black Metal (Termasuk varian Venom, Bathory, dll)
	{
		"metalelf0/black-metal-theme-neovim",
		lazy = true,
	},

	-- Estetika Retro Synthwave 84
	{
		"LunarVim/synthwave84.nvim",
		lazy = true,
	},
}
