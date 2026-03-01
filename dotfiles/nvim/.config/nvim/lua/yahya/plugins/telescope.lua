return {
    "nvim-telescope/telescope.nvim",

    tag = "0.1.5",

    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        "nvim-telescope/telescope-ui-select.nvim",
    },

    config = function()
        local telescope = require('telescope')
        telescope.setup({
            extensions = {
                fzf = {
                    fuzzy = true,
                    override_generic_sorter = true,
                    override_file_sorter = true,
                    case_mode = "smart_case",
                },
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown({})
                },
            },
        })

        -- Load extensions
        pcall(telescope.load_extension, "fzf")
        pcall(telescope.load_extension, "ui-select")

        local builtin = require('telescope.builtin')
        
        -- File pickers
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope: Find files in current directory' })
        vim.keymap.set('n', '<C-p>', builtin.git_files, { desc = 'Telescope: Find files tracked by git' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope: List and search open buffers' })
        
        -- Search pickers
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope: Live grep search in all files' })
        vim.keymap.set('n', '<leader>pws', function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word })
        end, { desc = 'Telescope: Search for word under cursor in all files' })
        vim.keymap.set('n', '<leader>pWs', function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word })
        end, { desc = 'Telescope: Search for WORD under cursor in all files' })
        vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") })
        end, { desc = 'Telescope: Search for custom string in all files' })
        
        -- Other pickers
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope: Search through vim help tags' })
        vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = 'Telescope: List all LSP diagnostics in project' })
        vim.keymap.set('n', '<leader>fc', builtin.commands, { desc = 'Telescope: Search and execute vim commands' })
        vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Telescope: Search through all keymaps' })
    end
}

