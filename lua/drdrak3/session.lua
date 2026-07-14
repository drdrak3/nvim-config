-- Branch-aware, SIGHUP-proof session restore.
--
-- See ~/Personal/session-resume-scope.md. This is Phase 1 ("base"): branch-keyed
-- file/layout restore via persistence.nvim, continuous save pinned to a cached
-- key, a prompted restore driven by both project-open and fs-watch branch-change
-- detection, and the close-terminals-before-wipe guard.
--
-- The Claude multi-conversation layer (Phase 2) is intentionally NOT here yet.
--
-- Key decisions implemented (letters map to the scope doc):
--   D5  persistence.nvim, branch = true (keyed by cwd + git branch)
--   D7  never save on exit; save continuously, always to the *cached* active key
--   D8  restore is prompted, triggered by a wrap of projectmgr's open_project
--   D18 all paths derived dynamically from cwd + branch (no repo names in config)
--   D19 force-close terminal/claude buffers before projectmgr's `bufdo bd` wipe
--   D20 branch-change detection via fs-watch on git HEAD, deferred to a focus/attention boundary
--   D21 prompt on both project-open and branch-change; keep-and-re-key on "No"
--   D22 saves pinned to the cached key + net-compare at the boundary => transient checkouts self-cancel

local uv = vim.uv or vim.loop

local M = {}

-- The pinned session key: the exact session-file path for the branch we consider
-- "active". Every save targets THIS, never a freshly re-detected HEAD (D7/D22).
M.active_key = nil
-- Suppress saves while a switch/wipe is in flight, so buffer teardown can't
-- clobber a good session with a half-empty one.
M.suspend_save = false
-- A branch change was detected by the fs-watch and is waiting for an attention
-- boundary before we act on it (D20).
M.pending = false
-- Whether the active key has held real file content since it was established.
-- Lets a deliberately-emptied branch be saved as empty (so a closed-to-empty
-- session stays empty on restore), while still protecting an existing on-disk
-- session from being clobbered by a transient/pre-restore empty state.
M.has_content = false

M.watcher = nil
local save_timer, head_timer

--- Session-file path for the *current* live cwd + HEAD (recomputed each call).
function M.current_key()
  local ok, path = pcall(function()
    return require('persistence').current()
  end)
  return ok and path or nil
end

--- Absolute path to the resolved git directory for the current cwd, or nil.
local function git_dir()
  local out = vim.fn.systemlist({ 'git', 'rev-parse', '--absolute-git-dir' })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == '' then
    return nil
  end
  return out[1]
end

--- True when at least one real, named file buffer is open. Guards against
--- clobbering a good session with an empty layout (e.g. mid-wipe).
local function has_file_buffer()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b)
      and vim.bo[b].buflisted
      and vim.bo[b].buftype == ''
      and vim.api.nvim_buf_get_name(b) ~= '' then
      return true
    end
  end
  return false
end

--- Write the session to the pinned key. Never re-detects the branch.
local function do_save()
  if not M.active_key then return end
  if has_file_buffer() then
    M.has_content = true
  elseif not M.has_content then
    -- Empty layout for a key that has never held content: don't clobber an
    -- existing on-disk session (protects startup / pre-restore states).
    return
  end
  -- Otherwise the empty layout is a deliberate close of a key that HAD content;
  -- record it so the emptied branch stays emptied on restore.
  pcall(vim.cmd, 'mks! ' .. vim.fn.fnameescape(M.active_key))
end

--- Immediate, unconditional save to the pinned key (used at switch boundaries).
function M.save_now()
  do_save()
end

--- Debounced save for the continuous-save autocmds (D7).
local function schedule_save()
  if M.suspend_save then return end
  save_timer = save_timer or uv.new_timer()
  save_timer:stop()
  save_timer:start(150, 0, function()
    vim.schedule(function()
      if not M.suspend_save then do_save() end
    end)
  end)
end

--- Source the pinned session file, if it exists on disk.
function M.restore()
  if M.active_key and vim.fn.filereadable(M.active_key) == 1 then
    pcall(vim.cmd, 'silent! source ' .. vim.fn.fnameescape(M.active_key))
  end
end

--- Force-close terminal and Claude buffers so projectmgr's `bufdo bd` (no bang)
--- won't error E948 and abort the wipe/restore (D19).
function M.close_term_buffers()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) then
      local bt = vim.bo[b].buftype
      local ft = vim.bo[b].filetype
      if bt == 'terminal' or ft == 'claude' then
        pcall(vim.api.nvim_buf_delete, b, { force = true })
      end
    end
  end
end

--- Wipe all listed buffers (terminals already closed). force=true is safe here
--- because callers write/confirm modified buffers first.
local function wipe_listed_buffers()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted then
      pcall(vim.api.nvim_buf_delete, b, { force = true })
    end
  end
end

