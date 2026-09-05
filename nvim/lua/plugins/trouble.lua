return {
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "Trouble", -- Load cuma pas dipanggil
    opts = {
      focus = true, -- Tetap fokus ke window pas dibuka
      modes = {
        diagnostics = {
          keys = {
            -- "jump" untuk pindah ke kode, "close = true" untuk otomatis tutup window Trouble
            ["<cr>"] = "jump_close",
            ["o"] = "jump_close",
          },
          win = {
            type = "float",
            relative = "editor",
            border = "single", -- "single" memberikan corner tajam/kotak
            title = " Diagnostics ",
            title_pos = "center",
            -- Posisi: { baris, kolom } -> 0.3 berarti agak ke atas
            position = { 0.25, 0.5 },
            size = { width = 0.6, height = 0.3 },
            zindex = 200,
          },
          preview = {
            type = "float",
            relative = "editor",
            border = "single", -- Samakan jadi kotak
            title = " Preview ",
            title_pos = "center",
            -- Diatur agar di bawah Diagnostics (0.3 + 0.3 height + gap)
            -- Kita taruh di 0.65 supaya ada sedikit celah (gap)
            position = { 0.7, 0.5 },
            size = { width = 0.6, height = 0.3 },
            zindex = 200,
          },
        },
      },
    },
    keys = {
      -- Keep diagnostics outside the <leader>t namespace used by navigation/tests.
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      -- Buffer diagnostics only.
      {
        "<leader>xB",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
    },
  },
}
