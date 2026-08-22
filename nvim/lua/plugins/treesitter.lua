return {
  "neovim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- WAJIB: Plugin ini sekarang tidak mendukung lazy-loading
  build = ":TSUpdate",
  dependencies = {
    "neovim-treesitter/treesitter-parser-registry",
  },
  config = function()
    -- Daftar bahasa yang ingin diinstall
    local langs = {
      -- Bahasa Dasar & Config
      "c",
      "lua",
      "vim",
      "vimdoc",
      "query",
      "bash",

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

    -- 1. Install parsers & queries (Menggantikan `ensure_installed`)
    require("nvim-treesitter").install(langs)

    -- Skip highlight pada file >100KB (log dump, minified bundle) — cegah scroll freeze.
    local MAX_TS_SIZE = 100 * 1024
    local function buf_too_big(buf)
      local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
      return ok and stats and stats.size > MAX_TS_SIZE
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = langs,
      callback = function(args)
        if buf_too_big(args.buf) then
          return
        end
        vim.treesitter.start()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
