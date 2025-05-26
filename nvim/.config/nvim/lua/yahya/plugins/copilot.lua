return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        config = function()
            require("copilot").setup({
                suggestion = {
                    enabled = true,
                    auto_trigger = false,
                    hide_during_completion = false,
                    debounce = 25,
                    keymap = {
                        accept = false,
                        accept_word = "<C-q>",
                        accept_line = "<Tab>",
                        next = "<C-w>",
                        prev = "<C-b>",
                        dismiss = "<C-x>",
                    },
                },
            })
        end,
    },
}
