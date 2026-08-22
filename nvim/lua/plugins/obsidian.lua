return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  ft = "markdown",
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    legacy_commands = false,
    workspaces = {
      {
        name = "personal",
        path = vim.env.NOTEBOOK_PATH or vim.fn.expand("~/notebook"),
      },
    },
    ui = { enable = false }, -- render-markdown handles inline rendering
  },
}
