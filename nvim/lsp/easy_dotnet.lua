---@type vim.lsp.Config
return {
  settings = {
    ["csharp|code_lens"] = {
      -- symbol-usage already shows references at end-of-line; avoid duplicate
      -- reference counts above declarations.
      dotnet_enable_references_code_lens = false,
      dotnet_enable_tests_code_lens = false,
    },
    ["csharp|inlay_hints"] = {
      csharp_enable_inlay_hints_for_types = true,
      csharp_enable_inlay_hints_for_implicit_variable_types = true,
      csharp_enable_inlay_hints_for_lambda_parameter_types = true,
      csharp_enable_inlay_hints_for_implicit_object_creation = false,
      dotnet_enable_inlay_hints_for_parameters = false,
    },
  },
}
