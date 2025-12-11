vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move Selected Line(s) Down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move Selected Line(s) Up' })

vim.keymap.set('n', 'gJ', 'mzJ`z', { desc = 'Join Lines' })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll Down' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll Up' })
vim.keymap.set('n', '<PageDown>', '<C-d>zz', { desc = 'Scroll Down' })
vim.keymap.set('n', '<PageUp>', '<C-u>zz', { desc = 'Scroll Up' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next Search Result' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous Search Result' })

vim.keymap.set('x', '<leader>p', [["_dP]], { desc = '[P]aste (Keep Clipboard)' })
vim.keymap.set('v', '<leader>d', [["_d]], { desc = '[D]elete (Keep Clipboard)' })

vim.keymap.set('n', 'Q', '<nop>', { desc = 'Disable Ex Mode' })
vim.keymap.set('n', '<leader>bf', vim.lsp.buf.format, { desc = '[B]uffer [F]ormat' })

vim.keymap.set('n', '<C-f>', '<cmd>cclose<CR>')
vim.keymap.set('n', '<C-k>', '<cmd>cnext<CR>zz')
vim.keymap.set('n', '<C-j>', '<cmd>cprev<CR>zz')
vim.keymap.set('n', '<leader>k', '<cmd>lnext<CR>zz', { desc = '[K] List Next Warning' })
vim.keymap.set('n', '<leader>j', '<cmd>lprev<CR>zz', { desc = '[J] List Previous Warning' })

vim.keymap.set(
  'n',
  '<leader>rs',
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = '[R]eplace Word Under Cur[S]or' }
)
vim.keymap.set('n', '<leader>fx', '<cmd>!chmod +x %<CR>', { silent = true, desc = '[F]ile e[X]ecutable' })
vim.keymap.set('n', '<leader>fd', '<cmd>!rm -rf %<CR>bd<CR>', { silent = true, desc = '[F]ile [D]elete' })

vim.keymap.set({ 'n', 'v', 't' }, '<C-q>', '<cmd>confirm qa<cr>', { desc = '[Q]uit All' })
vim.keymap.set('n', '<leader>bc', function()
  vim.cmd('set bufhidden=delete')
  local bufid = vim.api.nvim_get_current_buf()
  vim.cmd('confirm bp')
  if bufid == vim.api.nvim_get_current_buf() then
    vim.cmd('confirm enew')
  end
end, { desc = '[B]uffer [C]lose' })
vim.keymap.set('n', '<leader>bn', '<cmd>confirm enew<cr>', { desc = '[B]uffer [N]ew' })

vim.keymap.set('n', '<leader>tn', '<cmd>terminal<cr>', { desc = '[T]erminal [N]ew' })

vim.keymap.set('n', '<leader>gs', '<cmd>Telescope git_status<cr>', { desc = '[G]it [S]tatus' })
vim.keymap.set('n', '<leader>gb', '<cmd>Telescope git_branches<cr>', { desc = '[G]it [B]ranches' })
vim.keymap.set('n', '<leader>gc', '<cmd>Telescope git_commits<cr>', { desc = '[G]it [C]ommits' })
vim.keymap.set('n', '<leader>gm', package.loaded.gitsigns.blame_line, { desc = '[G]it [B]lame Line' })
vim.keymap.set('n', '<leader>gd', '<cmd>Git difftool<cr>', { desc = '[G]it [D]iff All Changes (Ctrl+j/k)' })
vim.keymap.set('n', '<leader>gD', '<cmd>Gvdiffsplit<cr>', { desc = '[G]it [D]iff Current File' })

vim.keymap.set('n', '<Tab>', '<cmd>bn<CR>', { desc = 'Next Buffer' })
vim.keymap.set('n', '<S-Tab>', '<cmd>bp<CR>', { desc = 'Previous Buffer' })

vim.keymap.set('n', '<leader>ac', function()
  require('snacks').terminal.toggle('claude', {
    win = {
      position = 'float',
      width = 0.85,
      height = 0.85,
      border = 'rounded',
    },
  })
end, { desc = '[A]I [C]laude' })

vim.keymap.set('n', '<leader>gl', function()
  require('snacks').terminal.toggle('lazygit', {
    win = {
      position = 'float',
      width = 0.85,
      height = 0.85,
      border = 'rounded',
    },
  })
end, { desc = '[G]it [L]azyGit' })
