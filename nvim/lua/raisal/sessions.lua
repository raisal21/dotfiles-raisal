local M = {}

vim.o.sessionoptions = "buffers,curdir,folds,tabpages,winsize,terminal,globals"

if not vim.g.current_session or vim.g.current_session == "" then
	vim.g.current_session = "auto"
end

M.sessions_dir = function()
	return vim.fn.stdpath("data") .. "/sessions"
end

M.list = function()
	local dir = M.sessions_dir()
	if vim.fn.isdirectory(dir) == 0 then
		return {}
	end
	return vim.fn.readdir(dir, function(name)
		return (type(name) == "string" and name:match("%.vim$")) and 1 or 0
	end)
end

M.servers = function()
	local raw = vim.fn.system({ "ss", "-xl" })
	local servers = {}
	local seen = {}
	local self_sock = vim.v.servername or ""
	for line in raw:gmatch("[^\n]+") do
		local path = line:match("(/run/user/%d+/[^%s]*nvim[^%s]*)")
			or line:match("(/tmp/[^%s]*nvim[^%s]*)")
		if path and not seen[path] and path ~= self_sock then
			seen[path] = true
			table.insert(servers, {
				socket = path,
				label = path:match("/([^/]+)$") or path,
			})
		end
	end
	return servers
end

M.reset_state = function()
	pcall(vim.cmd, "tabonly!")
	pcall(vim.cmd, "silent! %bwipeout!")
end

local function tabnames_path(session_path)
	return session_path:gsub("%.vim$", "") .. ".tabnames"
end

M.dump_tabnames = function(session_path)
	local lines = {}
	for _, tabnr in ipairs(vim.api.nvim_list_tabpages()) do
		local ok, name = pcall(vim.api.nvim_tabpage_get_var, tabnr, "tabname")
		table.insert(lines, (ok and name) or "")
	end
	pcall(vim.fn.writefile, lines, tabnames_path(session_path))
end

M.restore_tabnames = function(session_path)
	local file = tabnames_path(session_path)
	if vim.fn.filereadable(file) == 0 then
		return
	end
	local lines = vim.fn.readfile(file)
	local tabs = vim.api.nvim_list_tabpages()
	for i, tabnr in ipairs(tabs) do
		local name = lines[i]
		if name and name ~= "" then
			pcall(vim.api.nvim_tabpage_set_var, tabnr, "tabname", name)
		end
	end
	pcall(vim.cmd, "redrawtabline")
end

