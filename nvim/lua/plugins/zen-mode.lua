local read_state = {
  source_buf = nil,
  source_win = nil,
  source_cursor = nil,
  source_view = nil,
  preview_buf = nil,
}

local function trim(value)
  return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function is_structural(line)
  if line == "" or line:match("^%s") then
    return true
  end

  return line:match("^```+")
    or line:match("^~~~+")
    or line:match("^%s*[#>]")
    or line:match("^%s*[-*+]%s+")
    or line:match("^%s*%d+[.)]%s+")
    or line:match("^%s*|")
    or line:match("^%s*%[%^")
    or line:match("^%s*<")
    or line:match("^%s*[-*_]%s*[-*_]%s*[-*_]")
    or line:find("|")
    or line:find("`")
    or line:match("  $")
    or line:match("\\$")
end

local function word_width(word)
  return vim.fn.strdisplaywidth(word)
end

local function justify_words(words, width)
  local lines = {}
  local current = {}
  local current_width = 0

  local function push_current()
    if #current > 0 then
      lines[#lines + 1] = current
      current = {}
      current_width = 0
    end
  end

  for _, word in ipairs(words) do
    local next_width = current_width + (#current > 0 and 1 or 0) + word_width(word)
    if #current > 0 and next_width > width then
      push_current()
    end
    current[#current + 1] = word
    current_width = current_width + (#current > 1 and 1 or 0) + word_width(word)
  end
  push_current()

  local output = {}
  for index, line_words in ipairs(lines) do
    if index == #lines or #line_words == 1 then
      output[#output + 1] = table.concat(line_words, " ")
    else
      local content_width = 0
      for _, word in ipairs(line_words) do
        content_width = content_width + word_width(word)
      end

      local gaps = #line_words - 1
      local extra = math.max(width - content_width - gaps, 0)
      local separators = {}
      for gap = 1, gaps do
        separators[gap] = 1 + math.floor(extra / gaps)
        if gap <= extra % gaps then
          separators[gap] = separators[gap] + 1
        end
      end

      local parts = { line_words[1] }
      for gap = 1, gaps do
        parts[#parts + 1] = string.rep(" ", separators[gap])
        parts[#parts + 1] = line_words[gap + 1]
      end
      output[#output + 1] = table.concat(parts)
    end
  end

  return output
end

local function justify_markdown(lines, width)
  local output = {}
  local paragraph = {}
  local in_fence = false

  local function flush_paragraph()
    if #paragraph == 0 then
      return
    end

    local words = {}
    for _, line in ipairs(paragraph) do
      for word in trim(line):gsub("%s+", " "):gmatch("%S+") do
        words[#words + 1] = word
      end
    end

    vim.list_extend(output, justify_words(words, width))
    paragraph = {}
  end

  for _, line in ipairs(lines) do
    local fence = line:match("^%s*(```+|~~~+)")
    if fence then
      flush_paragraph()
      output[#output + 1] = line
      in_fence = not in_fence
    elseif in_fence or is_structural(line) then
      flush_paragraph()
      output[#output + 1] = line
    else
      paragraph[#paragraph + 1] = line
    end
  end
  flush_paragraph()

  return output
end

local function preview_width()
  return math.max(1, math.floor(vim.o.columns * 0.85) - 2)
end

local function restore_source()
  local source_buf = read_state.source_buf
  local source_win = read_state.source_win
  local preview_buf = read_state.preview_buf

  if source_win and vim.api.nvim_win_is_valid(source_win) and source_buf and vim.api.nvim_buf_is_valid(source_buf) then
    vim.api.nvim_win_set_buf(source_win, source_buf)
    if read_state.source_cursor then
      pcall(vim.api.nvim_win_set_cursor, source_win, read_state.source_cursor)
    end
    if read_state.source_view then
      pcall(vim.api.nvim_win_call, source_win, function()
        vim.fn.winrestview(read_state.source_view)
      end)
    end
  end

  if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
    vim.api.nvim_buf_delete(preview_buf, { force = true })
  end

  read_state.source_buf = nil
  read_state.source_win = nil
  read_state.source_cursor = nil
  read_state.source_view = nil
  read_state.preview_buf = nil
end

local function create_preview()
  local source_buf = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()
  local source_name = vim.api.nvim_buf_get_name(source_buf)
  local preview_name = source_name ~= "" and (source_name .. ".markdown-read.md")
    or (vim.fn.stdpath("cache") .. "/markdown-read-" .. source_buf .. ".md")
  local preview_buf = vim.api.nvim_create_buf(false, true)

  read_state.source_buf = source_buf
  read_state.source_win = source_win
  read_state.source_cursor = vim.api.nvim_win_get_cursor(source_win)
  read_state.source_view = vim.fn.winsaveview()
  read_state.preview_buf = preview_buf

  vim.api.nvim_buf_set_name(preview_buf, preview_name)
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, justify_markdown(
    vim.api.nvim_buf_get_lines(source_buf, 0, -1, false),
    preview_width()
  ))
  vim.bo[preview_buf].buftype = "nofile"
  vim.bo[preview_buf].bufhidden = "wipe"
  vim.bo[preview_buf].swapfile = false
  vim.api.nvim_set_current_buf(preview_buf)
  vim.b[preview_buf].markdown_read_preview = true
  vim.bo[preview_buf].filetype = "markdown"
  vim.bo[preview_buf].modifiable = false
  vim.bo[preview_buf].readonly = true
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.keymap.set("n", "<leader>ur", "<cmd>MarkdownRead<cr>", {
    buffer = preview_buf,
    desc = "Close Markdown reading mode",
  })
end

return {
  "folke/zen-mode.nvim",
  ft = "markdown",
  opts = {
    window = {
      backdrop = 0.5,
      width = 0.85,
      height = 1,
      options = {
        signcolumn = "no",
        number = false,
        relativenumber = false,
        cursorline = false,
        cursorcolumn = false,
        foldcolumn = "0",
        list = false,
        wrap = true,
        linebreak = true,
        breakindent = true,
        breakindentopt = "min:20,shift:4",
        showbreak = "",
      },
    },
    plugins = {
      options = {
        enabled = true,
        ruler = false,
        showcmd = false,
        laststatus = 0,
      },
      twilight = { enabled = false },
      gitsigns = { enabled = false },
      tmux = { enabled = false },
      todo = { enabled = false },
    },
    on_open = function(win)
      if read_state.preview_buf and vim.api.nvim_win_get_buf(win) == read_state.preview_buf then
        -- Paragraphs are already hard-wrapped and justified in the preview.
        vim.api.nvim_win_set_option(win, "wrap", false)
        vim.api.nvim_win_set_option(win, "linebreak", false)
        vim.api.nvim_win_set_option(win, "breakindent", false)
      end
    end,
    on_close = restore_source,
  },
  config = function(_, opts)
    require("zen-mode").setup(opts)

    vim.api.nvim_create_user_command("MarkdownRead", function()
      if vim.bo.filetype ~= "markdown" then
        vim.notify("MarkdownRead hanya tersedia di buffer Markdown", vim.log.levels.WARN)
        return
      end

      local zen = require("zen-mode")
      local view = require("zen-mode.view")
      if read_state.preview_buf or view.is_open() then
        zen.toggle()
        return
      end

      create_preview()
      local ok, error_message = pcall(zen.toggle)
      if not ok then
        restore_source()
        vim.notify("MarkdownRead gagal dibuka: " .. error_message, vim.log.levels.ERROR)
      end
    end, { desc = "Toggle focused Markdown reading mode" })

    vim.keymap.set("n", "<leader>ur", "<cmd>MarkdownRead<cr>", {
      buffer = true,
      desc = "Toggle Markdown reading mode",
    })
  end,
}
