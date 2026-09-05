return {
  "stevearc/aerial.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    "neovim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
    "nvim-telescope/telescope.nvim", -- Wajib buat integrasi fuzzy finder
  },
  keys = {
    -- Buka tutup outline window di kanan
    { "<leader>ta", "<cmd>AerialToggle!<CR>", desc = "Toggle Outline (Aerial)" },
    { "<leader>fs", "<cmd>Telescope aerial<CR>", desc = "Find Symbols (Telescope)" },
  },
  opts = {
    -- Roslyn has the most complete C# symbol model; keep Treesitter as fallback
    -- for buffers opened before the language server is ready.
    backends = {
      _ = { "treesitter", "lsp", "markdown", "asciidoc", "man" },
      cs = { "lsp", "treesitter" },
      csharp = { "lsp", "treesitter" },
    },
    close_automatic_events = { "unfocus", "switch_buffer", "unsupported" },
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
      _ = {
        "Class",
        "Constructor",
        "Enum",
        "Function",
        "Interface",
        "Module",
        "Method",
        "Struct",
        "Property",
        "Field",
        "Constant",
        "Variable",
      },
      cs = {
        "Namespace",
        "Class",
        "Interface",
        "Struct",
        "Enum",
        "Constructor",
        "Method",
        "Property",
        "Field",
        "Event",
        "EnumMember",
      },
      csharp = {
        "Namespace",
        "Class",
        "Interface",
        "Struct",
        "Enum",
        "Constructor",
        "Method",
        "Property",
        "Field",
        "Event",
        "EnumMember",
      },
    },
  },

  -- Inject Aerial ke dalam Telescope secara otomatis
  config = function(_, opts)
    require("aerial").setup(opts)
    require("telescope").load_extension("aerial")
  end,
}
