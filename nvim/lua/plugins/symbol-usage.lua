return {
  "Wansmer/symbol-usage.nvim",
  -- Plugin ini cukup berat kalau diload di awal.
  -- Kita lazy-load HANYA ketika LSP (tsserver, csharp_ls, dll) sudah benar-benar aktif di file tersebut.
  event = "LspAttach",

  config = function()
    local highlight_group = vim.api.nvim_create_augroup("SymbolUsageHighlights", { clear = true })
    local function set_highlights()
      vim.api.nvim_set_hl(0, "SymbolUsageRef", { link = "Comment", italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageDef", { link = "Comment", italic = true })
      vim.api.nvim_set_hl(0, "SymbolUsageImpl", { link = "Comment", italic = true })
    end

    set_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = highlight_group,
      callback = set_highlights,
    })

    local max_size = 100 * 1024
    local generated_patterns = {
      "[/\\]bin[/\\]",
      "[/\\]obj[/\\]",
      "[/\\]generated[/\\]",
      "%.g%.cs$",
      "%.generated%.cs$",
      "%.designer%.cs$",
      "%.assemblyattributes%.cs$",
    }

    local function is_generated_or_large(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return true
      end

      local name = vim.api.nvim_buf_get_name(bufnr)
      if name == "" then
        return false
      end

      local lower_name = name:lower()
      for _, pattern in ipairs(generated_patterns) do
        if lower_name:match(pattern) then
          return true
        end
      end

      local ok, stats = pcall(vim.uv.fs_stat, name)
      return ok and stats ~= nil and stats.size > max_size
    end

    local function text_format(symbol)
      local res = {}
      local references = symbol.references or 0
      local implementations = symbol.implementation or 0

      if references == 0 and implementations == 0 then
        return res
      end

      -- Kasih jarak 2 spasi
      table.insert(res, { "  " })

      -- Format Usages (References)
      if references > 0 then
        local usage = references == 1 and "usage" or "usages"
        table.insert(res, { "󰌹 " .. references .. " " .. usage, "SymbolUsageRef" })
      end

      -- Format Implementations
      if implementations > 0 then
        if #res > 1 then
          table.insert(res, { " | ", "Comment" })
        end
        table.insert(res, { "󰡱 " .. implementations .. " impls", "SymbolUsageImpl" })
      end

      return res
    end

    require("symbol-usage").setup({
      vt_position = "end_of_line",
      request_pending_text = false,

      text_format = text_format,

      filetypes = {
        cs = {
          kinds = {
            vim.lsp.protocol.SymbolKind.Class,
            vim.lsp.protocol.SymbolKind.Interface,
            vim.lsp.protocol.SymbolKind.Struct,
            vim.lsp.protocol.SymbolKind.Constructor,
            vim.lsp.protocol.SymbolKind.Method,
          },
          references = { enabled = true },
          implementation = {
            enabled = true,
            kinds = {
              vim.lsp.protocol.SymbolKind.Class,
              vim.lsp.protocol.SymbolKind.Interface,
              vim.lsp.protocol.SymbolKind.Method,
            },
          },
        },
        csharp = {
          kinds = {
            vim.lsp.protocol.SymbolKind.Class,
            vim.lsp.protocol.SymbolKind.Interface,
            vim.lsp.protocol.SymbolKind.Struct,
            vim.lsp.protocol.SymbolKind.Constructor,
            vim.lsp.protocol.SymbolKind.Method,
          },
          references = { enabled = true },
          implementation = {
            enabled = true,
            kinds = {
              vim.lsp.protocol.SymbolKind.Class,
              vim.lsp.protocol.SymbolKind.Interface,
              vim.lsp.protocol.SymbolKind.Method,
            },
          },
        },
      },

      disable = {
        filetypes = { "json", "yaml", "markdown", "toml", "css", "html" },
        cond = { is_generated_or_large },
      },
    })

    vim.keymap.set("n", "<leader>uS", function()
      require("symbol-usage").toggle()
    end, { desc = "Toggle symbol usage (buffer)" })
  end,
}
