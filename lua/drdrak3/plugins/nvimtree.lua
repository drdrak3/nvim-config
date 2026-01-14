-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  'nvim-tree/nvim-tree.lua',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    vim.opt.termguicolors = true

    require('nvim-tree').setup({
      filters = {
        dotfiles = false,
        exclude = { vim.fn.stdpath('config') .. '/lua/custom' },
      },
      disable_netrw = true,
      hijack_netrw = true,
      hijack_cursor = true,
      hijack_unnamed_buffer_when_opening = false,
      sync_root_with_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = false,
      },
      view = {
        adaptive_size = false,
        side = 'left',
        width = 35,
        preserve_window_proportions = true,
      },
      git = {
        enable = false,
        ignore = true,
      },
      filesystem_watchers = {
        enable = true,
      },
      actions = {
        open_file = {
          resize_window = true,
        },
      },
      renderer = {
        root_folder_label = false,
        highlight_git = false,
        highlight_opened_files = 'none',

        indent_markers = {
          enable = false,
        },

        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = false,
          },

          glyphs = {
            default = '󰈚',
            symlink = '',
            folder = {
              default = '',
              empty = '',
              empty_open = '',
              open = '',
              symlink = '',
              symlink_open = '',
              arrow_open = '',
              arrow_closed = '',
            },
            git = {
              unstaged = '✗',
              staged = '✓',
              unmerged = '',
              renamed = '➜',
              untracked = '★',
              deleted = '',
              ignored = '◌',
            },
          },
        },
      },
    })

    vim.keymap.set('n', '<leader>ft', '<cmd>NvimTreeToggle<cr>', { desc = '[F]ile [T]ree' })

    -- Prevent nvim-tree from being the only window open
    vim.api.nvim_create_autocmd('BufEnter', {
      nested = true,
      callback = function()
        local api = require('nvim-tree.api')
        if #vim.api.nvim_list_wins() == 1 and api.tree.is_tree_buf() then
          vim.defer_fn(function()
            api.tree.toggle({ find_file = true, focus = true })

            -- Find the most recently used listed buffer
            local bufs = vim.fn.getbufinfo({ buflisted = 1 })
            local current = vim.api.nvim_get_current_buf()

            -- Filter out current buffer and sort by lastused (most recent first)
            local valid_bufs = vim.tbl_filter(function(b)
              return b.bufnr ~= current and b.hidden == 0 or b.loaded == 1
            end, bufs)

            table.sort(valid_bufs, function(a, b)
              return (a.lastused or 0) > (b.lastused or 0)
            end)

            if #valid_bufs > 0 then
              vim.cmd('buffer ' .. valid_bufs[1].bufnr)
            else
              vim.cmd('enew')
            end

            api.tree.toggle({ find_file = true, focus = false })
          end, 0)
        end
      end,
    })
  end,
}
