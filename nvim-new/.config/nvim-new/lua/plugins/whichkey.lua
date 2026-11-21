vim.pack.add({
    "https://github.com/folke/which-key.nvim"
})

-- Key hints -------------------------------------------------------------------------
-- Press a key that starts a sequence (<leader>, g, z, ", ...) and wait:
-- a popup lists every key that can follow, using each map's `desc`.
local wk = require("which-key")
wk.setup({
    preset = "helix", -- popup in the bottom-right corner ("classic" = bottom bar)
})

-- Names for the prefixes, so the popup shows "+find" instead of "+3 keymaps".
wk.add({
    { "<leader>f", group = "find" },
    { "<leader>s", group = "split" },
    { "<leader>t", group = "tab" },
    { "<leader>e", group = "explorer" },
    { "<leader>o", group = "options" },
    { "<leader>c", group = "code" },
})


