return {
    {
        "MagicDuck/grug-far.nvim",
        config = function()
            require("grug-far").setup({
                -- Opsi visual biar makin ganteng
                headerMaxWidth = 80,
            })
        end,
        keys = {
            -- 1. Buka Grug-far kosong (Manual ketik yang mau dicari)
            {
                "<leader>sr", -- s = Search, r = Replace
                function()
                    require("grug-far").open()
                end,
                mode = { "n", "v" },
                desc = "Search and Replace (Grug-far)",
            },
            
            -- 2. Cari kata di bawah kursor saat ini (Langsung isi kolom search)
            {
                "<leader>sw", -- s = Search, w = Word
                function()
                    require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
                end,
                mode = { "n" },
                desc = "Search Current Word (Grug-far)",
            },
            
            -- 3. Cari file saat ini saja (Buffer only)
            {
                "<leader>sf", -- s = Search, f = File
                function()
                    require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
                end,
                mode = { "n" },
                desc = "Search in Current File",
            },
        },
    },
}
