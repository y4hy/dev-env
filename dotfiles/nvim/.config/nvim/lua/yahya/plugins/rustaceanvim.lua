return {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false,
    init = function()
        vim.g.rustaceanvim = function()
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
            if ok then
                capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
            end
            return {
                server = {
                    on_attach = function(_, bufnr)
                        local opts = { buffer = bufnr }

                        -- Rust-specific actions (override generic LSP mappings in Rust buffers)
                        vim.keymap.set("n", "K", function()
                            vim.cmd.RustLsp({ "hover", "actions" })
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Hover actions" }))

                        vim.keymap.set({ "n", "v" }, "<leader>ca", function()
                            vim.cmd.RustLsp("codeAction")
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Code action (rust-analyzer)" }))

                        -- Diagnostics
                        vim.keymap.set("n", "<leader>Re", function()
                            vim.cmd.RustLsp("explainError")
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Explain error" }))

                        vim.keymap.set("n", "<leader>Rd", function()
                            vim.cmd.RustLsp("renderDiagnostic")
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Render diagnostic" }))

                        -- Navigation
                        vim.keymap.set("n", "<leader>Rp", function()
                            vim.cmd.RustLsp("parentModule")
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Go to parent module" }))

                        vim.keymap.set("n", "<leader>Rc", function()
                            vim.cmd.RustLsp("openCargo")
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Open Cargo.toml" }))

                        vim.keymap.set("n", "<leader>RD", function()
                            vim.cmd.RustLsp("openDocs")
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Open docs.rs" }))

                        -- Run / Debug
                        vim.keymap.set("n", "<leader>Rr", function()
                            vim.cmd.RustLsp("runnables")
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Runnables" }))

                        vim.keymap.set("n", "<leader>Rt", function()
                            vim.cmd.RustLsp("testables")
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Testables" }))

                        vim.keymap.set("n", "<leader>Rg", function()
                            vim.cmd.RustLsp("debuggables")
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Debuggables" }))

                        -- Code tools
                        vim.keymap.set("n", "<leader>Rm", function()
                            vim.cmd.RustLsp("expandMacro")
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Expand macro" }))

                        vim.keymap.set("n", "J", function()
                            vim.cmd.RustLsp("joinLines")
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Smart join lines" }))

                        vim.keymap.set("n", "<leader>Rs", function()
                            vim.cmd.RustLsp("syntaxTree")
                        end, vim.tbl_extend("force", opts, { desc = "Rust: View syntax tree" }))

                        -- Inlay hints toggle (Neovim 0.10+)
                        vim.keymap.set("n", "<leader>Ri", function()
                            vim.lsp.inlay_hint.enable(
                                not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
                                { bufnr = bufnr }
                            )
                        end, vim.tbl_extend("force", opts, { desc = "Rust: Toggle inlay hints" }))
                    end,
                    capabilities = capabilities,
                    default_settings = {
                        ["rust-analyzer"] = {
                            check = {
                                command = "clippy",
                            },
                            cargo = {
                                allFeatures = true,
                            },
                            procMacro = {
                                enable = true,
                            },
                            inlayHints = {
                                chainingHints = { enable = true },
                                typeHints = { enable = true },
                                parameterHints = { enable = true },
                            },
                        },
                    },
                },
            }
        end
    end,
}
