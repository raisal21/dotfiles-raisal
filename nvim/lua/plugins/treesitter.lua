return {
	"nvim-treesitter/nvim-treesitter",

	build = ":TSUpdate",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
	config = function()
		local configs = require("nvim-treesitter.configs")

		configs.setup({
			-- Daftar parser yang WAJIB ada
			ensure_installed = {

				-- Bahasa Dasar & Config
				"c",
				"lua",
				"vim",
				"vimdoc",
				"query",
				"bash",

				-- Web Development (Basic)

				"html",
				"css",
				"javascript",
				"typescript",
				"python",

				-- TAMBAHAN BARU KAMU:
				"c_sharp", -- Untuk C# / .NET
				"xml", -- Untuk XML
				"yaml", -- Untuk YAML
				"toml", -- Untuk TOML
				"astro", -- Untuk Astro Framework
				"tsx", -- Untuk React (JSX/TSX)
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

			textobjects = {
				select = {
					enable = true,
					lookahead = true, -- Otomatis lompat ke textobject terdekat
					keymaps = {
						-- FUNGSI & CLASS
						["af"] = { query = "@function.outer", desc = "Select outer part of a function" },
						["if"] = { query = "@function.inner", desc = "Select inner part of a function" },
						["ac"] = { query = "@class.outer", desc = "Select outer part of a class" },
						["ic"] = { query = "@class.inner", desc = "Select inner part of a class" },

						-- ARGUMENT / PARAMETER
						["aa"] = { query = "@parameter.outer", desc = "Select outer part of an argument" },
						["ia"] = { query = "@parameter.inner", desc = "Select inner part of an argument" },

						-- SCOPE BLOCK
						["ab"] = { query = "@block.outer", desc = "Select outer part of a block" },
						["ib"] = { query = "@block.inner", desc = "Select inner part of a block" },

						-- LOGIC & CONTROL FLOW
						["al"] = { query = "@loop.outer", desc = "Select outer part of a loop" },
						["il"] = { query = "@loop.inner", desc = "Select inner part of a loop" },
						["a/"] = { query = "@conditional.outer", desc = "Select outer part of a conditional" },
						["i/"] = { query = "@conditional.inner", desc = "Select inner part of a conditional" },

						-- EKSEKUSI & ASSIGNMENT
						["ax"] = { query = "@call.outer", desc = "Select outer part of a function call" },
						["ix"] = { query = "@call.inner", desc = "Select inner part of a function call" },
						["a="] = { query = "@assignment.outer", desc = "Select outer part of an assignment" },
						["r="] = { query = "@assignment.rhs", desc = "Select right hand side of an assignment" },
						["l="] = { query = "@assignment.lhs", desc = "Select left hand side of an assignment" },
					},
				},
			},
		})
	end,
}
