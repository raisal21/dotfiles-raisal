return {
  "NvChad/nvim-colorizer.lua",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("colorizer").setup({
      filetypes = {
        "css",
        "scss",
        "sass",
        "less",
        "html",
        "vue",
        "svelte",
        "javascript",
        "typescript",
        "javascriptreact",
        "typescriptreact",
        "lua",
        "cs",
        "xaml",
        "json",
        "yaml",
        cmp_docs = { always_update = true },
      },
      user_default_options = {
        RGB = true, -- Aktifkan #RGB (misal: #FFF)
        RRGGBB = true, -- Aktifkan #RRGGBB (misal: #FF0000)
        names = false, -- Matikan warna dari nama (misal: 'Blue') biar ga risih
        RRGGBBAA = false, -- Matikan Hex dengan Alpha channel
        AARRGGBB = false,
        rgb_fn = true, -- Aktifkan fungsi css rgb() dan rgba()
        hsl_fn = true, -- Aktifkan fungsi css hsl() dan hsla()
        css = true, -- Dukung fitur CSS
        css_fn = true,
        mode = "background", -- Opsi: 'foreground', 'background', 'virtualtext'
        tailwind = true, -- Dukung warna Tailwind CSS
      },
    })
  end,
}
