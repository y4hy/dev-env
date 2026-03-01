return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
        local wk = require("which-key")
        wk.setup({
            preset = "modern",
            delay = 999999, -- Very large delay to effectively disable auto-trigger
            win = {
                width = { min = 50, max = 0.95 }, -- min 50 cols, max 95% of screen
                height = { min = 4, max = 0.6 }, -- min 4 rows, max 60% of screen (shorter)
                border = "rounded",
                padding = { 1, 3 }, -- reduced vertical padding
            },
            layout = {
                width = { min = 50, max = 120 }, -- min and max width of columns
                spacing = 8, -- spacing between columns
                align = "left", -- align columns left
            },
            show_help = false, -- hide the status bar at bottom
            show_keys = false, -- hide the "Press key" hint
        })

        -- Register key groups using new spec
        wk.add({
            { "<leader>f", group = "Find/Search (Telescope pickers)" },
            { "<leader>d", group = "Debug (DAP debugging tools)" },
            { "<leader>s", group = "Split (Window management)" },
            { "<leader>n", group = "Tab (Tab navigation and management)" },
            { "<leader>p", group = "Project (Project-wide search)" },
            { "<leader>c", group = "Code (LSP code actions)" },
            { "<leader>r", group = "Rename (LSP refactoring)" },
            { "<leader>b", group = "Buffer (Buffer operations)" },
        })

        -- Keybinding to manually toggle which-key for all mappings
        vim.keymap.set("n", "<leader>?", function()
            require("which-key").show({ global = true })
        end, { desc = "Show all available key mappings" })
    end,
}
