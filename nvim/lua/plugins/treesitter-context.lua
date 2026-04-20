return {
	"nvim-treesitter/nvim-treesitter-context",
	-- Load otomatis saat ngebuka atau bikin file baru
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },
	-- Pastikan treesitter utama jalan duluan
	dependencies = { "neovim-treesitter/nvim-treesitter" },

	opts = {
		enable = true,
		line_numbers = true,

		-- Kalau deklarasi fungsi panjang ke bawah, ambil baris pertamanya aja
		multiline_threshold = 1,
		trim_scope = "outer",
		mode = "cursor", -- Kalkulasi konteks berdasarkan kursor, lebih presisi
	},

	config = function(_, opts)
		require("treesitter-context").setup(opts)

		-- Tambahan Bonus: Shortcut buat nyalain/matiin kalau lagi sumpek
		-- Kamu bisa pakai <leader>tc (Toggle Context)
		vim.keymap.set("n", "<leader>tc", function()
			require("treesitter-context").toggle()
		end, { desc = "Toggle Treesitter Context" })
	end,
}
