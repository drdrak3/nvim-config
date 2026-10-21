return {
  -- Set lualine as statusline
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  -- See `:help lualine.txt`
  config = function()
    local function is_term() return vim.bo.buftype == 'terminal' end

    -- Terminals show what's running instead of their term://cwd//pid:cmd name:
    -- the conversation title for Claude, else the command (e.g. "zsh").
    local function term_name()
      if vim.bo.filetype == 'claude' then
        return '󰚩 ' .. require('drdrak3.claude').display_name(vim.api.nvim_get_current_buf())
      end
      local cmd = vim.api.nvim_buf_get_name(0):match('^term://.-//%d+:(.*)$') or ''
      return vim.fn.fnamemodify(vim.split(cmd, ' ')[1] or '', ':t')
    end

    require('lualine').setup {
      options = {
        theme = 'auto',
        icons_enabled = false,
        component_separators = '|',
        section_separators = '',
      },
      sections = {
        lualine_a = {
          { 'mode' },
        },
        lualine_b = {
          { 'filename', file_status = true, path = 1, cond = function() return not is_term() end },
          { term_name, cond = is_term },
          function() return require('drdrak3.project').name() end,
          'branch',
        },
        lualine_c = { { 'fileformat', cond = function() return not is_term() end } },
        lualine_x = {},
        lualine_y = { 'filetype', 'progress' },
        lualine_z = {
          { 'location' },
        },
      },
      inactive_sections = {
        lualine_a = { 'filename' },
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = { 'location' },
      },
      tabline = {},
      extensions = { 'nvim-tree' },
    }
  end,
}
