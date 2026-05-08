return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
	-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
	-- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		pipe_table = {
			-- Fitur ini akan merender tabel dengan border yang cantik
			-- dan berusaha menjaga tampilan sel tetap rapi.
			preset = "double",
			enabled = true,
			style = "full", -- atau "grid"
			cell = "overlay",
		},
	},
}
