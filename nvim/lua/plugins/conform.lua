return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.6",
	dependencies = { "nvim-lua/plenary.nvim" },

	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")
		local builtin = require("telescope.builtin")
		local harpoon = require("harpoon")
		local keymap = vim.keymap.set

		-- Helper: ambil path dari entry (support berbagai finder)
		local function get_entry_path(entry)
			return entry.filename or entry.value or entry[1]
		end

		-- Helper: ambil selections (multi jika ada, fallback ke current)
		local function get_selections(prompt_bufnr)
			local picker = action_state.get_current_picker(prompt_bufnr)
			local multi = picker:get_multi_selection()
			if #multi > 0 then
				return multi
			end
			local current = action_state.get_selected_entry()
			if current then
				return { current }
			end
			return {}
		end

		telescope.setup({
			defaults = {
				borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
				mappings = {
					i = {
						-- Bulk add: Tab untuk tandai, Ctrl-a untuk tambah semua ke Harpoon
						["<C-a>"] = function(prompt_bufnr)
							local selections = get_selections(prompt_bufnr)
							if #selections == 0 then
								print("󰐃 Nothing selected")
								return
							end

							local list = harpoon:list()
							local count = 0
							for _, entry in ipairs(selections) do
								local path = get_entry_path(entry)
								if path then
									list:add({ value = path })
									count = count + 1
								end
							end

							actions.close(prompt_bufnr)
							print("󰐃 Added " .. count .. " file(s) to Harpoon")
						end,

						["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
						["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
					},
				},
			},
		})

		-- Manage Harpoon: lihat list, Tab untuk tandai, Ctrl-d untuk hapus
		local function manage_harpoon()
			local conf = require("telescope.config").values
			local file_paths = {}

			for _, item in ipairs(harpoon:list().items) do
				table.insert(file_paths, item.value)
			end

			if #file_paths == 0 then
				print("󰐃 Harpoon list is empty")
				return
			end

			require("telescope.pickers")
				.new({}, {
					prompt_title = "Harpoon ─ <Tab> mark │ <C-d>/<d> delete",
					finder = require("telescope.finders").new_table({ results = file_paths }),
					previewer = conf.file_previewer({}),
					sorter = conf.generic_sorter({}),

					attach_mappings = function(prompt_bufnr, map)
						-- Wajib remap Tab di sini juga agar multi-select aktif di custom picker
						map("i", "<Tab>", actions.toggle_selection + actions.move_selection_worse)
						map("i", "<S-Tab>", actions.toggle_selection + actions.move_selection_better)
						map("n", "<Tab>", actions.toggle_selection + actions.move_selection_worse)

						local function delete_marked()
							local selections = get_selections(prompt_bufnr)
							if #selections == 0 then
								print("󰐃 Nothing to delete")
								return
							end

							local list = harpoon:list()

							-- Kumpulkan index yang akan dihapus (jangan hapus sambil iterasi!)
							local indices_to_delete = {}
							for _, entry in ipairs(selections) do
								local target = get_entry_path(entry)
								for i, item in ipairs(list.items) do
									if item.value == target then
										table.insert(indices_to_delete, i)
										break
									end
								end
							end

							-- Hapus dari index terbesar ke terkecil agar index tidak bergeser
							table.sort(indices_to_delete, function(a, b)
								return a > b
							end)
							for _, idx in ipairs(indices_to_delete) do
								list:removeAt(idx)
							end

							print("󰐃 Removed " .. #indices_to_delete .. " file(s) from Harpoon")
							actions.close(prompt_bufnr)
							vim.schedule(function()
								manage_harpoon()
							end)
						end

						map("i", "<C-d>", delete_marked)
						map("n", "d", delete_marked)

						return true
					end,
				})
				:find()
		end

		-- Keymaps
		keymap("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
		keymap("n", "<leader>fg", builtin.live_grep, { desc = "Live Grep" })
		keymap("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
		keymap("n", "<leader>hm", manage_harpoon, { desc = "Manage Harpoon List" })
		keymap("n", "<leader>fz", builtin.current_buffer_fuzzy_find, { desc = "Fuzzy Find Buffer" })
	end,
}
