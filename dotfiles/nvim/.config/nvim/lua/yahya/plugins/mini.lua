return {
    {
        "echasnovski/mini.ai",
        version = false,
        config = function()
            require("mini.ai").setup({
                n_lines = 500,
                custom_textobjects = nil,
            })
        end,
    },
    {
        "echasnovski/mini.bufremove",
        version = false,
        config = function()
            require("mini.bufremove").setup()
            vim.keymap.set("n", "<leader>bd", function()
                require("mini.bufremove").delete(0, false)
            end, { desc = "Delete current buffer (keep window layout)" })
            vim.keymap.set("n", "<leader>bD", function()
                require("mini.bufremove").delete(0, true)
            end, { desc = "Force delete current buffer (ignore unsaved changes)" })
        end,
    },
}
