local uv = vim.loop
local utils = {}

utils.is_win = uv.os_uname().version:match("Windows")

function utils.path_join(...)
  local path_sep = utils.is_win and "\\" or "/"
  return table.concat({ ... }, path_sep)
end

function utils.center_align(text)
  local indent = string.rep(" ", math.floor((vim.o.columns - vim.api.nvim_strwidth(text)) / 2))
  return indent .. text
end

function utils.right_align(text)
  local indent = string.rep(" ", math.floor((vim.o.columns - vim.api.nvim_strwidth(text)) / 7) * 5)
  return indent .. text
end

function utils.string_info(s)
  local lines = {}
  local max_line_len = 0
  for line in string.gmatch(s, "([^\n]*)\n?") do
    if line ~= "" then
      table.insert(lines, line)
    end
    max_line_len = math.max(max_line_len, string.len(line))
  end
  return #lines, lines, max_line_len
end

function utils.element_align(tbl)
  local lens = {}
  vim.tbl_map(function(k)
    table.insert(lens, vim.api.nvim_strwidth(k))
  end, tbl)
  table.sort(lens)
  local max = lens[#lens]
  local res = {}
  for _, item in pairs(tbl) do
    local len = vim.api.nvim_strwidth(item)
    local times = math.floor((max - len) / vim.api.nvim_strwidth(" "))
    item = item .. (" "):rep(times)
    table.insert(res, item)
  end
  return res
end

function utils.disable_move_key(bufnr, keys)
  vim.tbl_map(function(k)
    vim.keymap.set("n", k, "<Nop>", { buffer = bufnr })
  end, keys)
end

--- generate an empty table by length
function utils.generate_empty_table(length)
  local empty_tbl = {}
  if length == 0 then
    return empty_tbl
  end

  for _ = 1, length do
    table.insert(empty_tbl, "")
  end
  return empty_tbl
end

function utils.generate_truncateline(cells)
  local char = "┉"
  return char:rep(math.floor(cells / vim.api.nvim_strwidth(char)))
end

function utils.buf_is_empty(bufnr)
  bufnr = bufnr or 0
  return vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_buf_get_lines(0, 0, -1, false)[1] == ""
end

function utils.path_exists(p)
  local stat = vim.loop.fs_stat(p)
  return stat ~= nil
end

function utils.create_path(p)
  if utils.path_exists(p) then
    return true
  end
  local ok, err = uv.fs_mkdir(p, 511)
  if not ok and err ~= "EEXIST" then
    print("create path failed: " .. err)
    return false
  end
  return true
end
return utils
