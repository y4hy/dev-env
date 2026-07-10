return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "classic", -- least flashy, traditional bottom popup
        delay = 5000,
        icons = {
            mappings = false, -- text-only, keep it uncluttered
        },
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = true })
            end,
            desc = "Show all keymaps (which-key)",
        },
    },
}
