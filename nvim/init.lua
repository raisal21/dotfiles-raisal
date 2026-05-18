vim.loader.enable()
require("raisal.options")
pcall(require, "raisal.keymaps")
require("raisal.lazy")
require("raisal.lsp")

vim.opt.backupcopy = "yes"
vim.opt.winbar = "%#WinBar#%=  %f %m  %="

-- === Auto-reload files changed externally (agent/pi/opencode/claude edits) ===
local autoreload_group = vim.api.nvim_create_augroup("AutoReload", { clear = true })

-- Poll for file changes on focus gain and idle (CursorHold fires every 50ms thanks to updatetime=50)
vim.api.nvim_create_autocmd({ "FocusGained", "CursorHold" }, {
  group = autoreload_group,
  command = "silent! checktime",
})

-- When Vim detects a file changed, auto-reload without prompt
-- (even if buffer has unsaved changes — discards them silently)
vim.api.nvim_create_autocmd("FileChangedShell", {
  group = autoreload_group,
  nested = true,
  callback = function(args)
    vim.schedule(function()
      vim.api.nvim_buf_call(args.buf, function()
        vim.cmd("edit!") -- force-reload from disk, discard local changes
      end)
    end)
  end,
})
local theme = "kanagawa"
if theme == "moonfly" then
	-- Palet Moonfly (Dark Grey/Charcoal)
	vim.api.nvim_set_hl(0, "WinBar", { fg = "#bdbdbd", bg = "#1c1c1c", bold = true })
	vim.api.nvim_set_hl(0, "WinBarNC", { fg = "#7c7c7c", bg = "#1c1c1c" })
elseif theme == "kanagawa" then
	-- Palet Kanagawa Dragon (Earthy Dark Green/Black)
	vim.api.nvim_set_hl(0, "WinBar", { fg = "#c8c093", bg = "#181616", bold = true })
	vim.api.nvim_set_hl(0, "WinBarNC", { fg = "#727169", bg = "#181616" })
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

