return {
  "seblyng/roslyn.nvim",
  ft = "cs",
  init = function()
    vim.lsp.config("roslyn", {
      settings = {
        ["csharp|inlay_hints"] = {
          csharp_enable_inlay_hints_for_types = true,
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
          csharp_enable_inlay_hints_for_lambda_parameter_types = true,
          csharp_enable_inlay_hints_for_implicit_object_creation = false,
          dotnet_enable_inlay_hints_for_parameters = false,
        },
      },
    })
  end,
  ---@type RoslynNvimConfig
  opts = {
    -- Mason installs the server binary via mason-tool-installer ensure_installed.
    -- Plugin auto-detects mason-installed roslyn.
  },
}
