return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	-- Load setelah treesitter utama jalan
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	event = { "BufReadPost", "BufNewFile", "BufWritePre" },

	config = function()
		---@diagnostic disable-next-line: missing-fields
		require("nvim-treesitter.configs").setup({
			textobjects = {
				select = {
					enable = true,

					-- Otomatis lompat ke textobject terdekat kalau kursor belum ada di dalamnya
					lookahead = true,

					keymaps = {
						-- ==========================================
						-- 1. FUNGSI & CLASS (The Basics)
						-- ==========================================
						["af"] = { query = "@function.outer", desc = "Select outer part of a function" },
						["if"] = { query = "@function.inner", desc = "Select inner part of a function" },
						["ac"] = { query = "@class.outer", desc = "Select outer part of a class" },
						["ic"] = { query = "@class.inner", desc = "Select inner part of a class" },

						-- ==========================================
						-- 2. ARGUMENT / PARAMETER (React/C# God Tier)
						-- ==========================================
						["aa"] = { query = "@parameter.outer", desc = "Select outer part of an argument" },
						["ia"] = { query = "@parameter.inner", desc = "Select inner part of an argument" },

						-- ==========================================
						-- 3. SCOPE BLOCK (Pengganti ci{ yang buggy)
						-- ==========================================
						["ab"] = { query = "@block.outer", desc = "Select outer part of a block" },
						["ib"] = { query = "@block.inner", desc = "Select inner part of a block" },

						-- ==========================================
						-- 4. LOGIC & CONTROL FLOW
						-- ==========================================
						-- Loop (For, While, Foreach)
						["al"] = { query = "@loop.outer", desc = "Select outer part of a loop" },
						["il"] = { query = "@loop.inner", desc = "Select inner part of a loop" },

						-- Conditional (If, Else, Switch)
						["a/"] = { query = "@conditional.outer", desc = "Select outer part of a conditional" },
						["i/"] = { query = "@conditional.inner", desc = "Select inner part of a conditional" },

						-- ==========================================
						-- 5. EKSEKUSI & ASSIGNMENT
						-- ==========================================
						-- Function Call: dax -> hapus pemanggilan fungsi utuh
						["ax"] = { query = "@call.outer", desc = "Select outer part of a function call" },
						["ix"] = { query = "@call.inner", desc = "Select inner part of a function call" },

						-- Assignment: ci= -> ganti nilai di sebelah kanan sama dengan
						["a="] = { query = "@assignment.outer", desc = "Select outer part of an assignment" },
						["r="] = { query = "@assignment.rhs", desc = "Select right hand side of an assignment" },
						["l="] = { query = "@assignment.lhs", desc = "Select left hand side of an assignment" },
					},
				},
			},
		})
	end,
}
