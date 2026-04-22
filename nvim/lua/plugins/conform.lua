return {
	"stevearc/conform.nvim",
	-- Lazy loading: Hanya dimuat saat kamu membuka atau membuat file baru
	event = { "BufReadPre", "BufNewFile" },

	config = function()
		require("conform").setup({
			-- 1. TENTUKAN FORMATTER UNTUK TIAP BAHASA
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				-- python = { "isort", "black" }, -- Bisa pakai banyak formatter berurutan!
			},

			-- 2. MAGIC: OTOMATIS RAPI SAAT DI-SAVE
			format_on_save = {
				-- Kalau formatter (misal prettier) gagal/nggak ada, pakai LSP bawaan
				lsp_fallback = true,
				async = false,
				timeout_ms = 500, -- Kalau dalam 0.5 detik gagal nge-format, batalkan aja biar Neovim nggak nge-freeze
			},
		})

		-- 3. SHORTCUT MANUAL (Biar masuk ke Which-Key yang sudah kita bikin estetik!)
		-- Bisa di mode Normal (n) atau Visual block (v)
		vim.keymap.set({ "n", "v" }, "<leader>f", function()
			require("conform").format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 500,
			})
		end, { desc = "Format code", icon = "󰉩" })
	end,
}
