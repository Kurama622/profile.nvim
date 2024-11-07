-- version 0.2.3

local g = vim.api.nvim_create_augroup("nvim-profile", { clear = true })

local highlight = {
  ProfileRed = { fg = "#ffc0cb", bg = "NONE" },
  ProfileBlue = { fg = "#B0E2FF", bg = "NONE" },
  Profilegreen = { fg = "#c1Eac1", bg = "NONE" },
  Profileyellow = { fg = "#ffe4c4", bg = "NONE" },
}

for k, v in pairs(highlight) do
  vim.api.nvim_set_hl(0, k, v)
end

vim.api.nvim_create_autocmd("StdinReadPre", {
  group = g,
  callback = function()
    vim.g.read_from_stdin = 1
  end,
})

vim.api.nvim_create_autocmd("UIEnter", {
  group = g,
  callback = function()
    if vim.fn.argc() == 0 and vim.api.nvim_buf_get_name(0) == "" and vim.g.read_from_stdin == nil then
      require("profile"):instance()
    end
  end,
})

-- vim.api.nvim_create_autocmd({ "BufEnter" }, {
--   group = g,
--   callback = function()
--     require("profile"):close()
--   end,
-- })

vim.api.nvim_create_user_command("Profile", function()
  require("profile"):instance()
end, {})
