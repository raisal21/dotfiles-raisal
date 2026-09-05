local M = {}

local delay_ms = 1000
local pending = {}
local group = vim.api.nvim_create_augroup("AutoSave", { clear = true })

local function cancel(buf)
  local item = pending[buf]
  if not item then
    return
  end

  pending[buf] = nil
  if not item.timer:is_closing() then
    item.timer:stop()
    item.timer:close()
  end
end

local function eligible(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  local options = vim.bo[buf]
  local name = vim.api.nvim_buf_get_name(buf)
  return options.buftype == ""
    and options.modifiable
    and not options.readonly
    and options.modified
    and name ~= ""
    and vim.fn.isdirectory(name) == 0
end

local function save(buf)
  if not eligible(buf) then
    return false
  end

  local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
    vim.cmd("silent update")
  end)
  if not ok then
    vim.notify("Autosave failed for " .. vim.api.nvim_buf_get_name(buf) .. ": " .. err, vim.log.levels.WARN)
    return false
  end

  return true
end

function M.schedule(buf)
  cancel(buf)

  local token = {}
  local timer = vim.defer_fn(function()
    local item = pending[buf]
    if not item or item.token ~= token then
      return
    end

    pending[buf] = nil
    save(buf)
  end, delay_ms)
  pending[buf] = { timer = timer, token = token }
end

function M.flush(buf)
  cancel(buf)
  return save(buf)
end

function M.setup()
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(args)
      M.schedule(args.buf)
    end,
    desc = "Schedule autosave after editing settles",
  })

  vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
    group = group,
    callback = function(args)
      M.flush(args.buf)
    end,
    desc = "Flush autosave when leaving a buffer or focus",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        M.flush(buf)
      end
    end,
    desc = "Flush autosave before exiting Neovim",
  })

  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    callback = function(args)
      cancel(args.buf)
    end,
    desc = "Cancel autosave for deleted buffers",
  })
end

return M
