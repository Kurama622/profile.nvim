local comp = require("profile.components")
local api = vim.api

---@private
local function homepage_instance(opts)
  local OFFSET = {}
  comp.opts = opts
  comp.OFFSET = OFFSET
  OFFSET.y = 1
  local header_offset = opts.avatar_opts.avatar_height / 2 + opts.avatar_opts.avatar_y
  for _ = 1, header_offset do
    comp:text_component_render({ comp:separator() })
  end
  opts.format()
  --defer until next event loop
  vim.schedule(function()
    api.nvim_exec_autocmds("User", {
      pattern = "ProfileLoaded",
      modeline = false,
    })
  end)
end

return setmetatable({}, {
  __call = function(_, t)
    return homepage_instance(t)
  end,
})
