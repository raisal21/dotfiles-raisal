return {
    "nvim-treesitter/nvim-treesitter",

    build = ":TSUpdate",
    config = function()
        local configs = require("nvim-treesitter.configs")

        configs.setup({
            -- Daftar parser yang WAJIB ada
	    ensure_installed = { 

                -- Bahasa Dasar & Config
                "c", "lua", "vim", "vimdoc", "query", "bash",
                
                -- Web Development (Basic)

                "html", "css", "javascript", "typescript", 
                "python",

                -- TAMBAHAN BARU KAMU:
                "c_sharp",  -- Untuk C# / .NET
                "xml",      -- Untuk XML
                "yaml",     -- Untuk YAML
                "toml",     -- Untuk TOML
                "astro",    -- Untuk Astro Framework
                "tsx",      -- Untuk React (JSX/TSX)
            },
            
            -- Install parser secara background
            sync_install = false,

            -- Otomatis install parser kalau buka file bahasa baru
            auto_install = true,

            -- Fitur Highlighting
            highlight = { 
                enable = true,
                additional_vim_regex_highlighting = false,
            },


            -- Fitur Indentasi
            indent = { enable = true },
        })
    end
}
