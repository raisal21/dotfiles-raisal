return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	opts = {
		options = {
			theme = "auto",
			globalstatus = true,
			-- RETRO LOOK: Pakai string kosong untuk transisi antar warna yang kaku (tegak lurus)
			-- Ini akan memberikan efek "Blocky" ala Windows NT atau BIOS.
			section_separators = { left = "", right = "" },
			-- Pakai pipa tipis sebagai pemisah komponen di dalam blok yang sama
			component_separators = { left = "│", right = "│" },
		},
		sections = {
			lualine_a = {
				{
					"mode",
					-- Format mode jadi huruf kapital semua dengan tanda strip ala terminal klasik
					fmt = function(str)
						return "-- " .. str:upper() .. " --"
					end,
				},
			},
			lualine_b = {
				{ "branch", icon = "" }, -- Ikon git minimalis
				{
					"diff",
					-- Pakai simbol ASCII standar untuk diff agar tetap retro
					symbols = { added = "+", modified = "~", removed = "-" },
				},
			},

			-- KOMPONEN C DIHAPUS: Sesuai request untuk dipindah ke Winbar nantinya
			lualine_c = {},

			lualine_x = {
				{
					"diagnostics",
					-- Gunakan inisial huruf untuk diagnostik, bukan ikon besar
					symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" },
				},
				"filetype",
			},
			lualine_y = {
				{
					"progress",
					fmt = function(str)
						return "pos: " .. str
					end,
				},
			},
			lualine_z = {
				{
					"location",
					-- Format lokasi baris/kolom dengan prefix kaku
					fmt = function(str)
						return "ln: " .. str
					end,
				},
			},
		},
	},
}
