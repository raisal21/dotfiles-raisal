return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	opts = {
		options = {
			theme = "auto",
			globalstatus = true,
			section_separators = { left = "", right = "" },
			component_separators = { left = "│", right = "│" },
		},
		sections = {
			lualine_a = {
				{
					"mode",
					fmt = function(str)
						return " " .. str:upper() .. " "
					end,
				},
			},
			lualine_b = {
				{ "branch", icon = " " },
				{
					"diff",
					symbols = { added = "+", modified = "~", removed = "-" },
				},
			},
			lualine_c = {},
			lualine_x = {
				{
					"diagnostics",
					symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" },
				},
				"filetype",
			},
			lualine_y = {
				{
					"progress",
					fmt = function(str)
						return "pos: " .. str
					end,
				},
			},
			lualine_z = {
				{
					"location",
					fmt = function(str)
						return "ln: " .. str
					end,
				},
			},
		},
		tabline = {
			lualine_a = {
				{
					"tabs",
					mode = 1,
					max_length = function()
						return math.floor(vim.o.columns * 0.75)
					end,
					tabs_color = {
						active = "lualine_a_normal",
						inactive = "lualine_b_normal",
					},
					fmt = function(name, ctx)
						local ok, tabname = pcall(vim.api.nvim_tabpage_get_var, ctx.tabnr, "tabname")
						local label = (ok and tabname and tabname ~= "") and tabname or name
						return ctx.tabnr .. ":" .. label
					end,
				},
			},
			lualine_z = {
				{
					function()
						return " " .. (vim.g.current_session or "no session")
					end,
				},
			},
		},
	},
}
