vim.pack.add({
	-- "https://github.com/stevearc/oil.nvim",
	"https://github.com/nvim-mini/mini.files",
})

local map = vim.keymap.set
--
-- -- File Explorer Oil ------------------------------------------------------------
-- local oil = require("oil")
-- oil.setup({
--     view_options = {
--         max_width = 0.6, -- at most 60& of the screen wide...
--         max_height = 0.7, -- ... and 700% high
--     },
-- })
-- 
-- map("n", "<leader>ee", oil.toggle_float, { desc = "Toggle file explorer" })
-- map("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })

-- File Explorer mini.files --------------------------------------------------------
local files = require("mini.files")
files.setup({
    windows = {
        preview = true, -- show a preview column of the file/folder under the cursor
        width_preview = 50, -- preview column width, in characters
    },
    options = {
        permanent_delete = false, -- deleted files go to a trash folder instead
    },
    mappings = {
        go_in_plus = "<CR>", -- Enter: open file and close the explorer (default: L)
    },
})

map("n", "<leader>ee", function()
    if not files.close() then
        files.open(vim.api.nvim_buf_get_name(0))
    end
end, { desc = "Toggle file explorer" })


