-- Animate ------------------------------------------------------------
vim.pack.add({
	"https://github.com/nvim-mini/mini.animate",
})

-- Smooth scrolling ----------------------------------------------------------------
local animate = require("mini.animate")
animate.setup({
    scroll = {
        timing = animate.gen_timing.linear({ duration = 80, unit = "total" }),
    },
    cursor = { enable = false },
    resize = { enable = false },
    open = { enable = false },
    close = { enable = false },
})
