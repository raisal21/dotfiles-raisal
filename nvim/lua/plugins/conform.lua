return {
  "stevearc/conform.nvim",
  -- Lazy loading: Hanya dimuat saat kamu membuka atau membuat file baru
  event = { "BufReadPre", "BufNewFile" },

  config = function()
    require("conform").setup({
      -- 1. TENTUKAN FORMATTER UNTUK TIAP BAHASA
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
      },

      -- 2. MAGIC: OTOMATIS RAPI SAAT DI-SAVE
      format_on_save = {
        -- Kalau formatter (misal prettier) gagal/nggak ada, pakai LSP bawaan
        lsp_format = "fallback",
        async = false,
        timeout_ms = 1000,
      },
    })

    -- 3. SHORTCUT MANUAL (Biar masuk ke Which-Key yang sudah kita bikin estetik!)
    -- Bisa di mode Normal (n) atau Visual block (v)
    vim.keymap.set({ "n", "v" }, "<leader>f", function()
      require("conform").format({
        lsp_format = "fallback",
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = "Format code" })
  end,
}
