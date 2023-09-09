return {
  'charludo/projectmgr.nvim',
  config = function()
    require('projectmgr').setup({
      reopen = true,
      session = { enabled = false }
    })
    vim.keymap.set('n', '<leader>op', '<cmd>ProjectMgr<cr>', { desc = '[O]pen [P]roject' })
  end
}
