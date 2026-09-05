local workspace_path = vim.env.NOTEBOOK_PATH or vim.fn.expand("~/notebook")

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  ft = "markdown",
  -- A missing vault must not prevent render-markdown from attaching.
  cond = vim.fn.isdirectory(workspace_path) == 1,
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    legacy_commands = false,
    workspaces = {
      {
        name = "personal",
        path = workspace_path,
      },
    },
    ui = { enable = false }, -- render-markdown handles inline rendering
  },
}
