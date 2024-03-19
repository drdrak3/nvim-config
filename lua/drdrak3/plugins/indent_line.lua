return {
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    config = function()
      require('ibl').setup {
        indent = {
          char = '│',
          highlight = 'IndentBlanklineChar',
        },
        scope = {
          enabled = false,
        },
      }
    end,
  },
}
