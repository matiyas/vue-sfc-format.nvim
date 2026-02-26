vim.opt.rtp:append(".")

vim.bo = vim.bo or setmetatable({}, {
  __index = function()
    return {}
  end,
})

vim.fn = vim.fn or {}
vim.fn.filereadable = vim.fn.filereadable or function()
  return 0
end
vim.fn.isdirectory = vim.fn.isdirectory or function()
  return 0
end
vim.fn.getcwd = vim.fn.getcwd or function()
  return "/tmp"
end
vim.fn.stdpath = vim.fn.stdpath or function()
  return "/tmp"
end

vim.json = vim.json or {}
vim.json.decode = vim.json.decode or function(str)
  return loadstring("return " .. str)()
end
