return {
  'charludo/projectmgr.nvim',
  config = function()
    require('projectmgr').setup {
      reopen = false, -- a bare `nvim` opens the picker instead (lua/drdrak3/project.lua)
      session = { enabled = false },
    }
    vim.keymap.set('n', '<leader>op', '<cmd>ProjectMgr<cr>', { desc = '[O]pen [P]roject' })
  end,
}
