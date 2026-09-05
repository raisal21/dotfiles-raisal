return {
  "GustavEikaas/easy-dotnet.nvim",
  cmd = "Dotnet",
  event = {
    "BufReadPre *.cs",
    "BufNewFile *.cs",
    "BufReadPre *.csproj",
    "BufReadPre *.fsproj",
    "BufReadPre *.sln",
    "BufReadPre *.slnx",
    "BufReadPre *.razor",
    "BufReadPre *.cshtml",
  },
  keys = {
    { "<leader>mm", "<cmd>Dotnet<cr>", desc = ".NET commands" },
    { "<leader>ms", "<cmd>Dotnet solution select<cr>", desc = ".NET select solution" },
    { "<leader>mr", "<cmd>Dotnet run<cr>", desc = ".NET run" },
    { "<leader>mR", "<cmd>Dotnet run profile<cr>", desc = ".NET run profile" },
    { "<leader>mb", "<cmd>Dotnet build quickfix<cr>", desc = ".NET build project" },
    { "<leader>mB", "<cmd>Dotnet build solution quickfix<cr>", desc = ".NET build solution" },
    { "<leader>mw", "<cmd>Dotnet watch<cr>", desc = ".NET watch" },
    { "<leader>mo", "<cmd>Dotnet restore<cr>", desc = ".NET restore" },
    { "<leader>mc", "<cmd>Dotnet clean<cr>", desc = ".NET clean" },
    { "<leader>mp", "<cmd>Dotnet pack<cr>", desc = ".NET pack" },
    { "<leader>mP", "<cmd>Dotnet push<cr>", desc = ".NET push package" },
    { "<leader>mt", "<cmd>Dotnet terminal toggle<cr>", desc = ".NET terminal" },
    { "<leader>mx", "<cmd>lua require('easy-dotnet').stop()<cr>", desc = ".NET stop" },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  opts = {
    picker = "telescope",
    lsp = {
      -- roslyn.nvim remains the sole owner of the C# language server.
      enabled = false,
    },
    projx_lsp = {
      enabled = true,
    },
    debugger = {
      auto_register_dap = false,
      mem_cpu_usage = false,
    },
    test_runner = {
      auto_start_testrunner = false,
    },
    managed_terminal = {
      auto_hide = true,
      auto_hide_delay = 1000,
    },
    csproj_mappings = true,
    fsproj_mappings = true,
    auto_bootstrap_namespace = {
      enabled = false,
    },
  },
}
