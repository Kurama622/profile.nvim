# profile.nvim

<!-- mtoc-start -->

* [Dependencies](#dependencies)
* [Installation](#installation)
  * [image.nvim configuration](#imagenvim-configuration)
* [Define User Mappings](#define-user-mappings)
* [Some Unicode characters you might be interested in](#some-unicode-characters-you-might-be-interested-in)
* [Sample Configuration](#sample-configuration)
  * [ASCII Art](#ascii-art)
* [References](#references)

<!-- mtoc-end -->

Your personal homepage.

![profile-default](https://github.com/user-attachments/assets/ec627c79-ebac-46f5-8728-57472836642a)
![profile-custom](https://github.com/user-attachments/assets/24f8d775-f484-47a1-a278-b011817db08b)
![profile-ascii](https://github.com/user-attachments/assets/8987ecac-4e98-4aec-8f04-26f0ad598603)
![freecompress-profile-homepage](https://github.com/user-attachments/assets/890bade1-609c-4a95-8329-841831428310)


Will it make your neovim startup slower? No! Your worries are unnecessary!

![startup time](https://github.com/user-attachments/assets/121fd395-7631-4400-9ff0-351fc6f94786)


## Dependencies

- ["3rd/image.nvim"](https://github.com/3rd/image.nvim) - see [image.nvim:Installation](https://github.com/3rd/image.nvim?tab=readme-ov-file#installation).   **(optional, dependency of displaying images. If you do not display the image, then it is not necessary.)**



- curl, jq.  **(optional, dependency of git contribution map. If you do not display the contribution map, then it is not necessary.)**

- Github Token: [https://github.com/settings/tokens](https://github.com/settings/tokens) **(optional, If you use a third-party API to fetch git contributions, then you don't need a Github Token.)**

## Installation

- lazy.nvim

```lua
{
  "Kurama622/profile.nvim",
  dependencies = { "3rd/image.nvim" },
  config = function()
    require("profile").setup({
      avatar_path = "<your avatar path>", -- default: profile.nvim/resources/profile.png
      user = "<your github username>",
    })
    vim.api.nvim_set_keymap("n", "<leader>p", "<cmd>Profile<cr>", { silent = true })
  end
}
```


**Complete configuration**

You also can refer to my [config](https://github.com/Kurama622/.lazyvim/blob/main/lua/plugins/profile.lua).

```lua
  {
    "Kurama622/profile.nvim",
    dependencies = { "3rd/image.nvim" },
    config = function()
      local comp = require("profile.components")
      local win_width = vim.o.columns
      require("profile").setup({
        avatar_path = "/home/arch/Github/profile.nvim/resources/profile.png",
        -- avatar position options
        avatar_opts = {
          avatar_width = 20,
          avatar_height = 20,
          avatar_x = math.floor((win_width - 20) / 2),
          avatar_y = 7,
          force_blank = true,   -- if true, will create some blank lines (avatar_height + avatar_y)
        },

        -- git user
        user = "Kurama622",
        git_contributions = {
          start_week = 1, -- The minimum is 1
          end_week = 53, -- The maximum is 53
          empty_char = " ",
          full_char = { "", "󰧞", "", "", "" },
          fake_contributions = nil,
          cache_path = "/tmp/profile.nvim/", -- Cache the data of git contributions locally.
          cache_duration = 24 * 60 * 60, -- seconds, The cache validity period is 1 day.

          --[[
          -- If you want to fake git's contribution information,
          -- you can pass a function to fake_contributions.
          fake_contributions = function()
            local ret = {}
            for i = 1, 53 do
              ret[tostring(i)] = {}
              for j = 1, 7 do
                ret[tostring(i)][j] = math.random(0, 5)
              end
            end
            return ret
          end,
          ]]

          -- if you want to use a third-party API to fetch git contributions
          -- non_official_api_cmd = [[ curl -s "https://github-contributions-api.jogruber.de/v4/%s?y=$(date -d "1 year ago" +%%Y)&y=$(date +%%Y)" \
          --    | jq --arg start $(date -d "1 year ago" +%%Y-%%m-%%d) --arg end $(date +%%Y-%%m-%%d) \
          --    '.contributions | [ .[] | select((.date >= $start) and (.date <= $end)) ] | sort_by(.date) | (.[0].date | strptime("%%Y-%%m-%%d") | strftime("%%w") | tonumber) as $wd | map(.count) | ([range(0, $wd) ] | map(0)) + . | . as $array | reduce range(0; length; 7) as $i ({}; . + {($i/7+1 | tostring): $array[$i:$i+7] })' ]],
        },
        hide = {
          statusline = true,
          tabline = true,
        },

        disable_keys = { "h", "j", "k", "<Left>", "<Right>", "<Up>", "<Down>", "<C-f>" }, -- disable some mappings. (You can use it to disable cursor movement)
        cursor_pos = { 0, 0 },  -- set cursor position

        -- Customize the content to render
        format = function()
          -- render avatar
          comp:avatar()
          -- customize text component
          comp:text_component_render({
            comp:text_component("git@github.com:Kurama622/profile.nvim", "center", "ProfileRed"),
            comp:text_component("──── By Kurama622", "right", "ProfileBlue"),
          })
          comp:separator_render()

          -- Custom card component, render git repository by default
          comp:card_component_render({
            type = "table",
            content = function()
              return {
                {
                  title = "kurama622/llm.nvim",
                  description = [[LLM Neovim Plugin: Effortless Natural
Language Generation with LLM's API]],
                },
                {
                  title = "kurama622/profile.nvim",
                  description = [[A Neovim plugin: Your Personal Homepage]],
                },
              }
            end,
            hl = {
              border = "ProfileYellow",
              text = "ProfileYellow",
            },
          })
          comp:separator_render()

          -- git contributions, Considering network latency, the module will render asynchronously.
          -- you can also configure `fake_contributions`, so it won't fetch data from the Github
          comp:git_contributions_render("ProfileGreen")
        end,
      })
      vim.api.nvim_set_keymap("n", "<leader>p", "<cmd>Profile<cr>", { silent = true })
    end,
  },
```

### image.nvim configuration

`backend` can be `ueberzug` or `kitty`: MacOS only supports `kitty`

```lua
  {
    "3rd/image.nvim",
    dependencies = {
      "leafo/magick",
    },
    config = function()
      require("image").setup({
        backend = "ueberzug",
        -- backend = "kitty",
        kitty_method = "normal",
        integrations = {
          markdown = {
            enabled = true,
            clear_in_insert_mode = true,
            download_remote_images = true,
            only_render_image_at_cursor = true,
            filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
          },
          html = {
            enabled = false,
          },
          css = {
            enabled = false,
          },
        },
        max_width = nil,
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 50,
        window_overlap_clear_enabled = true, -- toggles images when windows are overlapped
        -- window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
        editor_only_render_when_focused = true, -- auto show/hide images when the editor gains/looses focus
        tmux_show_only_in_active_window = true, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
        hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
      })
    end,
  },
```

## Define User Mappings

```lua
local user_mappings = {
  n = {
    ["r"] = "<cmd>lua require('telescope.builtin').oldfiles()<cr>",
    ["f"] = "<cmd>lua require('telescope.builtin').find_files()<cr>",
    ["c"] = "<cmd>lua require('telescope.builtin').find_files({ cwd = '$HOME/.config/nvim' })<cr>",
    ["/"] = "<cmd>lua require('telescope.builtin').live_grep()<cr>",
    ["n"] = "<cmd>enew<cr>",
    ["l"] = "<cmd>Lazy<cr>",
  },
}
vim.api.nvim_create_autocmd("FileType", {
  pattern = "profile",
  callback = function()
    for mode, mapping in pairs(user_mappings) do
      for key, cmd in pairs(mapping) do
        vim.api.nvim_buf_set_keymap(0, mode, key, cmd, { noremap = true, silent = true })
      end
    end
  end,
})
```
Refer to my [config](https://github.com/Kurama622/.lazyvim/blob/main/lua/plugins/profile.lua).


## Some Unicode characters you might be interested in

```lua
--[[
full_char = { "█", "█", "█", "█", "█" },
full_char = { "■", "■", "■", "■", "■" },
full_char = { "▄", "▅", "▆", "▇", "█" },
full_char = { "", "󰧞", "", "", "" },
]]
```

## Sample Configuration

### ASCII Art

```lua
return {
  {
    "Kurama622/profile.nvim",
    config = function()
      local comp = require("profile.components")
      require("profile").setup({
        avatar_opts = {
          force_blank = false,
        },
        user = "Kurama622",
        git_contributions = {
          start_week = 1,
          end_week = 53,
          empty_char = " ",
          full_char = { "", "󰧞", "", "", "" },
          fake_contributions = nil,
        },
        hide = {
          statusline = true,
          tabline = true,
        },
        disable_keys = { "h", "j", "k", "<Left>", "<Right>", "<Up>", "<Down>", "<C-f>" },
        cursor_pos = { 17, 48 },
        format = function()
          local header = {
            [[                                                                       ]],
            [[                                                                       ]],
            [[                                                                       ]],
            [[                                                                       ]],
            [[                                                                       ]],
            [[                                                                       ]],
            [[                                                                     ]],
            [[       ████ ██████           █████      ██                     ]],
            [[      ███████████             █████                             ]],
            [[      █████████ ███████████████████ ███   ███████████   ]],
            [[     █████████  ███    █████████████ █████ ██████████████   ]],
            [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
            [[  ███████████ ███    ███ █████████ █████ █████ ████ █████  ]],
            [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
            [[                                                                       ]],
          }
          for _, line in ipairs(header) do
            comp:text_component_render({ comp:text_component(line, "center", "ProfileBlue") })
          end

          comp:text_component_render({
            comp:text_component("git@github.com:Kurama622/profile.nvim", "center", "ProfileRed"),
            comp:text_component("──── By Kurama622", "right", "ProfileBlue"),
          })
          comp:separator_render()
          comp:card_component_render({
            type = "table",
            content = function()
              return {
                {
                  title = "kurama622/llm.nvim",
                  description = [[LLM Neovim Plugin: Effortless Natural
Language Generation with LLM's API]],
                },
                {
                  title = "kurama622/profile.nvim",
                  description = [[A Neovim plugin: Your Personal Homepage]],
                },
              }
            end,
            hl = {
              border = "ProfileYellow",
              text = "ProfileYellow",
            },
          })
          comp:separator_render()
          comp:git_contributions_render("ProfileGreen")
        end,
      })
      vim.api.nvim_set_keymap("n", "<leader>p", "<cmd>Profile<cr>", { silent = true })

      local user_mappings = {
        n = {
          ["r"] = "<cmd>FzfLua oldfiles<cr>",
          ["f"] = "<cmd>FzfLua files<cr>",
          ["c"] = "<cmd>FzfLua files cwd=$HOME/.config/nvim<cr>",
          ["/"] = "<cmd>FzfLua live_grep<cr>",
          ["n"] = "<cmd>enew<cr>",
          ["l"] = "<cmd>Lazy<cr>",
        },
      }
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "profile",
        callback = function()
          for mode, mapping in pairs(user_mappings) do
            for key, cmd in pairs(mapping) do
              vim.api.nvim_buf_set_keymap(0, mode, key, cmd, { noremap = true, silent = true })
            end
          end
        end,
      })
    end,
  },
}
```

## References

- [dashboard-nvim](https://github.com/nvimdev/dashboard-nvim)
