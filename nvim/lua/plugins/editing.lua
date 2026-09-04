return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("conform").setup({
        -- DAFTAR FORMATTER
        formatters_by_ft = {
          lua = { "stylua" },
          -- Web Dev Stack (Prettier semua)
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" }, -- React .jsx/.tsx
          typescriptreact = { "prettier" },
          css = { "prettier" },
          html = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          markdown = { "prettier" },
          graphql = { "prettier" },
        },
        -- OPSI: FORMAT ON SAVE (Ala VS Code)
        -- Kalau mau otomatis rapi pas save, pastikan ini nyala:
        format_on_save = {
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        },
      })
    end,
  },
  -- 1. Auto Pairs: Otomatis tutup kurung () [] {}
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
    -- "config = true" sama dengan function() require('nvim-autopairs').setup({}) end
  },

  -- 2. Surround: Ganti quotes/kurung dengan cepat (cs"')
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    init = function()
      -- Flash owns `S` in visual mode.
      vim.g.nvim_surround_no_visual_mappings = true
    end,
    config = function()
      require("nvim-surround").setup({})
      vim.keymap.set("x", "gsa", "<Plug>(nvim-surround-visual)", {
        desc = "Add surround around visual selection",
      })
      vim.keymap.set("x", "gsA", "<Plug>(nvim-surround-visual-line)", {
        desc = "Add surround around visual selection on new lines",
      })
    end,
  },

  -- 3. Comment: Komentar cepat (gcc / gb)
  { "JoosepAlviste/nvim-ts-context-commentstring", lazy = true },
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy", -- Biar nvim gak berat pas startup, baru load pas mau dipake
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("Comment").setup({
        padding = true,
        sticky = true,
        ignore = "^$",
        toggler = {
          line = "gcc",
          block = "gbc",
        },
        opleader = {
          line = "gc",
          block = "gb",
        },
        extra = {
          above = "gcO",
          below = "gco",
          eol = "gcA",
        },
        mappings = {
          basic = true,
          extra = true,
        },
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },
  {
    "gbprod/cutlass.nvim",
    opts = {
      -- Tombol 'm' akan menjadi fungsi "Cut" yang asli (menghapus & meng-copy)
      cut_key = "m",

      -- Jika kamu ingin mengubah behaviour tambahan (opsional)
      override_del = true, -- 'd' jadi delete beneran
      exclude = {}, -- Jika ada command yang ingin dikecualikan
    },
  },
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      enable_close = true,
      enable_rename = true,
      enable_close_on_slash = true,
      per_filetype = {
        ["html"] = { enable_close_on_slash = true },
        ["typescriptreact"] = { enable_close_on_slash = true },
      },
    },
  },
}
