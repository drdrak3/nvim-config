vim.api.nvim_set_hl(0, 'LineNr', { fg = '#555555' })

local function _set_float_highlights()
  local float_bg = '#11151a'
  local prompt_bg = '#1c2128'
  local selection_bg = '#2d333b'
  vim.api.nvim_set_hl(0, 'TelescopeNormal', { bg = float_bg })
  vim.api.nvim_set_hl(0, 'TelescopeResultsNormal', { bg = float_bg })
  vim.api.nvim_set_hl(0, 'TelescopePreviewNormal', { bg = float_bg })
  vim.api.nvim_set_hl(0, 'TelescopePromptNormal', { bg = prompt_bg })
  vim.api.nvim_set_hl(0, 'TelescopePromptPrefix', { bg = prompt_bg })
  vim.api.nvim_set_hl(0, 'TelescopeSelection', { bg = selection_bg })
  vim.api.nvim_set_hl(0, 'SnacksFloatBg', { bg = float_bg })
end

vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = _set_float_highlights,
})
_set_float_highlights()

vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  pattern = { '*' },
  command = [[%s/\s\+$//e]],
})

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.isfname:append '@-@'

vim.opt.updatetime = 50

vim.opt.colorcolumn = '120'

vim.opt.fillchars = { eob = ' ' }

require 'drdrak3/remap'
require('drdrak3.project').setup()
require('drdrak3.claude').setup()
