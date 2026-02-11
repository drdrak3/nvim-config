return {
  'Wansmer/treesj',
  keys = {
    { 'gS', '<cmd>TSJToggle<cr>', desc = 'Toggle split/join' },
  },
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  opts = {
    use_default_keymaps = false,
  },
}
