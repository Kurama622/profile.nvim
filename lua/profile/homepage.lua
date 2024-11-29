local comp = require("profile.components")
local utils = require("profile.utils")
local api = vim.api

---@private
local function homepage_instance(opts)
  local OFFSET = {}
  if type(opts.disable_keys) == "table" then
    utils.disable_move_key(opts.bufnr, opts.disable_keys)
  end
  comp.opts = opts
  comp.OFFSET = OFFSET
  OFFSET.y = 1
  if opts.avatar_opts.force_blank then
    local header_offset = opts.avatar_opts.avatar_height / 2 + opts.avatar_opts.avatar_y
    for _ = 1, header_offset do
      comp:text_component_render({ comp:separator() })
    end
  end
  opts.format()
  --defer until next event loop
  vim.schedule(function()
    api.nvim_exec_autocmds("User", {
      pattern = "ProfileLoaded",
      modeline = false,
    })
  end)

  if opts.cursor_pos and type(opts.cursor_pos) == "table" then
    vim.api.nvim_win_set_cursor(opts.winid, opts.cursor_pos)
  end
end

return setmetatable({}, {
  __call = function(_, t)
    return homepage_instance(t)
  end,
})
