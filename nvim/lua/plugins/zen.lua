return {
	"folke/zen-mode.nvim",
	cmd = "ZenMode",
	opts = {
		window = {
			width = 0.7, -- lebar jendela zen (85% dari layar)
			options = {
				wrap = true, -- Menyalakan pembungkusan teks
				linebreak = true, -- Memastikan kata tidak terpotong di tengah
				list = false, -- Menyembunyikan karakter tak terlihat (biar bersih)
				breakindent = true, -- Baris baru tetap sejajar indentasinya
				spell = true,
			},
		},
		plugins = {
			-- Opsional: matikan fitur lain yang mengganggu fokus
			options = {
				enabled = true,
				ruler = false, -- sembunyikan baris bawah
				showcmd = false,
			},
			twilight = { enabled = true }, -- redupkan teks di luar kursor
		},
	},
	-- Opsional: Tambahkan shortcut biar cepat panggilnya
	keys = {
		{ "<leader>zz", "<cmd>ZenMode<cr>", desc = "Toggle Zen Mode" },
	},
}
