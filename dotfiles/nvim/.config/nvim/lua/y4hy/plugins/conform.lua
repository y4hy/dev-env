return {
	"stevearc/conform.nvim",
	opts = {},
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				c = { "clang-format" },
				cpp = { "clang-format" },
				lua = { "stylua" },
                rust = { "rustfmt" },
			},
			formatters = {
				["clang-format"] = {
					prepend_args = { "-style=file", "-fallback-style=LLVM" },
				},
			},
			format_on_save = function(bufnr)
				return { timeout_ms = 500, lsp_format = "fallback" }
			end,
		})

		vim.keymap.set("n", "<leader>fr", function()
			require("conform").format({ bufnr = 0 })
		end, { desc = "Format current buffer" })
	end,
}
