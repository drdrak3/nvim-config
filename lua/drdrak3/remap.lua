vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

vim.keymap.set('n', 'J', 'mzJ`z')
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', '<PageDown>', '<C-d>zz')
vim.keymap.set('n', '<PageUp>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- paste over visual selection while keeping existing clipboard
vim.keymap.set('x', '<leader>p', [["_dP]])
-- delete selection while keeping existing clipboard
vim.keymap.set('v', '<leader>d', [["_d]], { desc = '[D]elete (Keep Clipboard)' })

vim.keymap.set('n', 'Q', '<nop>')
vim.keymap.set('n', '<leader>bf', vim.lsp.buf.format, { desc = '[B]uffer [F]ormat' })

vim.keymap.set('n', '<C-k>', '<cmd>cnext<CR>zz')
vim.keymap.set('n', '<C-j>', '<cmd>cprev<CR>zz')
vim.keymap.set('n', '<leader>k', '<cmd>lnext<CR>zz', { desc = '[K] List Next Warning' })
vim.keymap.set('n', '<leader>j', '<cmd>lprev<CR>zz', { desc = '[J] List Previous Warning' })

vim.keymap.set('n', '<leader>rs', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = '[R]eplace Word Under Cur[S]or' })
vim.keymap.set('n', '<leader>fx', '<cmd>!chmod +x %<CR>', { silent = true, desc = '[F]ile e[X]ecutable' })

vim.keymap.set({ 'n', 'v', 't' }, '<C-q>', '<cmd>confirm qa<cr>', {})
vim.keymap.set('n', '<leader>bc', function()
  vim.cmd 'set bufhidden=delete'
  local bufid = vim.api.nvim_get_current_buf()
  vim.cmd 'confirm bp'
  if bufid == vim.api.nvim_get_current_buf() then
    vim.cmd 'confirm enew'
  end
end, { desc = '[B]uffer [C]lose' })

vim.keymap.set('n', '<leader>tn', '<cmd>terminal<cr>', { desc = '[T]erminal [N]ew' })

vim.keymap.set('n', '<leader>gs', '<cmd>Telescope git_status<cr>', { desc = '[G]it [S]tatus' })
vim.keymap.set('n', '<leader>gb', '<cmd>Telescope git_branches<cr>', { desc = '[G]it [B]ranches' })
vim.keymap.set('n', '<leader>gm', package.loaded.gitsigns.blame_line, { desc = '[G]it [B]lame Line' })

vim.keymap.set('n', '<Tab>', '<cmd>bn<CR>', { desc = 'Next Buffer' })
