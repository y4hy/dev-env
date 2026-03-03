return {
    "christoomey/vim-tmux-navigator",
    cmd = {
        "TmuxNavigateLeft",
        "TmuxNavigateDown",
        "TmuxNavigateUp",
        "TmuxNavigateRight",
        "TmuxNavigatePrevious",
    },
    keys = {
        { "<C-h>", "<cmd>TmuxNavigateLeft<CR>", desc = "Navigate to left pane (tmux/nvim)" },
        { "<C-j>", "<cmd>TmuxNavigateDown<CR>", desc = "Navigate to bottom pane (tmux/nvim)" },
        { "<C-k>", "<cmd>TmuxNavigateUp<CR>", desc = "Navigate to top pane (tmux/nvim)" },
        { "<C-l>", "<cmd>TmuxNavigateRight<CR>", desc = "Navigate to right pane (tmux/nvim)" },
        { "<C-\\>", "<cmd>TmuxNavigatePrevious<CR>", desc = "Navigate to previous pane (tmux/nvim)" },
    },
}
