return {
    "windwp/nvim-autopairs",
    event = { "InsertEnter" },
    dependencies = {
        "hrsh7th/nvim-cmp",
    },
    config = function()
        local autopairs = require("nvim-autopairs")
        local Rule = require("nvim-autopairs.rule")
        local cond = require("nvim-autopairs.conds")

        autopairs.setup({
            check_ts = true,
            ts_config = {
                lua = { "string" },
                rust = { "string" },
            },
        })

        autopairs.add_rules({
            Rule("<", ">", "rust")
                :with_pair(cond.before_regex("[%w_:]+%s*$"))
                :with_move(function(opts) return opts.char == ">" end)
        })

        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        local cmp = require("cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
}
