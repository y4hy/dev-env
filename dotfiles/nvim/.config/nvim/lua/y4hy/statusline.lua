-- Minimal, pale statusline.
--
-- The colors link to the active theme's `Comment` (and `NonText`) highlights,
-- which are muted and low-contrast by design, so the bar stays unobtrusive and
-- transparent across whichever colorscheme is loaded.

local function set_statusline_hl()
    vim.api.nvim_set_hl(0, "StatusLine", { link = "Comment" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { link = "NonText" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("MinimalStatusline", { clear = true }),
    callback = set_statusline_hl,
})

set_statusline_hl()

vim.opt.statusline = table.concat({
    " ",           -- left padding
    "%f",          -- relative file path
    "%m",          -- modified flag [+]
    "%=",          -- right align the rest
    "%{&filetype}",
    "  %l:%c ",     -- line:column
})
