local M = {}

local function set_tab_name(name)
	vim.api.nvim_tabpage_set_var(0, "tabname", name)
end

local function fresh_tab(dir, name)
	if dir and dir ~= "" then
		vim.cmd("tabnew")
		vim.cmd("tcd " .. vim.fn.fnameescape(dir))
		vim.cmd("enew")
	else
		vim.cmd("tabnew")
	end
	if name then
		set_tab_name(name)
	end
end

M.reset = function()
	require("raisal.sessions").save_auto()
	pcall(vim.cmd, "tabonly!")
	pcall(vim.cmd, "silent! %bwipeout!")
end

M.telemetry = function()
	M.reset()
	if not vim.g.current_session or vim.g.current_session == "" or vim.g.current_session == "auto" then
		vim.g.current_session = "telemetry"
	end
	local dir = vim.fn.expand("~/workspace/realtime-monitoring")

	vim.cmd("tcd " .. vim.fn.fnameescape(dir))
	set_tab_name("frontend")
	vim.cmd("Oil " .. vim.fn.fnameescape(dir))

	vim.cmd("tabnew")
	vim.cmd("tcd " .. vim.fn.fnameescape(dir))
	set_tab_name("backend")
	vim.cmd("Oil " .. vim.fn.fnameescape(dir))

	fresh_tab(dir, "sys-console")
	vim.cmd("terminal")
	vim.cmd("vsplit | terminal")

	fresh_tab(dir, "agents")
	vim.cmd("terminal")

	vim.cmd("tabfirst")
	pcall(vim.cmd, "redrawtabline")
end

vim.api.nvim_create_user_command("Workspaces", function(opts)
	local name = opts.args
	if name == "telemetry" then
		M.telemetry()
	else
		vim.notify("Unknown workspace: " .. name, vim.log.levels.WARN)
	end
end, {
	nargs = 1,
	complete = function()
		return { "telemetry" }
	end,
})

vim.api.nvim_create_user_command("TabRename", function(opts)
	local name = opts.args
	if name == "" then
		vim.ui.input({ prompt = "Tab name: " }, function(input)
			if input and input ~= "" then
				set_tab_name(input)
				vim.cmd("redrawtabline")
			end
		end)
	else
		set_tab_name(name)
		vim.cmd("redrawtabline")
	end
end, { nargs = "?" })

return M
