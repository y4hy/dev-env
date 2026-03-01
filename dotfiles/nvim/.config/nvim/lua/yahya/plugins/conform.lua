return {
	"stevearc/conform.nvim",
	opts = {},
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				c = { "clang-format" },
				cpp = { "clang-format" },
				lua = { "stylua" },
				go = { "gofmt" },
				javascript = { "prettier" },
				typescript = { "prettier" },
			},
            formatters = {
                ["clang-format"] = {
                    prepend_args = { "-style=file", "-fallback-style=LLVM" },
                },
            },
		})

        vim.keymap.set("n", "<leader>fr", function()
            require("conform").format({ bufnr = 0, lsp_format = "fallback" })
        end, { desc = "Format current buffer (formatter or LSP fallback)" })

	end,
}
