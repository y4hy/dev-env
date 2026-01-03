return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "j-hui/fidget.nvim",
    },

    config = function()
        local cmp_lsp = require("cmp_nvim_lsp")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities())

        require("fidget").setup({})
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "gopls",
                "pyright",
                "ruff",
                "clangd",
                "taplo",
                "jsonls",
                "yamlls",
                "marksman",
                "bashls",
                "html",
                "cssls",
                "tailwindcss",
            },
            handlers = {
                function(server_name) -- default handler (optional)
                    require("lspconfig")[server_name].setup {
                        capabilities = capabilities
                    }
                end,

                ["lua_ls"] = function()
                    local lspconfig = require("lspconfig")
                    lspconfig.lua_ls.setup {
                        capabilities = capabilities,
                        settings = {
                            Lua = {
                                runtime = { version = "Lua 5.1" },
                                diagnostics = {
                                    globals = { "bit", "vim", "it", "describe", "before_each", "after_each" },
                                }
                            }
                        }
                    }
                end,
            }
        })

        vim.diagnostic.config({
            underline = false,
            undercurl = false,
            virtual_text = {
                severity = { vim.diagnostic.severity.ERROR }
            },
            signs = {
                severity = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN }
            },
            float = {
                severity_sort = true,
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
            },
        })

        -- LSP Keymaps
        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('UserLspConfig', {}),
            callback = function(ev)
                local opts = { buffer = ev.buf }
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, { desc = 'LSP: Jump to definition of symbol under cursor' }))
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, { desc = 'LSP: Jump to declaration of symbol under cursor' }))
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('force', opts, { desc = 'LSP: Jump to implementation of symbol under cursor' }))
                vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, { desc = 'LSP: Show all references to symbol under cursor' }))
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('force', opts, { desc = 'LSP: Show documentation for symbol under cursor' }))
                vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, { desc = 'LSP: Rename symbol under cursor across project' }))
                vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, { desc = 'LSP: Show available code actions for current context' }))
                vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, vim.tbl_extend('force', opts, { desc = 'LSP: Show diagnostic message in floating window' }))
                vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, vim.tbl_extend('force', opts, { desc = 'LSP: Jump to previous diagnostic in buffer' }))
                vim.keymap.set('n', ']d', vim.diagnostic.goto_next, vim.tbl_extend('force', opts, { desc = 'LSP: Jump to next diagnostic in buffer' }))
            end,
        })
    end
}
