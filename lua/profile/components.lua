local utils = require("profile.utils")
local api = vim.api
local comp = {}
function comp:avatar()
  local img = require("image")
  self.opts.obj.avatar = img.from_file(self.opts.avatar_path, {
    id = "avatar",
    inline = true,
    x = self.opts.avatar_opts.avatar_x,
    y = self.opts.avatar_opts.avatar_y,
    width = self.opts.avatar_opts.avatar_width,
    height = self.opts.avatar_opts.avatar_height,
  })
end

function comp:text_component_render(tbl)
  for _, v in pairs(tbl) do
    local text, hl = v.content(), v.hl
    api.nvim_set_option_value("modifiable", true, { buf = self.opts.bufnr })
    api.nvim_set_option_value("modified", true, { buf = self.opts.bufnr })
    hl = hl or "Normal"
    api.nvim_buf_set_lines(self.opts.bufnr, self.OFFSET.y, self.OFFSET.y, false, { text })
    api.nvim_buf_add_highlight(self.opts.bufnr, -1, hl, self.OFFSET.y, 0, -1)
    self.OFFSET.y = self.OFFSET.y + 1
    api.nvim_set_option_value("modifiable", false, { buf = self.opts.bufnr })
    api.nvim_set_option_value("modified", false, { buf = self.opts.bufnr })
  end
end

function comp:text_component(text, align, hl)
  hl = hl or "Normal"
  return {
    type = "text",
    content = function()
      align = align or "right"
      if align == "center" then
        return utils.center_align(text)
      elseif align == "right" then
        return utils.right_align(text)
      elseif align == "left" then
        return text
      else
        return text
      end
    end,
    hl = hl,
  }
end

function comp:separator()
  return {
    type = "sep",
    content = function()
      return ""
    end,
  }
end

function comp:separator_render(tbl)
  tbl = tbl or { comp:separator() }
  comp:text_component_render(tbl)
end

local function gen_git_contribute_map(opts, contributions, contribute_map)
  for row = 1, 7 do
    contribute_map[row] = ""
    for col = opts.git_contributions.start_week, opts.git_contributions.end_week do
      if contributions[tostring(col)][row] == nil then
        contribute_map[row] = contribute_map[row] .. "  "
      elseif contributions[tostring(col)][row] == 0 then
        contribute_map[row] = contribute_map[row] .. opts.git_contributions.empty_char .. " "
      else
        local size = contributions[tostring(col)][row] > 5 and 5 or contributions[tostring(col)][row]
        contribute_map[row] = contribute_map[row] .. opts.git_contributions.full_char[size] .. " "
      end
    end
    contribute_map[row] = utils.center_align(contribute_map[row])
  end
end

local function async_get_git_contributions(opts, callback)
  local contribute_map = {}
  if opts.git_contributions.fake_contributions ~= nil then
    local contributions = opts.git_contributions.fake_contributions()
    gen_git_contribute_map(opts, contributions, contribute_map)
    pcall(callback, contribute_map)
  else
    local cmd =
      [[curl -s -H "Authorization: bearer $GITHUB_TOKEN" -X POST -d '{"query":"query {user(login: \"%s\") {contributionsCollection {contributionCalendar {weeks {contributionDays {contributionCount}}}}}}"}' https://api.github.com/graphql | \
jq -c 'reduce (.data.user.contributionsCollection.contributionCalendar.weeks | to_entries[]) as $week ({}; .[$week.key + 1 | tostring] = [$week.value.contributionDays[].contributionCount])']]
    if opts.git_contributions.non_official_api_cmd then
      cmd = opts.git_contributions.non_official_api_cmd
    end
    vim.fn.jobstart(string.format(cmd, opts.user), {
      on_stdout = function(job_id, data, event_type)
        vim.schedule(function()
          local str = ""
          for _, line in ipairs(data) do
            str = str .. line
          end
          if str == "" or str == " " or str == "\n" then
            return
          end
          local contributions = vim.json.decode(str)
          gen_git_contribute_map(opts, contributions, contribute_map)
          pcall(callback, contribute_map)
        end)
      end,
    })
  end
end