M.load = function(path)
	M.save_auto()
	M.reset_state()
	vim.cmd("silent! source " .. vim.fn.fnameescape(path))
	M.restore_tabnames(path)
	vim.g.current_session = vim.fn.fnamemodify(path, ":t:r")
	pcall(vim.cmd, "redrawtabline")
	vim.notify("Loaded: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
end

M.select = function()
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values

	local function entry_maker(item)
		local prefix = item.type == "server" and "▶ " or "💾 "
		return {
			value = item,
			display = prefix .. item.label,
			ordinal = item.label,
		}
	end

	local function build_finder()
		local items = {}
		for _, f in ipairs(M.list()) do
			table.insert(items, {
				label = f,
				type = "file",
				path = M.sessions_dir() .. "/" .. f,
			})
		end
		for _, s in ipairs(M.servers()) do
			table.insert(items, {
				label = s.label,
				type = "server",
				socket = s.socket,
			})
		end
		return finders.new_table({ results = items, entry_maker = entry_maker })
	end

	require("telescope.pickers")
		.new({}, {
			prompt_title = "Sessions (CR=load/attach, C-d=delete/kill)",
			finder = build_finder(),
			sorter = conf.generic_sorter({}),
			layout_strategy = "center",
			layout_config = {
				width = 60,
				height = 12,
				anchor = "C",
				prompt_position = "top",
			},
			border = true,
			sorting_strategy = "ascending",
			attach_mappings = function(_, map)
				map({ "i", "n" }, "<CR>", function(bufnr)
					local item = action_state.get_selected_entry().value
					actions.close(bufnr)
					if item.type == "file" then
						M.load(item.path)
					else
						vim.cmd(
							"tabnew | terminal env -u NVIM nvim --server "
								.. vim.fn.shellescape(item.socket)
								.. " --remote-ui"
						)
					end
				end)
				map({ "i", "n" }, "<C-d>", function(bufnr)
					local entry = action_state.get_selected_entry()
					if not entry then
						return
					end
					local item = entry.value
					if item.type == "file" then
						os.remove(item.path)
						os.remove(tabnames_path(item.path))
						vim.notify("Deleted: " .. item.label, vim.log.levels.INFO)
					else
						vim.fn.system({
							"nvim",
							"--server",
							item.socket,
							"--remote-send",
							"<C-\\><C-n>:qa!<CR>",
						})
						vim.notify("Killed: " .. item.label, vim.log.levels.INFO)
					end
					action_state.get_current_picker(bufnr):refresh(build_finder(), { reset_prompt = false })
				end)
				return true
			end,
		})
		:find()
end

M.save_auto = function()
	local dir = M.sessions_dir()
	vim.fn.mkdir(dir, "p")
	local name = (vim.g.current_session and vim.g.current_session ~= "") and vim.g.current_session or "auto"
	local path = dir .. "/" .. name .. ".vim"
	pcall(vim.cmd, "mksession! " .. vim.fn.fnameescape(path))
	M.dump_tabnames(path)
end

M.save_named = function(name)
	if not name or name == "" then
		M.save_auto()
		vim.notify("Saved to auto.vim", vim.log.levels.INFO)
		return
	end
	if not name:match("%.vim$") then
		name = name .. ".vim"
	end
	vim.fn.mkdir(M.sessions_dir(), "p")
	local path = M.sessions_dir() .. "/" .. name
	vim.cmd("mksession! " .. vim.fn.fnameescape(path))
	M.dump_tabnames(path)
	vim.g.current_session = name:gsub("%.vim$", "")
	pcall(vim.cmd, "redrawtabline")
	vim.notify("Saved: " .. name, vim.log.levels.INFO)
end

M.rename = function(old, new)
	if not old or old == "" or not new or new == "" then
		vim.notify("rename needs old and new", vim.log.levels.ERROR)
		return
	end
	old = old:gsub("%.vim$", "")
	new = new:gsub("%.vim$", "")
	local dir = M.sessions_dir()
	local old_vim = dir .. "/" .. old .. ".vim"
	local new_vim = dir .. "/" .. new .. ".vim"
	if vim.fn.filereadable(old_vim) == 0 then
		vim.notify("no such session: " .. old, vim.log.levels.ERROR)
		return
	end
	if vim.fn.filereadable(new_vim) == 1 then
		vim.notify("target exists: " .. new, vim.log.levels.ERROR)
		return
	end
	os.rename(old_vim, new_vim)
	local old_tab = dir .. "/" .. old .. ".tabnames"
	local new_tab = dir .. "/" .. new .. ".tabnames"
	if vim.fn.filereadable(old_tab) == 1 then
		os.rename(old_tab, new_tab)
	end
	if vim.g.current_session == old then
		vim.g.current_session = new
	end
	pcall(vim.cmd, "redrawtabline")
	vim.notify("Renamed: " .. old .. " → " .. new, vim.log.levels.INFO)
end

M.new = function(name)
	M.save_auto()
	M.reset_state()
	vim.cmd("tabnew +terminal")
	if name and name ~= "" then
		vim.g.current_session = name:gsub("%.vim$", "")
		M.save_named(name)
	else
		vim.g.current_session = "auto"
		pcall(vim.cmd, "redrawtabline")
		vim.notify("New blank session", vim.log.levels.INFO)
	end
end

M.restore_auto_prompt = function()
	local auto = M.sessions_dir() .. "/auto.vim"
	if vim.fn.filereadable(auto) == 0 then
		return
	end
	if vim.fn.argc() > 0 then
		return
	end
	vim.ui.select({ "Yes", "No" }, { prompt = "Restore last session?" }, function(choice)
		if choice == "Yes" then
			M.load(auto)
		end
	end)
end

M.detach = function()
	local pid = vim.g.v_session_client_pid
	if not pid or pid == 0 then
		vim.notify("VDetach: no client pid", vim.log.levels.WARN)
		return
	end
	M.save_auto()
	-- write terminal restore DIRECTLY to user TTY path (bypasses pty/socket race)
	local tty = vim.g.v_session_user_tty
	if tty and tty ~= "" then
		local uv = vim.uv or vim.loop
		local ok, fd = pcall(uv.fs_open, tty, "w", 0)
		if ok and fd then
			pcall(uv.fs_write, fd, "\27[?1049l\27[?47l\27[?25h\27[0m\27[?2004l\r", -1)
			pcall(uv.fs_close, fd)
		end
	end
	vim.fn.jobstart({ "kill", tostring(pid) }, { detach = true })
end

vim.api.nvim_create_user_command("VDetach", function()
	M.detach()
end, {})

vim.api.nvim_create_user_command("SessionSave", function(opts)
	M.save_named(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("SessionNew", function(opts)
	M.new(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("SessionRename", function(opts)
	local args = vim.split(opts.args, "%s+")
	M.rename(args[1], args[2])
end, {
	nargs = "+",
	complete = function(_, line)
		local n = #vim.split(line, "%s+")
		if n <= 2 then
			return M.list()
		end
		return {}
	end,
})

vim.api.nvim_create_user_command("SessionLoad", function(opts)
	local name = opts.args
	if not name:match("%.vim$") then
		name = name .. ".vim"
	end
	M.load(M.sessions_dir() .. "/" .. name)
end, {
	nargs = 1,
	complete = function()
		return M.list()
	end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
	group = vim.api.nvim_create_augroup("SessionSaveOnExit", { clear = true }),
	callback = function()
		M.save_auto()
	end,
})

return M
