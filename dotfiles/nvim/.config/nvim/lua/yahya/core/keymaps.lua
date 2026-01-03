vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
keymap.set("n", "<leader>e", "<cmd>Exp<CR>", { desc = "Open netrw file explorer" })

vim.cmd([[
  let g:netrw_nogx = 1
  autocmd FileType netrw nmap <buffer> <Tab> <CR>
]])

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights in buffer" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number under cursor" })
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number under cursor" })

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically (side by side)" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally (top and bottom)" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make all split windows equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split window" })

-- resize windows
keymap.set("n", "<A-Up>", ":resize -2<CR>", { desc = "Decrease current window height by 2" })
keymap.set("n", "<A-Down>", ":resize +2<CR>", { desc = "Increase current window height by 2" })
keymap.set("n", "<A-Right>", ":vertical resize -2<CR>", { desc = "Decrease current window width by 2" })
keymap.set("n", "<A-Left>", ":vertical resize +2<CR>", { desc = "Increase current window width by 2" })

keymap.set("n", "<leader>nn", "<cmd>tabnew<CR>", { desc = "Create a new empty tab" })
keymap.set("n", "<leader>nx", "<cmd>tabclose<CR>", { desc = "Close the current tab" })
keymap.set("n", "^", "<cmd>tabp<CR>", { desc = "Switch to previous tab" })
keymap.set("n", "¬", "<cmd>tabn<CR>", { desc = "Switch to next tab" })
keymap.set("n", "<leader>o", ":tabnew ", { desc = "Open a file in a new tab (type path)" })

for i = 1, 9 do
    keymap.set("n", "<A-" .. i .. ">", "<cmd>tabn " .. i .. "<CR>", { desc = "Jump to tab number " .. i })
    keymap.set("i", "<A-" .. i .. ">", "<Esc><cmd>tabn " .. i .. "<CR>", { desc = "Jump to tab number " .. i })
end

keymap.set({ "n", "i" }, "<A-l>", "<cmd>tabn<CR>", { desc = "Switch to next tab (Alt+l)" })
keymap.set({ "n", "i" }, "<A-h>", "<cmd>tabp<CR>", { desc = "Switch to previous tab (Alt+h)" })

-- buffer management
keymap.set("v", "<C-c>", '"+y', { desc = "Copy visual selection to system clipboard" })

-- move selected lines
keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up and reselect" })
keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down and reselect" })
