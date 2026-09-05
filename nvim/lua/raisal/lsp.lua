local keymap = vim.keymap -- for conciseness
local document_highlight_group = vim.api.nvim_create_augroup("UserLspDocumentHighlight", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(ev)
    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf, silent = true }

    -- set keybinds
    opts.desc = "Show LSP references"
    keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

    opts.desc = "Go to declaration"
    keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

    opts.desc = "Show LSP definition"
    keymap.set("n", "gd", vim.lsp.buf.definition, opts) -- show lsp definition

    opts.desc = "Show LSP implementations"
    keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

    opts.desc = "Show LSP type definitions"
    keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

    opts.desc = "See available code actions"
    keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

    opts.desc = "Smart rename"
    keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

    opts.desc = "Buffer diagnostics (Telescope)"
    keymap.set("n", "<leader>xb", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

    opts.desc = "Line diagnostics"
    keymap.set("n", "<leader>xl", vim.diagnostic.open_float, opts)

    opts.desc = "Go to previous diagnostic"
    keymap.set("n", "[d", function()
      vim.diagnostic.jump({ count = -1, float = true })
    end, opts) -- jump to previous diagnostic in buffer
    --
    opts.desc = "Go to next diagnostic"
    keymap.set("n", "]d", function()
      vim.diagnostic.jump({ count = 1, float = true })
    end, opts) -- jump to next diagnostic in buffer

    opts.desc = "Show documentation for what is under cursor"
    keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

    opts.desc = "Restart LSP"
    keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method("textDocument/documentHighlight") then
      vim.api.nvim_clear_autocmds({ group = document_highlight_group, buffer = ev.buf })
      vim.api.nvim_create_autocmd("CursorHold", {
        group = document_highlight_group,
        buffer = ev.buf,
        callback = vim.lsp.buf.document_highlight,
        desc = "Highlight references under cursor",
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
        group = document_highlight_group,
        buffer = ev.buf,
        callback = vim.lsp.buf.clear_references,
        desc = "Clear document highlights",
      })
    end

    -- <leader>t is reserved for C# structure and static-typing feedback.
    if vim.bo[ev.buf].filetype == "cs" or vim.bo[ev.buf].filetype == "csharp" then
      if client and client:supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })

        opts.desc = "C#: toggle inlay hints"
        keymap.set("n", "<leader>th", function()
          local filter = { bufnr = ev.buf }
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
        end, opts)
      end

      opts.desc = "C#: supertypes"
      keymap.set("n", "<leader>ts", function()
        vim.lsp.buf.typehierarchy("supertypes")
      end, opts)

      opts.desc = "C#: subtypes"
      keymap.set("n", "<leader>td", function()
        vim.lsp.buf.typehierarchy("subtypes")
      end, opts)

      opts.desc = "C#: incoming calls"
      keymap.set("n", "<leader>ti", "<cmd>Trouble lsp_incoming_calls toggle<cr>", opts)

      opts.desc = "C#: outgoing calls"
      keymap.set("n", "<leader>to", "<cmd>Trouble lsp_outgoing_calls toggle<cr>", opts)

      opts.desc = "C#: workspace symbols"
      keymap.set("n", "<leader>tw", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", opts)
    end
  end,
})

local severity = vim.diagnostic.severity

vim.diagnostic.config({
  update_in_insert = false,
  severity_sort = true,
  virtual_text = false,
  virtual_lines = { current_line = true },
  signs = {
    text = {
      [severity.ERROR] = " ",
      [severity.WARN] = " ",
      [severity.HINT] = "󰠠 ",
      [severity.INFO] = " ",
    },
  },
})
