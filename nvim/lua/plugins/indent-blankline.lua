return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = { "BufReadPost", "BufNewFile" },

  opts = {
    debounce = 200,
    indent = {
      char = "│",
      highlight = "IblIndent",
      priority = 1,
    },
    scope = {
      enabled = true,
      char = "│",
      highlight = "IblScope",
      show_start = true,
      show_end = true,
      priority = 1024,
    },
    exclude = {
      filetypes = {
        "",
        "help",
        "checkhealth",
        "TelescopePrompt",
        "TelescopeResults",
        "dashboard",
        "alpha",
        "oil",
        "NvimTree",
        "neo-tree",
      },
      buftypes = { "terminal", "nofile", "quickfix", "prompt" },
    },
  },

  config = function(_, opts)
    local hooks = require("ibl.hooks")
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

    local function is_active(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
      end

      local name = vim.api.nvim_buf_get_name(bufnr)
      if name == "" then
        return true
      end

      local lower_name = name:lower()
      for _, pattern in ipairs(generated_patterns) do
        if lower_name:match(pattern) then
          return false
        end
      end

      local ok, stats = pcall(vim.uv.fs_stat, name)
      return not (ok and stats and stats.size > max_size)
    end

    hooks.register(hooks.type.ACTIVE, is_active)

    local guide_colors = vim.api.nvim_create_augroup("IblGuideColors", { clear = true })
    local function apply_guide_colors()
      vim.api.nvim_set_hl(0, "IblIndent", { fg = "#FFFFFF" })
      vim.api.nvim_set_hl(0, "IblScope", { fg = "#4ADE80", bold = true })
    end
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = guide_colors,
      callback = apply_guide_colors,
    })
    apply_guide_colors()

    require("ibl").setup(opts)
  end,
}
