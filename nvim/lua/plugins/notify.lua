return {
	"rcarriga/nvim-notify",
	lazy = true, -- dimuat saat dipanggil noice atau vim.notify pertama kali

	opts = {
		-- ─── TAMPILAN ──────────────────────────────────────────────────────────
		-- "compact" : judul + ikon level di baris atas, pesan di bawahnya.
		--             Paling informatif dan retro — tidak ada padding tebal.
		-- Alternatif yang lebih minimal: "minimal" (tanpa judul/ikon sama sekali)
		render = "compact",

		-- Tidak ada animasi fade/opacity — langsung muncul dan slide ke luar.
		-- Paling "terminal-like" dan tidak buang CPU.
		stages = "slide",

		-- ─── UKURAN & POSISI ───────────────────────────────────────────────────
		top_down = true, -- notifikasi terbaru di atas (kanan atas layar)
		minimum_width = 30,
		-- max_width dan max_height bisa di-set juga jika perlu:
		-- max_width  = 60,
		-- max_height = 10,

		-- ─── TIMING ───────────────────────────────────────────────────────────
		fps = 30,
		timeout = 4000, -- 4 detik cukup untuk dibaca, tidak terlalu lama

		-- ─── ICON ASCII — konsisten dengan gaya retro ─────────────────────────
		-- Tidak pakai nerd font icon berat, cukup simbol ASCII/unicode sederhana
		icons = {
			ERROR = "E",
			WARN = "W",
			INFO = "I",
			DEBUG = "D",
			TRACE = "T",
		},

		-- ─── BORDER SINGLE via on_open ─────────────────────────────────────────
		-- nvim-notify tidak punya opsi border langsung, harus lewat on_open
		on_open = function(win)
			vim.api.nvim_win_set_config(win, { border = "single" })
		end,

		-- ─── LEVEL MINIMUM ────────────────────────────────────────────────────
		-- Hanya tampilkan INFO ke atas (sembunyikan DEBUG & TRACE di production)
		level = vim.log.levels.INFO,
	},

	config = function(_, opts)
		require("notify").setup(opts)

		-- Set sebagai vim.notify global agar semua notifikasi lewat sini,
		-- termasuk dari plugin lain yang tidak lewat noice.
		-- (Noice akan override ini lagi lewat routing-nya sendiri,
		--  tapi ini fallback yang aman kalau noice belum load.)
		vim.notify = require("notify")
	end,
}
