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
		local conf = require("telescope.config").values
		local finders = require("telescope.finders")
		local make_entry = require("telescope.make_entry")
		local pickers = require("telescope.pickers")
		local keymap = vim.keymap.set

		-- Ambil multi-selection, fallback ke current entry jika tidak ada
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
						["<C-a>"] = function(prompt_bufnr)
							local selections = get_selections(prompt_bufnr)
							if #selections == 0 then
								print("󰐃 Nothing selected")
								return
							end

							local list = harpoon:list()
							local count = 0

							for _, entry in ipairs(selections) do
								-- Ambil path (utamakan relative)
								local raw_path = entry.value or entry[1] or entry.path or entry.filename
								if raw_path then
									-- Paksa path menjadi relative terhadap Current Working Directory (CWD)
									local path = vim.fn.fnamemodify(raw_path, ":.")

									-- Cegah duplikasi item di list Harpoon
									local exists = false
									for _, item in ipairs(list.items) do
										if item.value == path then
											exists = true
											break
										end
									end

									if not exists then
										-- Gunakan append dengan struktur Harpoon 2 yang valid (butuh context)
										list:append({
											value = path,
											context = { row = 1, col = 0 },
										})
										count = count + 1
									end
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
						local function delete_marked()
							local selections = get_selections(prompt_bufnr)
							if #selections == 0 then
								print("󰐃 Nothing to delete")
								return
							end

							local list = harpoon:list()

							-- 1. Buat peta (lookup table) dari file yang ingin dihapus
							local to_remove = {}
							for _, entry in ipairs(selections) do
								-- Untuk finder new_table, value string murni ada di entry[1] atau entry.value
								local target = entry[1] or entry.value
								if target then
									to_remove[target] = true
								end
							end

							-- 2. Bangun ulang list dengan mengabaikan file yang masuk ke daftar to_remove
							local new_items = {}
							local count = 0

							for _, item in ipairs(list.items) do
								if not to_remove[item.value] then
									table.insert(new_items, item)
								else
									count = count + 1
								end
							end

							-- 3. Timpa (overwrite) item harpoon dengan list yang sudah bersih
							list.items = new_items

							print("󰐃 Removed " .. count .. " file(s) from Harpoon")
							actions.close(prompt_bufnr)

							-- Buka kembali picker hanya jika Harpoon belum kosong
							if #list.items > 0 then
								vim.schedule(function()
									manage_harpoon()
								end)
							end
						end

						map("i", "<C-d>", delete_marked)
						map("n", "d", delete_marked)

						return true
					end,
				})
				:find()
		end

		-- Exact/Regex search function using Ripgrep STRICTLY in the current file
		local function search_current_file_only()
			local current_file = vim.api.nvim_buf_get_name(0)

			if current_file == "" or not vim.uv.fs_stat(current_file) then
				print("󰐃 File not saved to disk. Ripgrep requires a physical file.")
				return
			end

			builtin.live_grep({
				prompt_title = "Current Buffer",
				search_dirs = { current_file },

				-- INI KUNCINYA: Menyembunyikan nama file/path dari hasil pencarian
				path_display = "hidden",

				-- Mematikan sorter bawaan agar hasil urut sesuai nomor baris dari atas ke bawah
				sorter = require("telescope.sorters").empty(),
			})
		end

		local function live_multigrep(opts)
			opts = opts or {}
			opts.cwd = opts.cwd or vim.uv.cwd()

			-- Membuat proses pencarian berjalan di latar belakang (async) agar Neovim tidak nge-freeze
			local finder = finders.new_async_job({
				command_generator = function(prompt)
					if not prompt or prompt == "" then
						return nil
					end

					-- PECAH PROMPT: Kita gunakan DUA SPASI sebagai pemisah
					local pieces = vim.split(prompt, "  ")
					local args = { "rg" }

					-- 1. Bagian pertama adalah teks yang ingin dicari (-e)
					if pieces[1] then
						table.insert(args, "-e")
						table.insert(args, pieces[1])
					end

					-- 2. Bagian kedua adalah filter file/folder (-g) menggunakan glob
					if pieces[2] then
						table.insert(args, "-g")
						table.insert(args, pieces[2])
					end

					-- Argumen wajib Ripgrep agar outputnya bisa dibaca dan diwarnai oleh Telescope
					local rg_defaults = {
						"--color=never",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
						"--smart-case",
					}

					for _, v in ipairs(rg_defaults) do
						table.insert(args, v)
					end

					return args
				end,

				-- Mengubah output Ripgrep menjadi baris-baris hasil di layar Telescope
				entry_maker = make_entry.gen_from_vimgrep(opts),
				cwd = opts.cwd,
			})

			pickers
				.new(opts, {
					debounce = 100, -- Jeda 100ms saat mengetik agar tidak membebani CPU
					prompt_title = "Multi Grep",
					finder = finder,
					previewer = conf.grep_previewer(opts),
					-- Mematikan sorting Telescope agar Ripgrep yang mengambil alih urutannya
					sorter = require("telescope.sorters").empty(),
				})
				:find()
		end

		keymap("n", "<leader>/", search_current_file_only, { desc = "Regex Search Current File" })
		keymap("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
		keymap("n", "<leader>fg", live_multigrep, { desc = "Live Grep" })
		keymap("n", "<leader>fc", builtin.colorscheme, { desc = "Colorscheme" })
		keymap("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })
		keymap("n", "<leader>fh", manage_harpoon, { desc = "Manage Harpoon List" })
	end,
}
