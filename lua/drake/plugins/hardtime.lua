return {
  'm4xshen/hardtime.nvim',
  dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim' },
  opts = {},
  config = function()
    vim.keymap.set("n", "<leader>ph", "<cmd>Hardtime toggle<cr>", {})
    require('hardtime').setup()
  end
}
