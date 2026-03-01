return {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local crates = require("crates")
        crates.setup({
            completion = {
                cmp = {
                    enabled = true,
                },
            },
        })

        -- Keymaps only relevant in Cargo.toml buffers
        vim.keymap.set("n", "<leader>Cv", crates.show_versions_popup, { desc = "Crates: Show versions" })
        vim.keymap.set("n", "<leader>Cf", crates.show_features_popup, { desc = "Crates: Show features" })
        vim.keymap.set("n", "<leader>Cd", crates.show_dependencies_popup, { desc = "Crates: Show dependencies" })
        vim.keymap.set("n", "<leader>Cu", crates.upgrade_crate, { desc = "Crates: Upgrade crate" })
        vim.keymap.set("v", "<leader>Cu", crates.upgrade_crates, { desc = "Crates: Upgrade selected crates" })
        vim.keymap.set("n", "<leader>Ca", crates.upgrade_all_crates, { desc = "Crates: Upgrade all crates" })
        vim.keymap.set("n", "<leader>CH", crates.open_homepage, { desc = "Crates: Open homepage" })
        vim.keymap.set("n", "<leader>CR", crates.open_repository, { desc = "Crates: Open repository" })
        vim.keymap.set("n", "<leader>CD", crates.open_documentation, { desc = "Crates: Open documentation" })
        vim.keymap.set("n", "<leader>CC", crates.open_crates_io, { desc = "Crates: Open crates.io" })
    end,
}
