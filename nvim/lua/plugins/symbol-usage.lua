return {
	"Wansmer/symbol-usage.nvim",
	-- Plugin ini cukup berat kalau diload di awal.
	-- Kita lazy-load HANYA ketika LSP (tsserver, csharp_ls, dll) sudah benar-benar aktif di file tersebut.
	event = "LspAttach",

	config = function()
		vim.api.nvim_set_hl(0, "SymbolUsageRef", { link = "Comment", italic = true })
		vim.api.nvim_set_hl(0, "SymbolUsageDef", { link = "Comment", italic = true })
		vim.api.nvim_set_hl(0, "SymbolUsageImpl", { link = "Comment", italic = true })

		local function text_format(symbol)
			local res = {}

			if symbol.references == 0 and symbol.implementation == 0 then
				return res
			end

			-- Kasih jarak 2 spasi
			table.insert(res, { "  " })

			-- Format Usages (References)
			if symbol.references then
				local usage = symbol.references <= 1 and "usage" or "usages"
				table.insert(res, { "󰌹 " .. symbol.references .. " " .. usage, "SymbolUsageRef" })
			end

			-- Format Implementations
			if symbol.implementation and symbol.implementation > 0 then
				if #res > 1 then
					table.insert(res, { " | ", "Comment" })
				end
				table.insert(res, { "󰡱 " .. symbol.implementation .. " impls", "SymbolUsageImpl" })
			end

			return res
		end

		require("symbol-usage").setup({
			vt_position = "end_of_line",

			text_format = text_format,

			disable = {
				filetypes = { "json", "yaml", "markdown", "toml", "css", "html" },
			},
		})
	end,
}
