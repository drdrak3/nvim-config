-- Project-first startup: a bare `nvim` opens the projectmgr picker, and opening a
-- project immediately starts a fresh Claude conversation in it.

local M = {}

-- Our own record of the last opened project. projectmgr's "current" flag can't be
-- used: its VimLeavePre shutdown clears it whenever nvim quits outside a project
-- (e.g. straight from the startup picker).
local last_project_path = vim.fn.stdpath('state') .. '/last_project'

local function read_last_project()
  local ok, lines = pcall(vim.fn.readfile, last_project_path)
  return ok and lines[1] or nil
end

-- Name of the project opened this session (nil until one is opened).
local current_project

--- Display name of the current project: the projectmgr name when one was opened,
--- else the working directory's basename (e.g. nvim started on a file).
function M.name()
  return current_project or vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
end

--- Force-close terminal and Claude buffers so projectmgr's `bufdo bd` (no bang)
--- doesn't error E948 on a running job and abort the project switch.
local function close_term_buffers()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) then
      if vim.bo[b].buftype == 'terminal' or vim.bo[b].filetype == 'claude' then
        pcall(vim.api.nvim_buf_delete, b, { force = true })
      end
    end
  end
end

--- Wrap projectmgr's open_project: clear terminals before its wipe/cd, then open
--- Claude in the new project.
local function install_projectmgr_wrap()
  local ok, manage = pcall(require, 'projectmgr.manage')
  if not ok or manage.__drdrak3_wrapped then return end

  local orig = manage.open_project
  local function wrapper(name)
    -- open_project is a no-op for an unknown name; don't touch anything then.
    if require('projectmgr.file_adapter').get_single_project(name) == nil then return end
    close_term_buffers()
    local ok2, err = pcall(orig, name)
    if not ok2 then
      vim.notify('projectmgr open_project failed: ' .. tostring(err), vim.log.levels.WARN)
      return
    end
    current_project = name
    pcall(vim.fn.writefile, { name }, last_project_path)
    -- Deferred so the picker window has fully closed before we enter the terminal.
    vim.schedule(function()
      require('drdrak3.claude').new_terminal()
    end)
  end

  manage.open_project = wrapper
  manage.__drdrak3_wrapped = true

  -- The non-telescope window picker calls the top-level cached reference; patch
  -- it too so the wrap fires regardless of which picker is active.
  local ok3, top = pcall(require, 'projectmgr')
  if ok3 then top.open_project = wrapper end
end

--- Make the telescope picker start with the last opened project highlighted.
--- projectmgr builds the picker in a local `show_telescope(opts)` that its
--- open_picker calls with no opts, so we pull it out as an upvalue to pass
--- telescope's default_selection_index.
local function install_picker_default()
  local ok, picker = pcall(require, 'projectmgr.telescope_picker')
  if not ok or picker.__drdrak3_wrapped then return end
  local name, show = debug.getupvalue(picker.open_picker, 1)
  if name ~= 'show_telescope' then return end

  picker.open_picker = function()
    local last = read_last_project()
    local index = last and vim.fn.index(require('projectmgr.file_adapter').get_projects(), last) or -1
    show(index >= 0 and { default_selection_index = index + 1 } or nil)
  end
  picker.__drdrak3_wrapped = true

  -- :ProjectMgr calls the top-level cached reference.
  local ok2, top = pcall(require, 'projectmgr')
  if ok2 and top.open_window then top.open_window = picker.open_picker end
end

function M.setup()
  install_projectmgr_wrap()
  install_picker_default()

  local grp = vim.api.nvim_create_augroup('drdrak3-project', { clear = true })
  local stdin = false
  vim.api.nvim_create_autocmd('StdinReadPre', {
    group = grp,
    callback = function() stdin = true end,
  })
  vim.api.nvim_create_autocmd('VimEnter', {
    group = grp,
    callback = function()
      if vim.fn.argc() > 0 or stdin then return end
      vim.schedule(function() vim.cmd('ProjectMgr') end)
    end,
  })
end

return M
