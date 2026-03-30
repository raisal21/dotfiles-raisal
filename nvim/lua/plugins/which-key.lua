return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			spec = {
				-- Label untuk Harpoon
				{ "<leader>a", desc = "Add to Harpoon", icon = "󰐃" },
				{ "<leader>e", desc = "Harpoon Quick Menu", icon = "󰍜" },
				-- 󰎲, 󰎵, 󰎸, 󰎣 Ikon Angka Nerd Font untuk 7, 8, 9, 0
				{ "<leader>7", desc = "Harpoon File 1", icon = "󰎲" },
				{ "<leader>8", desc = "Harpoon File 2", icon = "󰎵" },
				{ "<leader>9", desc = "Harpoon File 3", icon = "󰎸" },
				{ "<leader>0", desc = "Harpoon File 4", icon = "󰎣" },

				{ "<leader>g", group = "Git" },
				{ "<leader>f", group = "Find/Telescope" },
				{ "<leader>t", group = "Trouble", icon = "󰚌" },
				{ "<leader>s", group = "Grug-far" },

				{ "<leader>w", desc = "Save File", icon = "󰆓" },
				{ "<leader>q", desc = "Quit / Exit", icon = "󰩈" },
				{ "<leader>|", desc = "Split Vertical", icon = "" },
				{ "<leader>v", desc = "Visual Block Mode", icon = "󰒄" },
			},
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},
}
