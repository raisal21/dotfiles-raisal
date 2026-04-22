return {
	"folke/flash.nvim",
	event = "VeryLazy",
	---@type Flash.Config
	opts = {
		search = {
			-- Memodifikasi pola pencarian
			mode = function(str)
				-- Menambahkan "\<" (awal kata) ke string yang diketik
				return "\\<" .. str
			end,
		},
	},
	keys = {
		{
			"s",
			mode = { "n", "x", "o" },
			function()
				require("flash").jump()
			end,
			desc = "Flash",
		},
		{
			"S",
			mode = { "n", "x", "o" },
			function()
				require("flash").treesitter()
			end,
			desc = "Flash Treesitter",
		},
		{
			"<c-s>",
			mode = { "c" },
			function()
				require("flash").toggle()
			end,
			desc = "Toggle Flash Search",
		},
		{
			"<leader>l", -- ganti dengan shortcut favoritmu
			mode = { "n", "x", "o" },
			function()
				require("flash").jump({
					search = { mode = "search", max_length = 0 },
					label = { after = { 0, 0 } },
					pattern = "^",
				})
			end,
			desc = "Flash Line Jump",
		},
	},
}
