return {
	-- TELESCOPE (Fuzzy Finder)
	"nvim-telescope/telescope.nvim",
	tag = "v0.2.2",

	-- DEPENDENCIES:
	dependencies = { "nvim-lua/plenary.nvim" },

	-- CONFIG:
	config = function()
		local keymap = vim.keymap.set
		local builtin = require("telescope.builtin")

		-- Setup Keymaps (Shortcut)
		keymap("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" }) -- Cari file
		keymap("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" }) -- Cari text (grep)
		keymap("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" }) -- Cari buffer aktif
		keymap("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" }) -- Cari bantuan (help)
	end,
}
