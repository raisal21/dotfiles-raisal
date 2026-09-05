local M = {}

local configured_pre_hook
local initialized = false

local function fallback_comment_parts()
  local left, right = vim.bo.commentstring:match("^(.-)%%s(.*)$")
  if not left then
    return
  end

  return vim.trim(left), vim.trim(right)
end

local function comment_parts(row)
  local ok, utils = pcall(require, "Comment.utils")
  if ok then
    local config = vim.deepcopy(require("Comment.config"):get())
    if configured_pre_hook then
      config.pre_hook = configured_pre_hook
    end

    local context = {
      cmode = utils.cmode.uncomment,
      cmotion = utils.cmotion.line,
      ctype = utils.ctype.linewise,
      range = { srow = row, scol = 0, erow = row, ecol = 0 },
    }
    local parsed, left, right = pcall(utils.parse_cstr, config, context)
    if parsed and left and right then
      return left, right
    end
  end

  return fallback_comment_parts()
end

local function leading_comment(line, left)
  local indent, rest = line:match("^([ \\t]*)(.*)$")
  if not indent or not rest then
    return
  end

  local marker = rest:match("^(" .. vim.pesc(left) .. ")")
  if not marker then
    return
  end

  local padding = rest:sub(#marker + 1, #marker + 1) == " " and 1 or 0
  return indent, rest:sub(#marker + padding + 1), #indent, #marker + padding
end

function M.clean(line1, line2)
  local buffer = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buffer, line1 - 1, line2, false)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local removed_from_cursor_line = 0
  local changed = 0

  for index, line in ipairs(lines) do
    local row = line1 + index - 1
    local left, right = comment_parts(row)
    if left and right == "" then
      local indent, content, indent_length, removed = leading_comment(line, left)
      if indent then
        lines[index] = indent .. content
        changed = changed + 1
        if cursor[1] == row then
          removed_from_cursor_line = math.min(removed, math.max(cursor[2] - indent_length, 0))
        end
      end
    end
  end

  if changed == 0 then
    return 0
  end

  vim.api.nvim_buf_set_lines(buffer, line1 - 1, line2, false, lines)
  if cursor[1] >= line1 and cursor[1] <= line2 then
    cursor[2] = math.max(cursor[2] - removed_from_cursor_line, 0)
    vim.api.nvim_win_set_cursor(0, cursor)
  end

  return changed
end

local function snippet_active()
  if not vim.snippet or not vim.snippet.active then
    return false
  end

  local ok, active = pcall(vim.snippet.active, { direction = 1 })
  return ok and active
end

local function feed_enter()
  local enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  vim.api.nvim_feedkeys(enter, "m", false)
end

local function insert_clean_line()
  if vim.fn.pumvisible() == 1 or snippet_active() then
    feed_enter()
    return
  end

  local buffer = vim.api.nvim_get_current_buf()
  local row, column = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local left, right = comment_parts(row)
  if not left or right ~= "" or not leading_comment(line, left) then
    feed_enter()
    return
  end

  local indent = line:match("^[ \\t]*") or ""
  vim.api.nvim_buf_set_text(buffer, row - 1, column, row - 1, column, { "", indent })
  vim.api.nvim_win_set_cursor(0, { row + 1, #indent })
end

function M.set_pre_hook(pre_hook)
  configured_pre_hook = pre_hook
end

function M.setup()
  if initialized then
    return
  end
  initialized = true

  vim.api.nvim_create_user_command("CommentClean", function(args)
    M.clean(args.line1, args.line2)
  end, {
    desc = "Remove leading line comment markers",
    range = true,
  })

  vim.keymap.set("n", "<leader>cu", "<cmd>CommentClean<cr>", {
    desc = "Clean comment marker",
  })
  vim.keymap.set("i", "<S-CR>", insert_clean_line, {
    desc = "New clean line",
  })
end

return M
