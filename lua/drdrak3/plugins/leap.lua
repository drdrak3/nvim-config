return {
  url = 'https://codeberg.org/andyg/leap.nvim',
  dependencies = { 'tpope/vim-repeat' },
  config = function()
    vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap)')
    vim.keymap.set('n', 'S', '<Plug>(leap-from-window)')

    -- Enhanced f/t motions (replaces deprecated flit.nvim)
    local function ft(key_specific_args)
      require('leap').leap(
        vim.tbl_deep_extend('keep', key_specific_args, {
          inputlen = 1,
          inclusive = true,
          opts = {
            labels = '',
            safe_labels = vim.fn.mode(1):match('o') and '' or nil,
          },
        })
      )
    end

    local clever = require('leap.user').with_traversal_keys
    local clever_f, clever_t = clever('f', 'F'), clever('t', 'T')

    vim.keymap.set({ 'n', 'x', 'o' }, 'f', function() ft { opts = clever_f } end)
    vim.keymap.set({ 'n', 'x', 'o' }, 'F', function() ft { backward = true, opts = clever_f } end)
    vim.keymap.set({ 'n', 'x', 'o' }, 't', function() ft { offset = -1, opts = clever_t } end)
    vim.keymap.set({ 'n', 'x', 'o' }, 'T', function() ft { backward = true, offset = 1, opts = clever_t } end)
  end,
}
