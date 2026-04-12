return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },

	config = function()
		local harpoon = require("harpoon")
		harpoon:setup()

		-- 1. Tetap pakai keymap leader (leader-a dan ctrl-e)
		vim.keymap.set("n", "<leader>a", function()
			harpoon:list():add()
		end)
		vim.keymap.set("n", "<C-e>", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end)

		-- 2. Navigasi Sat-Set pakai < dan >
		vim.keymap.set("n", "<<", function()
			harpoon:list():prev()
		end)
		vim.keymap.set("n", ">>", function()
			harpoon:list():next()
		end)

		-- 4. Highlights (Tetap perlu biar retro)
		vim.cmd("highlight! HarpoonInactive guibg=NONE guifg=#63698c")
		vim.cmd("highlight! HarpoonActive guibg=NONE guifg=white")
	end,
}
