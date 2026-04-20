return {
	"neovim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false, -- WAJIB: Plugin ini sekarang tidak mendukung lazy-loading
	build = ":TSUpdate",
	dependencies = {
		"neovim-treesitter/treesitter-parser-registry",
	},
	config = function()
		-- Daftar bahasa yang ingin diinstall
		local langs = {
			-- Bahasa Dasar & Config
			"c",
			"lua",
			"vim",
			"vimdoc",
			"query",
			"bash",

			-- Web Development (Basic)
			"html",
			"css",
			"javascript",
			"typescript",
			"python",

			-- TAMBAHAN BARU KAMU:
			"c_sharp",
			"xml",
			"yaml",
			"toml",
			"astro",
			"tsx",
			"zsh", -- Tambahan baru
			"tmux",
		}

		-- 1. Install parsers & queries (Menggantikan `ensure_installed`)
		require("nvim-treesitter").install(langs)

		-- 2. Aktifkan fitur per-bahasa (Menggantikan `highlight` dan `indent` di setup lama)
		-- Fitur ini TIDAK aktif secara otomatis di versi baru.
		vim.api.nvim_create_autocmd("FileType", {
			pattern = langs,
			callback = function()
				-- Mengaktifkan Highlighting
				vim.treesitter.start()

				-- Mengaktifkan Treesitter Folds (Opsional, bawaan Neovim)
				-- vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				-- vim.wo.foldmethod = "expr"

				-- Mengaktifkan Treesitter Indentation
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})
	end,
}
