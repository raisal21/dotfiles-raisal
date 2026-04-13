return {
	"kevinhwang91/nvim-hlslens",
	config = function()
		local hlslens = require("hlslens")

		hlslens.setup({
			-- Efek "Retro Visual": Menggunakan karakter blok dan border tajam
			override_lens = function(render, posList, nearest, idx, relIdx)
				local lnum, col = unpack(posList[idx])
				local text, virt_str
				if nearest then
					local cnt = #posList
					if relIdx ~= 0 then
						text = string.format(" [%d/%d %d] ", idx, cnt, relIdx)
					else
						text = string.format(" [%d/%d] ", idx, cnt)
					end
					virt_str = { { text, "IncSearch" } }
				else
					text = string.format(" %d ", idx)
					virt_str = { { text, "Search" } }
				end

				-- PERBAIKAN: Menambahkan '0' (buffer saat ini) dan 'nearest'
				render.setVirt(0, lnum - 1, col - 1, virt_str, nearest)
			end,
		})

		-- Keymaps agar navigasi terasa responsif
		local opts = { noremap = true, silent = true }

		vim.api.nvim_set_keymap(
			"n",
			"n",
			[[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
			opts
		)
		vim.api.nvim_set_keymap(
			"n",
			"N",
			[[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
			opts
		)
		vim.api.nvim_set_keymap("n", "*", [[*<Cmd>lua require('hlslens').start()<CR>]], opts)
		vim.api.nvim_set_keymap("n", "#", [[#<Cmd>lua require('hlslens').start()<CR>]], opts)
		vim.api.nvim_set_keymap("n", "g*", [[g*<Cmd>lua require('hlslens').start()<CR>]], opts)
		vim.api.nvim_set_keymap("n", "g#", [[g#<Cmd>lua require('hlslens').start()<CR>]], opts)
	end,
}
