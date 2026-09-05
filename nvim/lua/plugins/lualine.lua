local function is_file_buffer()
  return vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= ""
end

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = {
    options = {
      theme = "auto",
      globalstatus = true,
      section_separators = { left = "", right = "" },
      component_separators = { left = "│", right = "│" },
    },
    sections = {
      lualine_a = {
        {
          "mode",
          fmt = function(str)
            return " " .. str:upper() .. " "
          end,
        },
      },
      lualine_b = {
        { "branch", icon = " " },
        {
          "diff",
          symbols = { added = "+", modified = "~", removed = "-" },
        },
      },
      lualine_c = {},
      lualine_x = {
        {
          "diagnostics",
          symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" },
        },
        "filetype",
      },
      lualine_y = {
        {
          "progress",
          fmt = function(str)
            return "pos: " .. str
          end,
        },
      },
      lualine_z = {
        {
          "location",
          fmt = function(str)
            return "ln: " .. str
          end,
        },
      },
    },
    winbar = {
      lualine_c = {
        {
          "filename",
          path = 1,
          newfile_status = true,
          cond = is_file_buffer,
        },
        {
          "aerial",
          sep = " > ",
          depth = 4,
          exact = false,
          cond = is_file_buffer,
        },
      },
    },
    inactive_winbar = {
      lualine_c = {
        {
          "filename",
          path = 1,
          newfile_status = true,
          cond = is_file_buffer,
        },
      },
    },
  },
}
