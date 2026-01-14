return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Continue',
    },
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>dB',
      function()
        require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
      end,
      desc = 'Debug: Set Breakpoint',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        if require('dap').session() then
          require('dapui').toggle()
        else
          vim.notify('No active debug session', vim.log.levels.WARN)
        end
      end,
      desc = 'Debug: Toggle UI',
    },
    -- Terminate session
    {
      '<leader>dt',
      function()
        require('dap').terminate()
        require('dapui').close()
      end,
      desc = 'Debug: Terminate Session',
    },
    -- Panel navigation keymaps (focus existing panels by filetype)
    {
      '<leader>ds',
      function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'dapui_scopes' then
            vim.api.nvim_set_current_win(win)
            return
          end
        end
        vim.notify('Scopes panel not open', vim.log.levels.WARN)
      end,
      desc = 'Debug: Focus Scopes',
    },
    {
      '<leader>dp',
      function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'dapui_breakpoints' then
            vim.api.nvim_set_current_win(win)
            return
          end
        end
        vim.notify('Breakpoints panel not open', vim.log.levels.WARN)
      end,
      desc = 'Debug: Focus Breakpoints',
    },
    {
      '<leader>dk',
      function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'dapui_stacks' then
            vim.api.nvim_set_current_win(win)
            return
          end
        end
        vim.notify('Stacks panel not open', vim.log.levels.WARN)
      end,
      desc = 'Debug: Focus Stacks',
    },
    {
      '<leader>dw',
      function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'dapui_watches' then
            vim.api.nvim_set_current_win(win)
            return
          end
        end
        vim.notify('Watches panel not open', vim.log.levels.WARN)
      end,
      desc = 'Debug: Focus Watches',
    },
    {
      '<leader>dr',
      function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'dapui_repl' then
            vim.api.nvim_set_current_win(win)
            return
          end
        end
        vim.notify('REPL panel not open', vim.log.levels.WARN)
      end,
      desc = 'Debug: Focus REPL',
    },
    {
      '<leader>dc',
      function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'dapui_console' then
            vim.api.nvim_set_current_win(win)
            return
          end
        end
        vim.notify('Console panel not open', vim.log.levels.WARN)
      end,
      desc = 'Debug: Focus Console',
    },
    -- Evaluate custom expression with input
    {
      '<leader>dE',
      function()
        require('dapui').eval(vim.fn.input('Expression: '))
      end,
      desc = 'Debug: Evaluate Custom Expression',
    },
  },
  config = function()
    local dap = require('dap')
    local dapui = require('dapui')

    require('mason-nvim-dap').setup({
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'php-debug-adapter',
      },
    })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup({
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
      layouts = {
        {
          elements = {
            { id = 'scopes', size = 0.25 },
            { id = 'breakpoints', size = 0.25 },
            { id = 'stacks', size = 0.25 },
            { id = 'watches', size = 0.25 },
          },
          size = 40,
          position = 'left',
        },
        {
          elements = {
            { id = 'repl', size = 0.5 },
            { id = 'console', size = 0.5 },
          },
          size = 10,
          position = 'bottom',
        },
      },
    })

    -- Breakpoint icons and highlights
    vim.api.nvim_set_hl(0, 'DapBreakpoint', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStopped', { fg = '#98c379', bg = '#2e4b2e' })
    vim.api.nvim_set_hl(0, 'DapStoppedLine', { bg = '#2e4b2e' })

    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapBreakpointRejected', { text = '○', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapLogPoint', { text = '◆', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    vim.fn.sign_define('DapStopped', { text = '→', texthl = 'DapStopped', linehl = 'DapStoppedLine', numhl = '' })

    -- Stack frame sign for non-current frames (shown in other files in the call stack)
    vim.api.nvim_set_hl(0, 'DapStackFrame', { fg = '#61afef', bg = '#2b3e50' })
    vim.api.nvim_set_hl(0, 'DapStackFrameLine', { bg = '#2b3e50' })
    vim.fn.sign_define('DapStackFrame', { text = '⬆', texthl = 'DapStackFrame', linehl = 'DapStackFrameLine', numhl = '' })

    -- Track stack frame signs
    local stack_frame_signs = {}

    local function clear_stack_frame_signs()
      for _, sign_id in ipairs(stack_frame_signs) do
        vim.fn.sign_unplace('dap_stack_frames', { id = sign_id })
      end
      stack_frame_signs = {}
    end

    local function update_stack_frame_signs()
      clear_stack_frame_signs()

      local session = dap.session()
      if not session then
        return
      end

      local current_thread = session.stopped_thread_id
      if not current_thread then
        return
      end

      -- Get stack trace for current thread
      session:request('stackTrace', { threadId = current_thread }, function(err, response)
        if err or not response or not response.stackFrames then
          return
        end

        local frames = response.stackFrames
        -- Skip the first frame (current position) - that one already has DapStopped sign
        for i = 2, #frames do
          local frame = frames[i]
          if frame.source and frame.source.path then
            local path = frame.source.path
            -- Handle path mappings for Docker/remote debugging
            for remote, local_path in pairs(dap.configurations.php[1].pathMappings or {}) do
              if path:find(remote, 1, true) == 1 then
                path = path:gsub('^' .. vim.pesc(remote), local_path)
                break
              end
            end

            local bufnr = vim.fn.bufnr(path)
            if bufnr == -1 then
              -- Try to load the buffer if it exists on disk
              if vim.fn.filereadable(path) == 1 then
                bufnr = vim.fn.bufadd(path)
              end
            end

            if bufnr ~= -1 then
              local sign_id = vim.fn.sign_place(0, 'dap_stack_frames', 'DapStackFrame', bufnr, {
                lnum = frame.line,
                priority = 5, -- Lower priority than DapStopped (default 10)
              })
              table.insert(stack_frame_signs, sign_id)
            end
          end
        end
      end)
    end

    -- Update stack frame signs when debugger stops
    dap.listeners.after.event_stopped['stack_frame_signs'] = function()
      -- Small delay to ensure thread info is available
      vim.defer_fn(update_stack_frame_signs, 100)
    end

    -- Clear signs when session ends
    dap.listeners.before.event_terminated['stack_frame_signs'] = clear_stack_frame_signs
    dap.listeners.before.event_exited['stack_frame_signs'] = clear_stack_frame_signs
    dap.listeners.before.disconnect['stack_frame_signs'] = clear_stack_frame_signs

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Buffer-local keymaps for dapui elements (copy value with 'yv')
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'dapui_scopes', 'dapui_watches' },
      callback = function()
        -- yv to copy the value of the variable under cursor
        vim.keymap.set('n', 'yv', function()
          local line = vim.api.nvim_get_current_line()
          -- Extract value after the equals sign or colon
          local value = line:match('=%s*(.+)$') or line:match(':%s*(.+)$')
          if value then
            value = vim.trim(value)
            vim.fn.setreg('+', value)
            vim.fn.setreg('"', value)
            vim.notify('Copied: ' .. value, vim.log.levels.INFO)
          else
            vim.notify('No value found on this line', vim.log.levels.WARN)
          end
        end, { buffer = true, desc = 'Debug: Copy variable value' })
      end,
    })

    -- Install golang specific config
    require('dap-go').setup({
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has('win32') == 0,
      },
    })

    -- PHP/Xdebug configuration for Docker
    dap.adapters.php = {
      type = 'executable',
      command = 'node',
      args = { vim.fn.stdpath('data') .. '/mason/packages/php-debug-adapter/extension/out/phpDebug.js' },
    }

    dap.configurations.php = {
      {
        type = 'php',
        request = 'launch',
        name = 'Listen for Xdebug (Rosterfy2 Docker)',
        port = 9003,
        pathMappings = {
          ['/var/www'] = vim.fn.expand('~/Projects/Rosterfy2'),
        },
      },
    }
  end,
}
