return {
  'Everblush/nvim',
  priority = 100,
  config = function()
    require('everblush').setup {
      transparent_background = true,
    }
    vim.cmd.colorscheme 'everblush'
  end,
}