function comp:git_contributions_render(hl)
  hl = hl or "ProfileGreen"
  async_get_git_contributions(self.opts, function(map)
    api.nvim_set_option_value("modifiable", true, { buf = self.opts.bufnr })
    api.nvim_set_option_value("modified", true, { buf = self.opts.bufnr })
    for row = 1, 7 do
      api.nvim_buf_set_lines(self.opts.bufnr, self.OFFSET.y + row, self.OFFSET.y + row, false, { map[row] })
    end

    api.nvim_set_option_value("modifiable", false, { buf = self.opts.bufnr })
    api.nvim_set_option_value("modified", false, { buf = self.opts.bufnr })
    for row = 0, 6 do
      api.nvim_buf_add_highlight(self.opts.bufnr, -1, hl, self.OFFSET.y + row, 0, -1)
    end
    self.OFFSET.y = self.OFFSET.y + 7
  end)
end

local function card_component()
  -- curl GET https://pinned.berrysauce.me/get/kurama622
  return {
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
      border = "Comment",
      text = "Normal",
    },
  }
end

function comp:card_component_render(cards)
  cards = cards or card_component()
  api.nvim_set_option_value("modifiable", true, { buf = self.opts.bufnr })
  api.nvim_set_option_value("modified", true, { buf = self.opts.bufnr })
  local cards_info = cards.content()

  local result = {}
  local border_char_pos = {}
  local border_char_width = #"─"
  local card_height = 0
  for i = 1, #cards_info, 2 do
    local row = {}
    local first_card = cards_info[i]
    local second_card = cards_info[i + 1]

    local title1 = first_card.title or ""
    local desc1 = first_card.description or ""
    local desc_line_cnt1, desc_lines1, desc_max_len1 = utils.string_info(desc1)
    local title2 = second_card and second_card.title or ""
    local desc2 = second_card and second_card.description or ""
    local desc_line_cnt2, desc_lines2, desc_max_len2 = utils.string_info(desc2)

    local max_desc_height = math.max(desc_line_cnt1, desc_line_cnt2)
    card_height = max_desc_height + 4

    local name_padding_left1 = 0
    local name_padding_right1 = 0
    local name_padding_left2 = 0
    local name_padding_right2 = 0
    local desc_padding_left1 = 0
    local desc_padding_right1 = 0
    local desc_padding_left2 = 0
    local desc_padding_right2 = 0

    if desc_max_len1 > #title1 then
      name_padding_left1 = math.ceil((desc_max_len1 - #title1) / 2)
      name_padding_right1 = desc_max_len1 - name_padding_left1 - #title1
    else
      desc_padding_left1 = math.ceil((#title1 - desc_max_len1) / 2)
      desc_padding_right1 = #title1 - desc_padding_left1 - desc_max_len1
    end

    if desc_max_len2 > #title2 then
      name_padding_left2 = math.ceil((desc_max_len2 - #title2) / 2)
      name_padding_right2 = desc_max_len2 - name_padding_left2 - #title2
    else
      desc_padding_left2 = math.ceil((#title2 - desc_max_len2) / 2)
      desc_padding_right2 = #title2 - desc_padding_left2 - desc_max_len2
    end

    local name_space_left1 = string.rep(" ", name_padding_left1)
    local name_space_right1 = string.rep(" ", name_padding_right1)
    local name_space_left2 = string.rep(" ", name_padding_left2)
    local name_space_right2 = string.rep(" ", name_padding_right2)
    local desc_space_left1 = string.rep(" ", desc_padding_left1)
    local desc_space_right1 = string.rep(" ", desc_padding_right1)
    local desc_space_left2 = string.rep(" ", desc_padding_left2)
    local desc_space_right2 = string.rep(" ", desc_padding_right2)
    local sep_pos1 = 0
    local sep_pos2 = border_char_width + name_padding_left1 + #title1 + name_padding_right1 + 2
    local sep_pos3 = sep_pos2 + border_char_width + 1
    local sep_pos4 = sep_pos3 + border_char_width + name_padding_left2 + #title2 + name_padding_right2 + 2

    table.insert(border_char_pos, { sep_pos1, sep_pos2, sep_pos3, sep_pos4 })
    table.insert(
      row,
      string.format(
        "╭%s╮ ╭%s╮",
        string.rep("─", name_padding_left1 + #title1 + name_padding_right1 + 2),
        string.rep("─", name_padding_left2 + #title2 + name_padding_right2 + 2)
      )
    )

    table.insert(
      row,
      string.format(
        "│ %s%s%s │ │ %s%s%s │",
        name_space_left1,
        title1,
        name_space_right1,
        name_space_left2,
        title2,
        name_space_right2
      )
    )

    table.insert(
      row,
      string.format(
        "│ %s%s%s │ │ %s%s%s │",
        string.rep(" ", name_padding_left1 - api.nvim_strwidth("─")),
        string.rep("─", api.nvim_strwidth(title1) / api.nvim_strwidth("─") + 2),
        string.rep(" ", name_padding_right1 - api.nvim_strwidth("─")),
        string.rep(" ", name_padding_left2 - api.nvim_strwidth("─")),
        string.rep("─", api.nvim_strwidth(title2) / api.nvim_strwidth("─") + 2),
        string.rep(" ", name_padding_right2 - api.nvim_strwidth("─"))
      )
    )

    local pattern = "│ %s%-" .. desc_max_len1 .. "s%s │ │ %s%-" .. desc_max_len2 .. "s%s │"
    for h = 1, max_desc_height do
      table.insert(
        row,
        string.format(
          pattern,
          desc_space_left1,
          desc_lines1[h],
          desc_space_right1,
          desc_space_left2,
          desc_lines2[h] and desc_lines2[h] or "",
          desc_space_right2
        )
      )
    end
    table.insert(
      row,
      string.format(
        "╰%s╯ ╰%s╯",
        string.rep("─", name_padding_left1 + #title1 + name_padding_right1 + 2),
        string.rep("─", name_padding_left2 + #title2 + name_padding_right2 + 2)
      )
    )

    table.insert(result, row)
  end

  local offset_x = {}
  for i = 1, #result do
    table.insert(offset_x, math.floor((vim.o.columns - vim.api.nvim_strwidth(result[i][1])) / 2))
    local final_lines = {}
    for n = 1, card_height do
      table.insert(final_lines, utils.center_align(result[i][n]))
    end
    api.nvim_buf_set_lines(
      self.opts.bufnr,
      self.OFFSET.y + (i - 1) * card_height,
      self.OFFSET.y + #final_lines + (i - 1) * card_height,
      false,
      final_lines
    )
  end
  api.nvim_set_option_value("modifiable", false, { buf = self.opts.bufnr })
  api.nvim_set_option_value("modified", false, { buf = self.opts.bufnr })
  for i = 1, #result do
    for idx = 1, card_height do
      vim.api.nvim_buf_add_highlight(
        self.opts.bufnr,
        -1,
        cards.hl.text,
        self.OFFSET.y + (i - 1) * card_height + idx,
        0,
        -1
      )

      vim.api.nvim_buf_add_highlight(
        self.opts.bufnr,
        -1,
        cards.hl.border,
        self.OFFSET.y + (i - 1) * card_height + idx,
        border_char_pos[i][1] + offset_x[i],
        border_char_pos[i][1] + border_char_width + offset_x[i]
      )
      vim.api.nvim_buf_add_highlight(
        self.opts.bufnr,
        -1,
        cards.hl.border,
        self.OFFSET.y + (i - 1) * card_height + idx,
        border_char_pos[i][2] + offset_x[i],
        border_char_pos[i][2] + border_char_width + offset_x[i]
      )
      vim.api.nvim_buf_add_highlight(
        self.opts.bufnr,
        -1,
        cards.hl.border,
        self.OFFSET.y + (i - 1) * card_height + idx,
        border_char_pos[i][3] + offset_x[i],
        border_char_pos[i][3] + border_char_width + offset_x[i]
      )
      vim.api.nvim_buf_add_highlight(
        self.opts.bufnr,
        -1,
        cards.hl.border,
        self.OFFSET.y + (i - 1) * card_height + idx,
        border_char_pos[i][4] + offset_x[i],
        border_char_pos[i][4] + border_char_width + offset_x[i]
      )
    end
    vim.api.nvim_buf_add_highlight(self.opts.bufnr, -1, cards.hl.border, self.OFFSET.y + (i - 1) * card_height, 0, -1)
    vim.api.nvim_buf_add_highlight(
      self.opts.bufnr,
      -1,
      cards.hl.border,
      self.OFFSET.y + (i - 1) * card_height + card_height - 1,
      0,
      -1
    )
    vim.api.nvim_buf_add_highlight(
      self.opts.bufnr,
      -1,
      cards.hl.border,
      self.OFFSET.y + (i - 1) * card_height + 2,
      0,
      -1
    )
  end
  self.OFFSET.y = self.OFFSET.y + card_height * #result
end
return comp
