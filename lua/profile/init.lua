local api, fn = vim.api, vim.fn
local utils = require("profile.utils")
local comp = require("profile.components")
local ctx = {}
local pf = {}

pf.__index = pf
pf.__newindex = function(t, k, v)
  rawset(t, k, v)
end

local function clean_avatar(obj)
  if obj then
    obj:clear()
    obj = nil
  end
end

local function show_avatar(obj)
  if obj then
    obj:render()
  end
end

local function plugin_path()
  local d = debug.getinfo(1).source:sub(2)
  return vim.fn.fnamemodify(d, ":h")
end

local function default_options()
  local win_width = vim.o.columns
  return {
    disable_keys = nil,
    cursor_pos = nil,
    avatar_path = plugin_path() .. "/../../resources/profile.png",
    avatar_opts = {
      avatar_width = 20,
      avatar_height = 20,
      avatar_x = math.floor((win_width - 20) / 2),
      avatar_y = 7,
      force_blank = true,
    },
    user = "Kurama622",
    git_contributions = {
      start_week = 1,
      end_week = 53,
      empty_char = "□",
      full_char = { "■", "■", "■", "■", "■" },
      fake_contributions = nil,
      non_official_api_cmd = nil,
      cache_path = "/tmp/profile.nvim/",
      cache_duration = 24 * 60 * 60, -- seconds
    },
    format = function()
      comp:avatar()
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
      comp:git_contributions_render()
    end,
    obj = {
      avatar = nil,
    },
    hide = {
      statusline = true,
      tabline = true,
    },
    bufnr = nil,
    winid = nil,
  }
end

local function buf_local()
  local opts = {
    ["bufhidden"] = "wipe",
    ["colorcolumn"] = "",
    ["foldcolumn"] = "0",
    ["matchpairs"] = "",
    ["buflisted"] = false,
    ["cursorcolumn"] = false,
    ["cursorline"] = false,
    ["list"] = false,
    ["number"] = false,
    ["relativenumber"] = false,
    ["spell"] = false,
    ["swapfile"] = false,
    ["readonly"] = false,
    ["filetype"] = "profile",
    ["wrap"] = false,
    ["signcolumn"] = "no",
  }
  for opt, val in pairs(opts) do
    vim.opt_local[opt] = val
  end
  if fn.has("nvim-0.9") == 1 then
    vim.opt_local.stc = ""
  end
end

function pf:save_user_options()
  self.user_cursor_line = vim.opt.cursorline:get()
  self.user_laststatus_value = vim.opt.laststatus:get()
  self.user_tabline_value = vim.opt.showtabline:get()
  self.user_winbar_value = vim.opt.winbar:get()
end

function pf:set_ui_options(opts)
  if opts.hide.statusline then
    vim.opt.laststatus = 0
  end
  if opts.hide.tabline then
    vim.opt.showtabline = 0
  end
  if opts.hide.winbar then
    vim.opt.winbar = ""
  end

  if opts.obj.avatar then
    show_avatar(opts.obj.avatar)
  end
end

function pf:restore_user_options(opts)
  if self.user_cursor_line then
    vim.opt.cursorline = self.user_cursor_line
  end

  if opts.hide.statusline and self.user_laststatus_value then
    vim.opt.laststatus = tonumber(self.user_laststatus_value)
  end

  if opts.hide.tabline and self.user_tabline_value then
    vim.opt.showtabline = tonumber(self.user_tabline_value)
  end

  if opts.hide.winbar and self.user_winbar_value then
    vim.opt.winbar = self.user_winbar_value
  end
end

function pf:clear(opts)
  clean_avatar(opts.obj.avatar)
  vim.bo[self.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, {})
end

function pf:render(opts)
  require("profile.homepage")(opts)
  self:set_ui_options(opts)
  vim.bo[self.bufnr].modifiable = false
end

function pf:init(opts)
  opts.bufnr = self.bufnr
  opts.winid = self.winid

  self:render(opts)

  api.nvim_create_autocmd("VimResized", {
    buffer = self.bufnr,
    callback = function()
      self:clear(opts)
      self:render(opts)
    end,
  })

  api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
    callback = function()
      local ft = vim.bo.filetype
      if ft ~= "profile" and ft ~= "noice" then
        clean_avatar(opts.obj.avatar)
      end
    end,
  })

  api.nvim_create_autocmd("BufEnter", {
    callback = function(opt)
      if vim.bo.filetype == "profile" then
        self:set_ui_options(opts)
        return
      end

      local bufs = api.nvim_list_bufs()

      bufs = vim.tbl_filter(function(k)
        return vim.bo[k].filetype == "profile"
      end, bufs)

      -- restore the user's UI settings is no profile buffers are visible
      local wins = api.nvim_tabpage_list_wins(0)
      wins = vim.tbl_filter(function(k)
        return vim.tbl_contains(bufs, api.nvim_win_get_buf(k))
      end, wins)

      if #wins == 0 then
        self:restore_user_options(opts)
      end

      if #bufs == 0 then
        pcall(api.nvim_del_autocmd, opt.id)
      end
    end,
    desc = "[Profile] clean profile data reduce memory",
  })
end

-- create profile instance
function pf:instance()
  local mode = api.nvim_get_mode().mode
  if mode == "i" or not vim.bo.modifiable then
    return
  end

  if not vim.o.hidden and vim.bo.modified then
    --save before open
    vim.cmd.write()
    return
  end

  if not utils.buf_is_empty(0) then
    self.bufnr = api.nvim_create_buf(false, true)
  else
    self.bufnr = api.nvim_get_current_buf()
  end

  self.winid = api.nvim_get_current_win()
  api.nvim_win_set_buf(self.winid, self.bufnr)

  self:save_user_options()

  buf_local()
  if self.opts then
    self:init(self.opts)
  end
end

function pf.setup(opts)
  opts = opts or {}
  ctx.opts = vim.tbl_deep_extend("force", default_options(), opts)
end

return setmetatable(ctx, pf)
