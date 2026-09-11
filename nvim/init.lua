vim.loader.enable()
require("raisal.options")
pcall(require, "raisal.keymaps")
require("raisal.comments").setup()
require("raisal.autosave").setup()
require("raisal.lazy")
require("raisal.lsp")

vim.opt.backupcopy = "yes"
-- Table-driven theme switch: autocmd handles WinBar hl + persists last choice.
-- Swap via <leader>fc (telescope colorscheme picker) or :colorscheme <name>.
local theme_palettes = {
  kanagawa = { fg = "#c8c093", fg_nc = "#727169", bg = "#181616" },
  moonfly = { fg = "#bdbdbd", fg_nc = "#7c7c7c", bg = "#1c1c1c" },
}
local theme_state_file = vim.fn.stdpath("state") .. "/last_theme"

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("WinBarTheme", { clear = true }),
  callback = function()
    local p = theme_palettes[vim.g.colors_name]
    if not p then
      return
    end
    vim.api.nvim_set_hl(0, "WinBar", { fg = p.fg, bg = p.bg, bold = true })
    vim.api.nvim_set_hl(0, "WinBarNC", { fg = p.fg_nc, bg = p.bg })
    pcall(vim.fn.writefile, { vim.g.colors_name }, theme_state_file)
  end,
})

-- Restore last theme (whitelist + pcall — see Decision 8)
if vim.uv.fs_stat(theme_state_file) then
  local ok, lines = pcall(vim.fn.readfile, theme_state_file)
  if ok and lines[1] and theme_palettes[lines[1]] then
    pcall(vim.cmd.colorscheme, lines[1])
  end
end

local telescope_group = vim.api.nvim_create_augroup("TelescopeCustomUI", { clear = true })

-- 1. Nyalakan relative number di jendela Preview (Kanan/Atas)
vim.api.nvim_create_autocmd("User", {
  pattern = "TelescopePreviewerLoaded",
  group = telescope_group,
  callback = function()
    vim.wo.number = true
    vim.wo.relativenumber = true
  end,
})

-- 2. Nyalakan relative number di jendela Results (Daftar Pencarian)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "TelescopeResults",
  group = telescope_group,
  callback = function()
    vim.wo.number = true
    vim.wo.relativenumber = true
  end,
})
