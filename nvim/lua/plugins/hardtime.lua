return {
	"m4xshen/hardtime.nvim",
	dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
	opts = {
		max_count = 3,

		restricted_keys = {
			["j"] = { "n", "x", count = 3 },
			["k"] = { "n", "x", count = 3 },

			["+"] = { "n", "x", count = 0 },
			["-"] = { "n", "x", count = 0 },
		},
	},
}
