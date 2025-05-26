vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

keymap.set("i", "jk", "<ESC>")
keymap.set("n", "<leader>e", "<cmd>Exp<CR>")

vim.cmd([[
  let g:netrw_nogx = 1
  autocmd FileType netrw nmap <buffer> <Tab> <CR>
]])

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v") -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s") -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=") -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

-- resize windows
keymap.set("n", "<A-Up>", ":resize -2<CR>")
keymap.set("n", "<A-Down>", ":resize +2<CR>")
keymap.set("n", "<A-Right>", ":vertical resize -2<CR>")
keymap.set("n", "<A-Left>", ":vertical resize +2<CR>")

keymap.set("n", "<leader>nn", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>nx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "^", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) -- Alt-h
keymap.set("n", "¬", "<cmd>tabn<CR>", { desc = "Go to next tab" }) -- Alt-l
keymap.set("n", "<leader>o", ":tabnew ", { desc = "Open file in new tab" }) -- open file in new tab

for i = 1, 9 do
    keymap.set("n", "<leader>" .. i, "<cmd>tabn " .. i .. "<CR>")
end

-- buffer management
keymap.set("v", "<C-c>", '"+y')

-- move selected lines
keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })
keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
