return { 
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require('gitsigns').setup({
                -- ========================================================
                -- 1. KONFIGURASI TAMPILAN (VISUAL)
                -- ========================================================
                signs = {
                    add          = { text = '┃' },
                    change       = { text = '┃' },
                    delete       = { text = '_' },
                    topdelete    = { text = '‾' },
                    changedelete = { text = '~' },
                    untracked    = { text = '┆' },
                },
                signs_staged = {
                    add          = { text = '┃' },
                    change       = { text = '┃' },
                    delete       = { text = '_' },
                    topdelete    = { text = '‾' },
                    changedelete = { text = '~' },
                    untracked    = { text = '┆' },
                },
                signs_staged_enable = true,
                signcolumn = true,  -- Tampilkan kolom tanda di kiri
                numhl      = false, -- Highlight nomor baris (biasanya false biar gak rame)
                linehl     = false, -- Highlight background baris
                word_diff  = false, -- Highlight per kata
                
                watch_gitdir = {
                    follow_files = true
                },
                
                auto_attach = true,
                attach_to_untracked = false, -- File baru yg belum di-git add tidak akan ada tandanya
                
                -- Konfigurasi Ghost Text (Teks samar info commit di sebelah kanan)
                current_line_blame = false, -- Default mati, nyalakan pakai <leader>tb
                current_line_blame_opts = {
                    virt_text = true,
                    virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
                    delay = 1000,
                    ignore_whitespace = false,
                    virt_text_priority = 100,
                    use_focus = true,
                },
                current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
                
                sign_priority = 6,
                update_debounce = 100,
                status_formatter = nil, -- Use default
                max_file_length = 40000, 
                
                preview_config = {
                    -- Options passed to nvim_open_win
                    style = 'minimal',
                    relative = 'cursor',
                    row = 0,
                    col = 1
                },

                -- ========================================================
                -- 2. KEYMAPS / SHORTCUTS (FUNGSI)
                -- ========================================================
                on_attach = function(bufnr)
                    local gitsigns = require('gitsigns')

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- A. Navigation (Loncat antar perubahan)
                    map('n', ']c', function()
                        if vim.wo.diff then vim.cmd.normal({']c', bang = true}) else gitsigns.nav_hunk('next') end
                    end)

                    map('n', '[c', function()
                        if vim.wo.diff then vim.cmd.normal({'[c', bang = true}) else gitsigns.nav_hunk('prev') end
                    end)

                    -- B. Preview & Blame (Lihat info)
                    map('n', '<leader>hp', gitsigns.preview_hunk) -- Popup preview perubahan
                    map('n', '<leader>tb', gitsigns.toggle_current_line_blame) -- Toggle info siapa yg edit

                    -- C. Reset (Undo perubahan git)
                    map('n', '<leader>hr', gitsigns.reset_hunk)
                    -- Support Visual Mode (Block selection) buat reset
                    map('v', '<leader>hr', function() gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end)

                    -- D. Diff (Compare file)
                    map('n', '<leader>hd', gitsigns.diffthis)
                end
            })
        end
    },
    {
        "tpope/vim-fugitive",
        cmd = "Git", -- Load cuma pas diketik :Git
        keys = {
            { "<leader>gs", vim.cmd.Git, desc = "Fugitive Status" },
        }
    }
}
