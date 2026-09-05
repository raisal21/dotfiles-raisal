return {
  "neovim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- WAJIB: Plugin ini sekarang tidak mendukung lazy-loading
  build = ":TSUpdate",
  dependencies = {
    "neovim-treesitter/treesitter-parser-registry",
  },
  config = function()
    -- Parser IDs yang ingin diinstall. Filetype Neovim dipetakan terpisah di bawah.
    local langs = {
      -- Bahasa Dasar & Config
      "c",
      "lua",
      "vim",
      "vimdoc",
      "query",
      "bash",
      "markdown",
      "markdown_inline",

      -- Web Development (Basic)
      "html",
      "css",
      "javascript",
      "typescript",
      "python",

      -- TAMBAHAN BARU KAMU:
      "c_sharp",
      "xml",
      "yaml",
      "toml",
      "astro",
      "tsx",
      "zsh", -- Tambahan baru
      "tmux",
    }

    local parser_filetypes = {
      bash = { "sh", "bash" },
      c_sharp = { "cs", "csharp" },
      javascript = { "javascript", "javascriptreact" },
      tsx = { "typescriptreact", "typescript.tsx" },
      xml = { "xml", "xsd", "xslt", "svg" },
    }

    local filetype_to_parser = {}
    for _, parser in ipairs(langs) do
      for _, filetype in ipairs(parser_filetypes[parser] or { parser }) do
        filetype_to_parser[filetype] = parser
      end
    end

    -- 1. Install parsers & queries (Menggantikan `ensure_installed`)
    require("nvim-treesitter").install(langs)

    -- Skip highlight pada file >100KB (log dump, minified bundle) — cegah scroll freeze.
    local MAX_TS_SIZE = 100 * 1024
    local function buf_too_big(buf)
      local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
      return ok and stats and stats.size > MAX_TS_SIZE
    end

    local function has_indent_query(parser)
      local ok, query = pcall(vim.treesitter.query.get, parser, "indents")
      return ok and query ~= nil
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = vim.tbl_keys(filetype_to_parser),
      callback = function(args)
        local parser = filetype_to_parser[vim.bo[args.buf].filetype]
        if not parser then
          return
        end

        -- Let EditorConfig win when it defines indentation; otherwise C# uses
        -- the conventional four-space fallback for projects without a config.
        if parser == "c_sharp" then
          local editorconfig = vim.b[args.buf].editorconfig or {}
          if editorconfig.indent_size == nil and editorconfig.tab_width == nil then
            vim.bo[args.buf].tabstop = 4
            vim.bo[args.buf].shiftwidth = 4
          end
        end

        if buf_too_big(args.buf) then
          return
        end

        vim.treesitter.start(args.buf, parser)

        -- C# has no Treesitter indents query. Keep runtime indent/cs.vim.
        if has_indent_query(parser) then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
