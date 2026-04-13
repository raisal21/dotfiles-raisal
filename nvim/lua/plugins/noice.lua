return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},

	keys = {
		{
			"<leader>nl",
			function()
				require("noice").cmd("last")
			end,
			desc = "Noice: Last message",
		},
		{
			"<leader>nh",
			function()
				require("noice").cmd("history")
			end,
			desc = "Noice: History",
		},
		{
			"<leader>nd",
			function()
				require("noice").cmd("dismiss")
			end,
			desc = "Noice: Dismiss all",
		},
		{
			"<leader>ne",
			function()
				require("noice").cmd("errors")
			end,
			desc = "Noice: Errors",
		},
		-- Scroll LSP hover / signature docs dengan C-f / C-b
		{
			"<C-f>",
			function()
				if not require("noice.lsp").scroll(4) then
					return "<C-f>"
				end
			end,
			silent = true,
			expr = true,
			mode = { "n", "i", "s" },
			desc = "Scroll LSP doc forward",
		},
		{
			"<C-b>",
			function()
				if not require("noice.lsp").scroll(-4) then
					return "<C-b>"
				end
			end,
			silent = true,
			expr = true,
			mode = { "n", "i", "s" },
			desc = "Scroll LSP doc backward",
		},
	},

	opts = {

		-- ─── CMDLINE ──────────────────────────────────────────────────────────
		cmdline = {
			enabled = true,
			view = "cmdline_popup",
			format = {
				-- Icon ASCII-style agar tetap retro, tidak perlu nerd font berat
				cmdline = { pattern = "^:", icon = ">", lang = "vim" },
				search_down = { kind = "search", pattern = "^/", icon = "/", lang = "regex" },
				search_up = { kind = "search", pattern = "^%?", icon = "?", lang = "regex" },
				filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
				lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "~", lang = "lua" },
				help = { pattern = "^:%s*he?l?p?%s+", icon = "?" },
				input = { view = "cmdline_input", icon = ":" },
			},
			keymap = {
				preset = "inherit",
				["<Tab>"] = { "show_and_insert_or_accept_single", "select_next" },
				["<S-Tab>"] = { "show_and_insert_or_accept_single", "select_prev" },
			},
			completion = { menu = { auto_show = true } },
		},

		-- ─── MESSAGES ─────────────────────────────────────────────────────────
		messages = {
			enabled = true,
			view = "notify",
			view_error = "notify",
			view_warn = "notify",
			view_history = "messages", -- :Noice history pakai split buffer
			view_search = "virtualtext",
		},

		-- ─── NOTIFY (vim.notify) ──────────────────────────────────────────────
		notify = {
			enabled = true,
			view = "notify", -- pop up di pojok kanan bawah tanpa nvim-notify
		},

		-- ─── POPUPMENU ────────────────────────────────────────────────────────
		popupmenu = {
			enabled = true,
			backend = "nui",
			kind_icons = {}, -- tetap pakai kind icons dari noice
		},

		-- ─── LSP ──────────────────────────────────────────────────────────────
		lsp = {
			progress = {
				enabled = true,
				format = "lsp_progress",
				format_done = "lsp_progress_done",
				throttle = 1000 / 30,
				view = "mini", -- LSP loading spinner di pojok bawah, tidak ganggu
			},

			override = {
				-- Paksa Noice render markdown LSP pakai Treesitter (lebih bagus di hover docs)
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				-- Catatan: 'cmp.entry.get_documentation' TIDAK diset karena kita pakai blink.cmp
			},

			hover = {
				enabled = true,
				silent = true, -- tidak tampil pesan error kalau hover tidak tersedia
			},

			signature = {
				-- Dimatikan karena blink.cmp sudah handle signature help-nya sendiri.
				-- Mengaktifkan keduanya bisa menyebabkan popup double.
				enabled = false,
			},

			message = {
				enabled = true,
				view = "notify",
			},

			documentation = {
				view = "hover",
				opts = {
					lang = "markdown",
					replace = true,
					render = "plain",
					format = { "{message}" },
					win_options = { concealcursor = "n", conceallevel = 3 },
				},
			},
		},

		-- ─── PRESETS ──────────────────────────────────────────────────────────
		presets = {
			bottom_search = true, -- search (/ dan ?) tetap di bawah, klasik & retro
			command_palette = true, -- cmdline popup + popupmenu muncul bersama di tengah
			long_message_to_split = true, -- output panjang (>20 baris) otomatis ke split buffer
			inc_rename = false,
			lsp_doc_border = true, -- kita atur border hover secara manual di views
		},

		-- ─── VIEWS: semua border = 'single', no rounded ───────────────────────
		views = {
			notify = {
				border = { style = "single" },
				size = { width = 60, max_height = "50%" },
				win_options = {
					wrap = true,
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
				},
			},
			-- Notifikasi pop-up pojok kanan bawah (mini backend, built-in noice)
			mini = {
				timeout = 3000,
				reverse = false, -- pesan terbaru di bawah
				position = { row = -2, col = "100%" },
				border = { style = "none" }, -- mini tidak butuh border, posisi sudah jelas
				win_options = { winblend = 0 },
			},

			-- Cmdline popup (muncul di tengah layar karena command_palette = true)
			cmdline_popup = {
				border = { style = "single" },
				position = { row = "50%", col = "50%" },
				size = { width = 60, height = "auto" },
				win_options = {
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
				},
			},

			-- Popup generik (dipakai :Noice last, confirm, dsb.)
			popup = {
				border = { style = "single" },
				win_options = {
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
					wrap = true, -- [DITAMBAHKAN] Paksa teks di-wrap jika melebihi batas
				},
			},

			-- LSP hover docs dan sejenisnya
			hover = {
				border = { style = "single" },
				win_options = {
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
				},
			},
			-- Dialog konfirmasi (misal: `vim.ui.select`)
			confirm = {
				border = { style = "single" },
				win_options = {
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
				},
			},

			-- Split untuk history dan output panjang
			split = {
				enter = true, -- langsung masuk ke split saat terbuka
				border = { style = "single" },
				win_options = {
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
				},
			},
		},

		-- ─── ROUTES: filter pesan-pesan noisy ─────────────────────────────────
		routes = {
			{
				filter = {
					event = "msg_show",
					any = {
						{ find = "%d+L, %d+B" }, -- Menangkap pesan save (misal: "10L, 200B")
						{ find = "written" }, -- Menangkap pesan save eksplisit
						{ find = "yanked" }, -- Menangkap pesan copy (y)
						{ find = "fewer lines" }, -- Menangkap pesan hapus (d)
						{ find = "more lines" }, -- Menangkap pesan paste (p)
						{ find = "changes;" }, -- Menangkap pesan undo/redo (u / C-r)
						{ find = "already at newest" }, -- Pesan mentok saat redo
					},
				},
				opts = { skip = true },
			},

			{ filter = { event = "msg_show", kind = "search_count" }, opts = { skip = true } },
			{ filter = { event = "cmdline", find = "^%s*[wW]" }, opts = { skip = true } },
			-- Output command yang sangat panjang langsung ke split
			{
				view = "split",
				filter = { event = "msg_show", min_height = 10 },
			},

			{
				filter = {
					event = "cmdline",
					find = "^%s*[wWq]", -- match :w, :W, :wa, :wq, dll
				},
				opts = { skip = true },
			},
		},
	},
}
