return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	lazy = false,
	-- Lazy loading: Oil hanya jalan kalau kamu panggil command :Oil atau pencet tombol '-'
	-- cmd = "Oil",
	keys = {
		{ "-", "<cmd>Oil<cr>", desc = "Buka direktori parent (Oil)" },
		{ "<leader>-", "<cmd>Oil --float<cr>", desc = "Buka direktori di floating window (Oil)" },
	},
	opts = {
		win_options = {
			-- 1. Spasi kosong di awal memberikan "Left Padding"
			-- 2. Menggunakan highlight standar (String, Comment, WarningMsg) agar cocok di semua tema
			-- 3. Menggunakan pemisah vertikal tipis (│) bukan pipa biasa (|) agar terlihat lebih premium
			winbar = "%#WarningMsg#  󰏇 OIL EXPLORER  %#Comment#│  %#String#[-] %#Comment#Parent  %#Comment#│  %#String#[_] %#Comment#CWD  %#Comment#│  %#String#[<CR>] %#Comment#Open  %#Comment#│  %#String#[<C-p>] %#Comment#Preview  %#Comment#│  %#String#[<C-s>] %#Comment#Split  %#Comment#│  %#String#[g?] %#Comment#Help",

			-- Opsional: Menyembunyikan nomor baris di dalam Oil biar layarnya murni untuk file
			number = false,
			relativenumber = false,
			signcolumn = "no",
		},

		-- 1. PENGATURAN DASAR (BEHAVIOR)
		default_file_explorer = true,
		delete_to_trash = true, -- Wajib! Mencegah tragedi salah hapus permanen.
		skip_confirm_for_simple_edits = true, -- Sat-set. Ganti nama/hapus 1 file nggak usah ditanya "Yakin?".
		prompt_save_on_select_new_entry = true,
		cleanup_delay_ms = 2000,
		constrain_cursor = "editable", -- Kursor nggak bakal nyasar ke area icon atau size, fokus di nama file.

		-- 2. TAMPILAN & INFORMASI (KOLOM)
		-- Sebagai power user, kita butuh informasi lengkap layaknya `ls -lh`
		columns = {
			"icon",
			"permissions",
			"size",
			"mtime", -- Modified time (waktu terakhir diubah)
		},

		-- 3. VISIBILITAS FILE (VIEW OPTIONS)
		view_options = {
			show_hidden = true, -- Selalu tampilkan dotfiles (.env, .gitignore, dll)
			is_always_hidden = function(name, _)
				-- Sembunyikan folder .git atau .DS_Store secara paksa agar rapi
				return name == ".git" or name == ".DS_Store"
			end,
			natural_order = true, -- Urutkan file bernomor secara logis (file2 > file10, bukan file10 > file2)
			sort = {
				{ "type", "asc" }, -- Folder di atas, file di bawah
				{ "name", "asc" }, -- Urut abjad
			},
		},

		-- 4. INTEGRASI CERDAS (LSP & GIT)
		lsp_file_methods = {
			enabled = true,
			timeout_ms = 1000,
			autosave_changes = true, -- MAGIC FEATURE: Ganti nama file di Oil, semua import di file lain otomatis diganti dan di-save!
		},
		git = {
			-- Opsional: Otomatis git add/mv/rm kalau kita modifikasi file via Oil
			add = function(_)
				return false
			end,
			mv = function(_, _)
				return true
			end,
			rm = function(_)
				return true
			end,
		},

		-- 5. FLOATING WINDOW (UI ESTETIKA)
		float = {
			padding = 2,
			max_width = 100,
			max_height = 0.8,
			border = "rounded",
			win_options = {
				winblend = 10, -- Efek transparan (buat background gelap)
			},
			preview_split = "auto",
		},

		-- 6. PREVIEW WINDOW
		preview_win = {
			update_on_cursor_moved = true,
			preview_method = "fast_scratch",
			disable_preview = function(filename)
				-- Jangan preview file terlalu besar biar Neovim nggak nge-freeze
				local stats = vim.uv.fs_stat(filename)
				return stats and stats.size > 100 * 1024 -- Disable jika > 100KB
			end,
		},

		-- 7. KEYMAPS INTERNAL OIL
		use_default_keymaps = false, -- Kita matikan bawaan agar bisa kita kontrol penuh
		keymaps = {
			["g?"] = { "actions.show_help", desc = "Show help menu" },
			["<CR>"] = { "actions.select", desc = "Open file or directory" },
			["<C-s>"] = { "actions.select", opts = { vertical = true }, desc = "Open in vertical split" },
			["<C-h>"] = { "actions.select", opts = { horizontal = true }, desc = "Open in horizontal split" },
			["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },
			["<C-p>"] = { "actions.preview", desc = "Toggle preview window" },
			["<C-c>"] = { "actions.close", desc = "Close Oil" },
			["<C-l>"] = { "actions.refresh", desc = "Refresh Oil buffer" },
			["-"] = { "actions.parent", desc = "Go to parent directory" },
			["_"] = { "actions.open_cwd", desc = "Open current working directory" },
			["`"] = { "actions.cd", desc = "Change directory (:cd)" },
			["~"] = { "actions.cd", opts = { scope = "tab" }, desc = "Change tab directory (:tcd)" },
			["gs"] = { "actions.change_sort", desc = "Change sorting order" },
			["gx"] = { "actions.open_external", desc = "Open in external app" },
			["g."] = { "actions.toggle_hidden", desc = "Toggle hidden files" },
			["g\\"] = { "actions.toggle_trash", desc = "Toggle trash view" },
		},
	},
}
