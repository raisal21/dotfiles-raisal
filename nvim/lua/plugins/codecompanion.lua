vim.g.codecompanion_permission_mode = vim.g.codecompanion_permission_mode or "ask"

local function permission_mode()
  local mode = vim.g.codecompanion_permission_mode
  if mode == "allow" then
    return mode
  end
  return "ask"
end

local function set_permission_mode(mode)
  if mode == "auto" then
    mode = "allow"
  end
  if mode ~= "ask" and mode ~= "allow" then
    vim.notify("CodeCompanion permission must be 'ask' or 'allow'", vim.log.levels.ERROR)
    return
  end

  vim.g.codecompanion_permission_mode = mode
  local label = mode == "allow" and "allow (auto)" or "ask"
  vim.notify("OpenCode permission: " .. label .. " (applies to the next ACP chat)", vim.log.levels.INFO)
end

local function toggle_permission_mode()
  set_permission_mode(permission_mode() == "allow" and "ask" or "allow")
end

local function register_permission_command()
  pcall(vim.api.nvim_del_user_command, "CodeCompanionPermission")
  vim.api.nvim_create_user_command("CodeCompanionPermission", function(command)
    if command.args == "" or command.args == "toggle" then
      if command.args == "" then
        vim.notify("OpenCode permission: " .. permission_mode(), vim.log.levels.INFO)
      else
        toggle_permission_mode()
      end
      return
    end
    set_permission_mode(command.args)
  end, {
    nargs = "?",
    complete = function()
      return { "ask", "allow", "auto", "toggle" }
    end,
    desc = "Set OpenCode ACP permission mode",
  })
end

local function switch_backend(adapter)
  local codecompanion = require("codecompanion")
  local chat = codecompanion.last_chat()

  if not chat then
    return codecompanion.toggle_chat({ params = { adapter = adapter } })
  end

  -- Close the existing ACP process before starting the other backend.
  chat:close()
  vim.defer_fn(function()
    codecompanion.toggle_chat({ params = { adapter = adapter } })
  end, 50)
end

local function opencode_adapter()
  local command = { "opencode", "acp" }
  if permission_mode() == "allow" then
    table.insert(command, "--auto")
  end

  return require("codecompanion.adapters").extend("opencode", {
    commands = { default = command },
    env = {
      OPENCODE_CONFIG_CONTENT = vim.json.encode({ default_agent = "build" }),
    },
  })
end

return {
  "olimorris/codecompanion.nvim",
  version = "v19.23.0",
  event = "VeryLazy",
  cmd = {
    "CodeCompanion",
    "CodeCompanionActions",
    "CodeCompanionChat",
    "CodeCompanionCmd",
  },
  keys = {
    {
      "<leader>ic",
      "<cmd>CodeCompanionChat Toggle<cr>",
      mode = { "n", "v" },
      desc = "AI chat",
    },
    {
      "<leader>ii",
      "<cmd>CodeCompanion<cr>",
      mode = { "n", "v" },
      desc = "AI inline prompt",
    },
    {
      "<leader>ia",
      "<cmd>CodeCompanionActions<cr>",
      mode = { "n", "v" },
      desc = "AI actions",
    },
    {
      "<leader>io",
      function()
        switch_backend("opencode")
      end,
      mode = "n",
      desc = "AI chat (OpenCode)",
    },
    {
      "<leader>iy",
      toggle_permission_mode,
      mode = "n",
      desc = "Toggle OpenCode auto permission",
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function(_, opts)
    require("codecompanion").setup(opts)
    register_permission_command()
  end,
  opts = {
    adapters = {
      acp = {
        -- OpenCode's --auto flag is selected by CodeCompanionPermission allow.
        opencode = opencode_adapter,
      },
    },

    opts = {
      log_level = "ERROR",
      language = "Indonesian",
      send_code = true,
    },

    interactions = {
      opts = {
        -- Native Neovim autoread owns external file changes.
        watcher = {
          enabled = false,
        },
      },
      chat = {
        adapter = "opencode",
        opts = {
          completion_provider = "blink",
          context_management = {
            enabled = true,
            editing = {
              trigger = 0.65,
              keep_cycles = 3,
            },
            compaction = {
              trigger = 0.85,
              min_token_savings = 10000,
            },
          },
        },
        tools = {
          ["delete_file"] = {
            opts = {
              allowed_in_yolo_mode = false,
              require_approval_before = true,
              require_cmd_approval = true,
              judge_in_yolo_mode = false,
            },
          },
          ["insert_edit_into_file"] = {
            opts = {
              allowed_in_yolo_mode = false,
              require_approval_before = {
                buffer = true,
                file = true,
              },
              require_confirmation_after = true,
            },
          },
          ["run_command"] = {
            opts = {
              allowed_in_yolo_mode = false,
              require_approval_before = true,
              require_cmd_approval = true,
              judge_in_yolo_mode = false,
            },
          },
        },
      },
    },

    display = {
      chat = {
        window = {
          layout = "vertical",
          position = "right",
          full_height = true,
          width = 0.38,
          border = "single",
          opts = {
            breakindent = true,
            linebreak = true,
            wrap = true,
          },
        },
        auto_scroll = true,
        fold_context = true,
        show_context = true,
        show_header_separator = false,
        show_settings = false,
        show_token_count = true,
        start_in_insert_mode = false,
      },
      diff = {
        enabled = true,
        threshold_for_chat = 6,
        window = {
          width = function()
            return math.min(120, vim.o.columns - 10)
          end,
          height = function()
            return math.max(10, vim.o.lines - 4)
          end,
          opts = {
            number = true,
            relativenumber = false,
          },
        },
        word_highlights = {
          additions = true,
          deletions = true,
        },
      },
    },
  },
}
