return {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    opts = {
        providers = {
            copilot = {
                endpoint = "https://api.githubcopilot.com",
                model = "claude-3.7-sonnet",
                proxy = nil, -- [protocol://]host[:port] Use this proxy
                allow_insecure = false, -- Allow insecure server connections
                timeout = 30000, -- Timeout in milliseconds
                temperature = 0,
                max_tokens = 20480,
                disable_tools = false,
                extra_request_body = {
                    max_tokens = 20480, -- Override the default max_tokens for copilot
                    temperature = 0, -- Override the default temperature for copilot
                }
            },
        },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "stevearc/dressing.nvim",
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        --- The below dependencies are optional,
        "echasnovski/mini.pick", -- for file_selector provider mini.pick
        "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
        "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
        "ibhagwan/fzf-lua", -- for file_selector provider fzf
        "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
        "zbirenbaum/copilot.lua", -- for providers='copilot'
        {
            -- support for image pasting
            "HakonHarnes/img-clip.nvim",
            event = "VeryLazy",
            opts = {
                -- recommended settings
                default = {
                    embed_image_as_base64 = false,
                    prompt_for_file_name = false,
                    drag_and_drop = {
                        insert_mode = true,
                    },
                    -- required for Windows users
                    use_absolute_path = true,
                },
            },
        },
        {
            -- Make sure to set this up properly if you have lazy=true
            'MeanderingProgrammer/render-markdown.nvim',
            opts = {
                file_types = { "markdown", "Avante" },
            },
            ft = { "markdown", "Avante" },
        },
    },
    config = function()
        require("avante").setup({
            -- other avante configurations
            hints = { enabled = false },
            system_prompt = function()
                local hub = require("mcphub").get_hub_instance()
                if hub then
                    return hub:get_active_servers_prompt()
                else
                    return "You are a helpful AI assistant."
                end
            end,
            custom_tools = function()
                local mcphub_extension = require("mcphub.extensions.avante")
                if mcphub_extension and mcphub_extension.mcp_tool then
                    return { mcphub_extension.mcp_tool() }
                else
                    return {}
                end
            end,

            disabled_tools = {
                "list_files",
                "search_files",
                "read_file",
                "create_file",
                "rename_file",
                "delete_file",
                "create_dir",
                "rename_dir",
                "delete_dir",
                "bash",
                "python",
            },

            providers = {
                copilot = {
                    endpoint = "https://api.githubcopilot.com",
                    model = "claude-3.7-sonnet",
                    proxy = nil, -- [protocol://]host[:port] Use this proxy
                    allow_insecure = false, -- Allow insecure server connections
                    timeout = 30000, -- Timeout in milliseconds
                    disable_tools = false,
                    extra_request_body = {
                        max_tokens = 20480, -- Override the default max_tokens for copilot
                        temperature = 0, -- Override the default temperature for copilot
                    }
                },
            },
            provider = "copilot", -- Default provider
        })
    end
}

