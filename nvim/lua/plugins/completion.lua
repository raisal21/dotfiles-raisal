return {
	"saghen/blink.cmp",
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	version = "1.*", -- lebih eksplisit dari '*'
	opts_extend = { "sources.default" }, -- PENTING: biar plugin lain bisa extend source tanpa override

	opts = {
		keymap = { preset = "default", ["<Tab>"] = { "accept", "fallback" } },

		appearance = {
			-- use_nvim_cmp_as_default sudah tidak ada di docs terbaru, hapus
			nerd_font_variant = "mono",
		},

		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},

		fuzzy = {
			-- Belum ada di configmu sebelumnya — Rust fuzzy matcher jauh lebih cepat
			implementation = "prefer_rust_with_warning",
		},

		cmdline = {
			keymap = { preset = "inherit" }, -- pakai keymap yang sama dengan insert mode
			completion = { menu = { auto_show = true } },
		},

		completion = {
			menu = {
				border = "single", -- retro: garis lurus, bukan bulat

				draw = {
					-- Tambah kolom 'kind' di kanan — ini yang kasih tau kamu Function/Keyword/Snippet
					-- Layout: [icon] [label + description]        [Function]
					columns = {
						{ "kind_icon" },
						{ "label", "label_description", gap = 1 },
						{ "kind" },
					},

					-- Tanda snippet jadi lebih jelas dengan ~ (default vim, cocok buat retro)
					snippet_indicator = "~",
				},
			},

			documentation = {
				-- Muncul otomatis saat navigasi item, dengan sedikit delay biar ga ganggu
				auto_show = true,
				auto_show_delay_ms = 300,
				window = { border = "single" },
			},

			ghost_text = {
				enabled = true,
				show_with_menu = true, -- ghost text tetap tampil walau menu terbuka
				show_without_menu = true, -- ghost text tampil bahkan saat menu tertutup
				show_with_selection = true, -- ikuti item yang sedang di-highlight
				show_without_selection = true,
			},
		},

		signature = {
			enabled = true,
			window = { border = "single" }, -- konsisten dengan menu dan docs
		},
	},
}
