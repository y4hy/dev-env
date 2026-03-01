function ColorMyPencils(color)
	color = color or "rose-pine-moon"
    vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
	vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
	vim.api.nvim_set_hl(0, "WinSeparator", { bg = "none" })
end

return {
    {
        'jesseleite/nvim-noirbuddy',
        dependencies = {
            { 'tjdevries/colorbuddy.nvim' }
        },
        priority = 1000,
        lazy = false,
        config = function()
            require("noirbuddy").setup()
            ColorMyPencils("noirbuddy")
        end
    },
}
