return {
	"stevearc/aerial.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
		"nvim-telescope/telescope.nvim", -- Wajib buat integrasi fuzzy finder
	},
	keys = {
		-- Buka tutup outline window di kanan
		{ "<leader>o", "<cmd>AerialToggle!<CR>", desc = "Toggle Outline (Aerial)" },
		{ "<leader>fs", "<cmd>Telescope aerial<CR>", desc = "Find Symbols (Telescope)" },
	},
	opts = {
		-- 1. LAYOUT & ESTETIKA (Cocok dengan tema retro/border single kamu)
		layout = {
			max_width = { 40, 0.2 },
			width = 30,
			min_width = 10,
			default_direction = "right",
		},

		-- Garis hierarki (Tree guides)
		show_guides = true,
		guides = {
			mid_item = "├─",
			last_item = "└─",
			nested_top = "│ ",
			whitespace = "  ",
		},

		-- 2. NOISE FILTERING (Hanya tampilkan arsitektur penting)
		filter_kind = {
			"Class",
			"Constructor",
			"Enum",
			"Function",
			"Interface",
			"Module",
			"Method",
			"Struct",
			"Property", -- Wajib untuk C#
			"Field", -- Wajib untuk C#
			"Constant", -- Wajib untuk React Arrow Functions
			"Variable", -- Opsional: Nyalakan jika ingin melihat React State/Hooks
		},

		-- 3. HIJACK TOMBOL NAVIGASI ({ dan })
		-- Menggunakan on_attach adalah "Galaxy Brain Move".
		-- Kenapa? Karena tombol { dan } hanya akan di-hijack di file kode (Lua, JS, Python).
		-- Kalau kamu buka file teks biasa (.txt / markdown), { dan } tetap normal lompat paragraf!
		on_attach = function(bufnr)
			-- Lompat ke symbol sebelumnya
			vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr, desc = "Previous Symbol" })
			-- Lompat ke symbol selanjutnya
			vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr, desc = "Next Symbol" })

			-- Bonus: Lompat ke Parent Symbol (Keluar dari nested function ke function utama)
			vim.keymap.set("n", "[[", "<cmd>AerialPrevUp<CR>", { buffer = bufnr, desc = "Jump Up Symbol" })
			vim.keymap.set("n", "]]", "<cmd>AerialNextUp<CR>", { buffer = bufnr, desc = "Jump Down Symbol" })
		end,
	},

	-- Inject Aerial ke dalam Telescope secara otomatis
	config = function(_, opts)
		require("aerial").setup(opts)
		require("telescope").load_extension("aerial")
	end,
}
