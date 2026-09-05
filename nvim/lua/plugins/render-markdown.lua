return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = "markdown",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    pipe_table = {
      preset = "double",
      enabled = true,
      style = "full",
      cell = "padded",
    },
    on = {
      attach = function()
        local buf = vim.api.nvim_get_current_buf()
        local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))
        if size > 500 * 1024 then
          require("render-markdown").buf_disable()
        end
      end,
    },
  },
}