--- Re-establish the fs-watch on the current repo's git HEAD (D20). Watches the
--- git directory (robust to git's atomic HEAD.lock -> HEAD rename) and filters
--- for the HEAD entry.
function M.rearm_watcher()
  if M.watcher then
    pcall(function() M.watcher:stop() end)
    pcall(function() M.watcher:close() end)
    M.watcher = nil
  end
  local gd = git_dir()
  if not gd then return end
  local w = uv.new_fs_event()
  local ok = pcall(function()
    w:start(gd, {}, function(err, filename, _events)
      if err then return end
      if filename and filename ~= 'HEAD' then return end
      vim.schedule(function() M.on_head_event() end)
    end)
  end)
  if ok then
    M.watcher = w
  else
    pcall(function() w:close() end)
  end
end

--- Debounce raw HEAD write events, then flag a pending change and try to act if
--- we're already at an attention boundary.
function M.on_head_event()
  head_timer = head_timer or uv.new_timer()
  head_timer:stop()
  head_timer:start(300, 0, function()
    vim.schedule(function()
      M.pending = true
      M.process_pending()
    end)
  end)
end

--- Act on a pending branch change, but only once we're back on a normal buffer
--- (not still inside lazygit / a Claude terminal / the projectmgr picker) so we
--- don't rearrange the editor under the user (D20). Net-compares current HEAD to
--- the pinned key, so A->B->A round-trips are a no-op (D22).
function M.process_pending()
  if not M.pending then return end
  local bt = vim.bo.buftype
  local ft = vim.bo.filetype
  if bt == 'terminal' or ft == 'claude' or ft == 'projectmgr' then
    return
  end
  local target = M.current_key()
  if not target then return end
  M.pending = false
  if target ~= M.active_key then
    M.on_branch_change(target)
  end
end

--- Handle a confirmed net branch change (D21): always force-save the outgoing
--- branch first; then prompt if the target has a saved session.
function M.on_branch_change(target)
  M.save_now() -- outgoing branch preserved under the (still-current) pinned key

  if vim.fn.filereadable(target) == 1 then
    local choice = vim.fn.confirm("Branch changed. Restore this branch's saved session?", '&Yes\n&No', 1)
    if choice == 1 then
      M.suspend_save = true
      pcall(vim.cmd, 'confirm wa') -- write modified buffers before wiping (no lost changes)
      M.close_term_buffers()
      wipe_listed_buffers()
      M.active_key = target
      M.restore()
      M.has_content = has_file_buffer()
      M.suspend_save = false
    else
      M.active_key = target -- keep current buffers, re-key to target
      M.has_content = has_file_buffer()
    end
  else
    M.active_key = target -- no saved session: silent keep + re-key
    M.has_content = has_file_buffer()
  end

  M.rearm_watcher()
end

--- Wrap projectmgr's open_project so every project open (picker + startup
--- reopen) force-saves the outgoing branch, closes terminals, runs the original
--- wipe/cd, then prompts to restore the target branch's session (D8/D19/D21).
function M.install_projectmgr_wrap()
  local ok, manage = pcall(require, 'projectmgr.manage')
  if not ok or manage.__drdrak3_wrapped then return end

  local orig = manage.open_project
  local function wrapper(...)
    M.save_now()
    M.suspend_save = true
    M.close_term_buffers()

    local ok2, err = pcall(orig, ...)
    if not ok2 then
      vim.schedule(function()
        vim.notify('projectmgr open_project failed: ' .. tostring(err), vim.log.levels.WARN)
      end)
    end

    M.rearm_watcher()
    local target = M.current_key()
    M.active_key = target

    if target and vim.fn.filereadable(target) == 1 then
      local choice = vim.fn.confirm("Restore this branch's saved session?", '&Yes\n&No', 1)
      if choice == 1 then
        M.restore()
      end
    end

    M.has_content = has_file_buffer()
    M.suspend_save = false
  end

  manage.open_project = wrapper
  manage.__drdrak3_wrapped = true

  -- The non-telescope window picker calls the top-level cached reference; patch
  -- it too so the wrap fires regardless of which picker is active.
  local ok3, top = pcall(require, 'projectmgr')
  if ok3 then top.open_project = wrapper end
end

function M.setup()
  pcall(function()
    require('persistence').setup({ branch = true, need = 1 })
    -- D7: never save on exit. Remove persistence's VimLeavePre autosave; we save
    -- continuously to the pinned key instead.
    require('persistence').stop()
  end)

  -- Save files + window layout only. Exclude terminals/options so a save with a
  -- Claude terminal open doesn't serialize a broken terminal (Phase 1).
  vim.opt.sessionoptions = { 'buffers', 'curdir', 'folds', 'tabpages', 'winsize', 'help' }

  local grp = vim.api.nvim_create_augroup('drdrak3-session', { clear = true })

  -- Continuous, SIGHUP-proof save (D7).
  vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufAdd', 'BufDelete', 'FocusLost' }, {
    group = grp,
    callback = schedule_save,
  })

  -- Attention boundaries for a deferred branch-change restore (D20).
  vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'WinEnter' }, {
    group = grp,
    callback = function()
      vim.schedule(function() M.process_pending() end)
    end,
  })

  M.install_projectmgr_wrap()

  -- Establish the initial context when launched into a repo without projectmgr's
  -- reopen firing (e.g. `nvim <file>`); reopen, when it runs, sets active_key via
  -- the wrap and this becomes a no-op except for re-arming the watcher.
  vim.api.nvim_create_autocmd('VimEnter', {
    group = grp,
    callback = function()
      vim.schedule(function()
        if not M.active_key and git_dir() then
          M.active_key = M.current_key()
          M.has_content = has_file_buffer()
        end
        M.rearm_watcher()
      end)
    end,
  })
end

return M
