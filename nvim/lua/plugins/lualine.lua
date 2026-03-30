return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
        options = {
            theme = "auto", -- Otomatis ikut warna neovim
            globalstatus = true, -- SATU statusline untuk semua window (Modern Look)
            -- Kosongkan ini kalau mau tampilan kotak (Blocky) ala Windows NT
            section_separators = { left = '', right = ''},
            component_separators = { left = '', right = ''},
        },
        sections = {
            -- Kiri
            lualine_a = { "mode" },
            lualine_b = { "branch", "diff", "diagnostics" },
            lualine_c = {
                {
                    function()
                        return vim.fn.expand('%:h:t') -- Ambil nama folder terdekat
                    end,
                    icon = ' ', -- Kasih ikon folder biar jelas (Wajib install Nerd Fonts)
                    color = { fg = '#a9b1d6', gui = 'italic' }, -- Warnanya agak redup & miring biar aesthetic
                    padding = { right = 1 }, -- Jarak dikit ke kanan

                },

                -- Komponen 2: Nama File Asli
                {
                    "filename",
                    path = 0, -- 0 = Nama file doang (biar gak dobel path-nya)
                    color = { gui = 'bold' }, -- Filename dibikin tebal biar menonjol
                    padding = { left = 1 },
                }
            },
            -- Kanan
            lualine_x = { "filetype" }, -- Gak perlu encoding/fileformat, menuhin tempat
            lualine_y = { "progress" },
            lualine_z = { "location" },
        },
        -- Inactive sections bisa dihapus, biarkan default (abu-abu)
    },
}
