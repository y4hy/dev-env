local opt = vim.opt

opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one
opt.softtabstop = 4

opt.wrap = false

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

opt.cursorline = false

opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- avante.nvim suggesetions
opt.laststatus = 3

-- Set the GUI cursor style
opt.guicursor = ""

-- Disable swap file creation
opt.swapfile = false
-- Disable backup file creation
opt.backup = false
-- Set undo directory
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
-- Enable persistent undo
opt.undofile = true

-- Disable search highlighting
opt.hlsearch = false
-- Enable incremental search
opt.incsearch = true

-- Set number of lines to keep above and below the cursor
opt.scrolloff = 8
-- Append to 'isfname' option
opt.isfname:append("@-@")

-- Set the time to wait before triggering the swap file write
opt.updatetime = 50

