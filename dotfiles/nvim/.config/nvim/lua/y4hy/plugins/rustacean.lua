return {
    "mrcjkb/rustaceanvim",
    version = '^8',
    lazy = false,
    init = function()
        -- rustaceanvim manages rust_analyzer itself; configure it here rather
        -- than through lspconfig/mason-lspconfig to avoid a duplicate client.
        vim.g.rustaceanvim = {
            server = {
                default_settings = {
                    ["rust-analyzer"] = {
                        cargo = { allFeatures = true },
                        check = { command = "clippy" },
                        checkOnSave = true,
                        diagnostics = { enable = true },
                    },
                },
            },
        }
    end,
}
