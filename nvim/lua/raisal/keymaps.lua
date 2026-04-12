local keymap = vim.keymap.set

keymap("n", "<leader>w", ":w<CR>")
keymap("n", "<leader>q", ":q<CR>")

keymap("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "Vertical Split" })
keymap("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window" })
keymap("n", "<leader>v", "<C-v>", { desc = "Visual Block Mode" })

keymap("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename (Global)" })
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear Search Highlights" })

keymap("n", "<C-d>", "<C-d>zz", { desc = "Scroll down & center" })
keymap("n", "<C-u>", "<C-u>zz", { desc = "Scroll up & center" })

keymap("n", "n", "nzzzv", { desc = "Next search result & center" })
keymap("n", "N", "Nzzzv", { desc = "Prev search result & center" })
