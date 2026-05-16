local keymap = vim.keymap.set

keymap("n", "<leader>w", ":w<CR>")
keymap("n", "<leader>q", ":q<CR>")

keymap("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "Vertical Split" })
keymap("n", "<leader>-", "<cmd>split<cr>", { desc = "Horizontal Split" })
keymap("n", "<C-h>", "<C-w>h", { desc = "Window left" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Window right" })
keymap("n", "<leader>v", "<C-v>", { desc = "Visual Block Mode" })

-- Tab cycle (wrap) in normal, insert, visual, terminal
keymap({ "n", "i", "v", "t" }, "<C-j>", "<Cmd>tabnext<CR>", { desc = "Next tab (wrap)" })
keymap({ "n", "i", "v", "t" }, "<C-k>", "<Cmd>tabprevious<CR>", { desc = "Prev tab (wrap)" })

keymap("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename (Global)" })
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear Search Highlights" })

keymap("n", "<C-d>", "<C-d>zz", { desc = "Scroll down & center" })
keymap("n", "<C-u>", "<C-u>zz", { desc = "Scroll up & center" })

keymap("n", "n", "nzzzv", { desc = "Next search result & center" })
keymap("n", "N", "Nzzzv", { desc = "Prev search result & center" })

keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Tab management (cycle via <C-j>/<C-k> above)
keymap("n", "<leader>tn", ":tabnew +terminal<CR>", { desc = "New tab (terminal)" })
keymap("n", "<leader>tN", ":tabnew | Oil<CR>", { desc = "New tab (Oil)" })
keymap("n", "<leader>tc", ":tabclose<CR>", { desc = "Close tab" })
keymap("n", "<leader>to", ":tabonly<CR>", { desc = "Close other tabs" })
keymap("n", "<leader>ts", function()
	require("raisal.sessions").select()
end, { desc = "Sessions" })
keymap("n", "<leader>tS", ":SessionSave<CR>", { desc = "Save session" })
