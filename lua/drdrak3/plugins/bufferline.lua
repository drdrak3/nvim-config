return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = 'nvim-tree/nvim-web-devicons',
  config = function()
    vim.opt.termguicolors = true
    vim.api.nvim_set_hl(0, 'BufferlineClaudeIcon', { fg = '#cba6f7' })
    require('bufferline').setup {
      options = {
        -- Room for Claude session titles (default 18 truncates most of them).
        max_name_length = 40,
        name_formatter = function(buf)
          if vim.bo[buf.bufnr].filetype == 'claude' then
            return require('drdrak3.claude').display_name(buf.bufnr)
          end
        end,
        get_element_icon = function(element)
          if element.filetype == 'claude' then
            return '󰚩', 'BufferlineClaudeIcon'
          end
        end,
        offsets = {
          {
            filetype = 'NvimTree',
            text = ' ',
            text_align = 'center',
          },
        },
      },
    }
  end,
}
