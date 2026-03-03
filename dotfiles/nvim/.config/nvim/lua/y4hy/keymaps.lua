vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
keymap.set("n", "<leader>e", vim.cmd.Ex, { desc = "Open netrw file explorer (Ex)" })

vim.cmd([[
  let g:netrw_nogx = 1
  autocmd FileType netrw nmap <buffer> <Tab> <CR>
]])

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights in buffer" })

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically (side by side)" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally (top and bottom)" })
keymap.set("n", "<leader>ss", "<C-w>=", { desc = "Make all split windows equal size" })

-- resize windows
keymap.set("n", "<A-Up>", ":resize -2<CR>", { desc = "Decrease current window height by 2" })
keymap.set("n", "<A-Down>", ":resize +2<CR>", { desc = "Increase current window height by 2" })
keymap.set("n", "<A-Right>", ":vertical resize -2<CR>", { desc = "Decrease current window width by 2" })
keymap.set("n", "<A-Left>", ":vertical resize +2<CR>", { desc = "Increase current window width by 2" })

keymap.set("n", "<leader>q", "<cmd>tabnew<CR>", { desc = "Create a new empty tab" })
keymap.set("n", "<leader>c", "<cmd>tabclose<CR>", { desc = "Close the current tab" })
keymap.set({ "n", "i" }, "<M-[>", "<cmd>tabp<CR>", { desc = "Switch to previous tab" })
keymap.set({ "n", "i" }, "<M-]>", "<cmd>tabn<CR>", { desc = "Switch to next tab" })
keymap.set("n", "<leader><Tab>", "<cmd>tablast<CR>", { desc = "Go to the last tab" })
keymap.set("n", "<leader>o", ":tabnew ", { desc = "Open a file in a new tab (type path)" })

-- buffer management
keymap.set("v", "<C-c>", '"+y', { desc = "Copy visual selection to system clipboard" })

-- move selected lines
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down and reselect" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up and reselect" })

-- join lines and keep cursor position
keymap.set("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- centered scrolling and search
keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll half-page down and center" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll half-page up and center" })
keymap.set("n", "n", "nzzzv", { desc = "Next search result centered" })
keymap.set("n", "N", "Nzzzv", { desc = "Previous search result centered" })

-- paste without yanking (greatest remap ever)
keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste over selection without yanking" })

-- clipboard yank
keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" })

-- delete to black hole register
keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete to black hole register" })

-- escape from insert mode with C-c
keymap.set("i", "<C-c>", "<Esc>", { desc = "Escape insert mode with Ctrl-c" })

-- disable Q
keymap.set("n", "Q", "<nop>", { desc = "Disable Ex mode" })

-- substitute word under cursor
keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute word under cursor" })

-- source current file
keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end, { desc = "Source current file" })
