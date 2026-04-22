return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"saghen/blink.cmp",
		"b0o/SchemaStore.nvim",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/lazydev.nvim", opts = {} },
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = {
				"ts_ls",
				"html",
				"cssls",
				"jsonls",
				"tailwindcss",
				"lua_ls",
				"emmet_ls",
				"pyright",
			},
		})

		-- ✅ API baru Neovim 0.11+
		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		-- Override khusus per server
		vim.lsp.config("jsonls", {
			settings = {
				json = {
					schemas = require("schemastore").json.schemas(),
					validate = { enable = true },
				},
			},
		})

		vim.lsp.config("emmet_ls", {
			filetypes = {
				"html",
				"typescriptreact",
				"javascriptreact",
				"css",
				"sass",
				"scss",
				"less",
			},
		})

		-- ✅ Enable semua server yang sudah di-install Mason
		vim.lsp.enable({
			"ts_ls",
			"html",
			"cssls",
			"jsonls",
			"tailwindcss",
			"lua_ls",
			"emmet_ls",
			"pyright",
		})
	end,
}
