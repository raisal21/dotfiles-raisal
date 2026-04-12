require("raisal.options")
pcall(require, "raisal.keymaps")
require("raisal.lazy")
require("raisal.lsp")

vim.opt.backupcopy = "yes"

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
