return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
        local wk = require("which-key")
        wk.setup({
            preset = "modern",
            delay = 999999, -- Very large delay to effectively disable auto-trigger
            win = {
                width = { min = 50, max = 0.95 },
                height = { min = 4, max = 0.6 },
                border = "rounded",
                padding = { 1, 3 },
            },
            layout = {
                width = { min = 50, max = 120 },
                spacing = 8,
                align = "left",
            },
            show_help = false,
            show_keys = false,
        })

        -- Register key groups
        wk.add({
            { "<leader>f", group = "Find/Search (Telescope)" },
            { "<leader>d", group = "Debug (DAP)" },
            { "<leader>s", group = "Split (Window)" },
            { "<leader>n", group = "Tab (Navigation)" },
            { "<leader>p", group = "Project (Search)" },
            { "<leader>c", group = "Code (LSP actions)" },
            { "<leader>r", group = "Rename (LSP)" },
            { "<leader>b", group = "Buffer (Operations)" },
            { "<leader>t", group = "Test (Neotest)" },
            { "<leader>x", group = "Trouble (Diagnostics)" },
            { "<leader>R", group = "Rust (rust-analyzer)" },
            { "<leader>C", group = "Crates (Cargo.toml)" },
            { "<leader>w", group = "Session (Workspace)" },
        })

        -- Keybinding to manually toggle which-key for all mappings
        vim.keymap.set("n", "<leader>?", function()
            require("which-key").show({ global = true })
        end, { desc = "Show all available key mappings" })
    end,
}
