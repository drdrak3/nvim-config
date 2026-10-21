-- Claude terminals in nvim, with conversation titles on their bufferline tabs.
--
-- Each Claude terminal is spawned with a CLAUDE_NVIM_SLOT env. A SessionStart hook
-- (scripts/claude_session_hook.sh|ps1, self-installed into ~/.claude/settings.json)
-- phones the live session id home per slot, which lets us find the conversation's
-- transcript and read its title. It re-fires on /resume and /clear, so the tab
-- follows whichever conversation the terminal is currently in.

local M = {}

--- Slots currently held by open Claude terminals.
local function open_slots()
  local s = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.bo[b].filetype == 'claude' then
      local slot = vim.b[b].claude_slot
      if slot ~= nil then s[tostring(slot)] = true end
    end
  end
  return s
end

--- Open Claude terminal buffer holding `slot`, or nil.
local function buf_for_slot(slot)
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.bo[b].filetype == 'claude'
      and tostring(vim.b[b].claude_slot) == tostring(slot) then
      return b
    end
  end
end

-- Tab titles: Claude Code appends `custom-title` (/rename) and `ai-title` entries
-- to the session transcript (~/.claude/projects/<cwd>/<sid>.jsonl), re-appending
-- them as the conversation grows, so the newest copy sits near the end. We read
-- the tail (cached by size+mtime) and expose it as b:claude_title for bufferline.

local TAIL_BYTES = 512 * 1024
local FULL_SCAN_MAX = 4 * 1024 * 1024
local transcript_paths = {} -- sid -> path
local title_cache = {} -- path -> { size, mtime, title }

local function transcript_path(sid)
  local p = transcript_paths[sid]
  if p and vim.uv.fs_stat(p) then return p end
  local root = vim.env.CLAUDE_CONFIG_DIR or vim.fn.expand('~/.claude')
  p = vim.fn.glob(root .. '/projects/*/' .. sid .. '.jsonl', true, true)[1]
  transcript_paths[sid] = p
  return p
end

--- Newest custom title (else AI title) found in `text`, or nil.
local function scan_titles(text)
  local custom, ai
  for line in text:gmatch('[^\n]+') do
    if line:find('"type":"custom-title"', 1, true) or line:find('"type":"ai-title"', 1, true) then
      local ok, e = pcall(vim.json.decode, line)
      if ok and type(e) == 'table' then
        if e.type == 'custom-title' and type(e.customTitle) == 'string' and e.customTitle ~= '' then
          custom = e.customTitle
        elseif e.type == 'ai-title' and type(e.aiTitle) == 'string' and e.aiTitle ~= '' then
          ai = e.aiTitle
        end
      end
    end
  end
  return custom or ai
end

local function read_title(path)
  local st = vim.uv.fs_stat(path)
  if not st then return nil end
  local c = title_cache[path]
  if c and c.size == st.size and c.mtime == st.mtime.sec then return c.title end
  local f = io.open(path, 'rb')
  if not f then return nil end
  local title
  if st.size > TAIL_BYTES then
    f:seek('set', st.size - TAIL_BYTES)
    local tail = f:read('*a') or ''
    title = scan_titles(tail:gsub('^[^\n]*\n', '', 1)) -- drop the partial first line
  end
  if not title and st.size <= FULL_SCAN_MAX then
    f:seek('set', 0)
    title = scan_titles(f:read('*a') or '')
  end
  f:close()
  -- Keep the previous title if a huge transcript's tail happens to lack one.
  title = title or (c and c.title)
  title_cache[path] = { size = st.size, mtime = st.mtime.sec, title = title }
  return title
end

--- Refresh b:claude_title on every Claude terminal; redraw the tabline on change.
function M.refresh_titles()
  local changed = false
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.bo[b].filetype == 'claude' then
      local sid = vim.b[b].claude_sid
      local path = sid and transcript_path(sid)
      local title = path and read_title(path) or nil
      if vim.b[b].claude_title ~= title then
        vim.b[b].claude_title = title
        changed = true
      end
    end
  end
  if changed then pcall(vim.cmd, 'redrawtabline') end
end

local function base_name(b)
  return vim.b[b].claude_title or 'Claude'
end

--- Tab label for a Claude terminal: its title, or "Claude" until one exists.
--- Bufferline dedupes identical labels by prefixing a dir from the buffer path
--- (giving "/bin/..." for term:// buffers), so on a collision with another Claude
--- terminal we disambiguate with the slot number instead.
function M.display_name(buf)
  local name = base_name(buf)
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= buf and vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted
      and vim.bo[b].filetype == 'claude' and base_name(b) == name then
      return name .. ' ' .. ((tonumber(vim.b[buf].claude_slot) or 0) + 1)
    end
  end
  return name
end

--- Lowest non-negative slot not used by an open terminal.
local function alloc_slot()
  local used = open_slots()
  local i = 0
  while used[tostring(i)] do i = i + 1 end
  return i
end

--- <leader>ac / project open: start a new Claude conversation in the current
--- window via `:enew` -- never a split. Its session id arrives shortly via the
--- SessionStart hook -> M.on_session.
function M.new_terminal()
  local slot = alloc_slot()
  vim.cmd('enew')
  -- Run through the shell so `claude` resolves via the shell's PATH. env extends
  -- (not replaces) the inherited environment. CLAUDE_NVIM_SLOT marks this as one
  -- of our terminals for the hook; CLAUDE_NVIM_BIN lets the hook find nvim by
  -- absolute path even when the terminal's PATH is minimal (e.g. GUI-launched nvim).
  local shell = (vim.o.shell ~= '' and vim.o.shell) or (vim.env.SHELL or '/bin/sh')
  local flag = (vim.o.shellcmdflag ~= '' and vim.o.shellcmdflag) or '-c'
  pcall(vim.fn.jobstart, { shell, flag, 'claude' }, {
    term = true,
    env = {
      CLAUDE_NVIM_SLOT = tostring(slot),
      CLAUDE_NVIM_BIN = vim.v.progpath,
    },
  })
  vim.bo.filetype = 'claude'
  vim.b.claude_slot = slot
  vim.cmd('startinsert')
end

--- Hook handler (invoked from the SessionStart script via --remote-expr): tag the
--- slot's terminal with its current session id so its title can be looked up.
function M.on_session(slot, sid)
  sid = tostring(sid)
  if sid == '' then return end
  local b = buf_for_slot(tostring(slot))
  if b then
    vim.b[b].claude_sid = sid
    vim.schedule(M.refresh_titles)
  end
end

--- Idempotently ensure the SessionStart hook is registered in the user-global
--- ~/.claude/settings.json, pointing at the OS-appropriate script in this repo.
--- Preserves all existing settings; only adds our entry once.
local function ensure_hook_installed()
  local scripts = vim.fn.stdpath('config') .. '/scripts/'
  local command
  if vim.fn.has('win32') == 1 then
    command = 'powershell -NoProfile -ExecutionPolicy Bypass -File "' .. scripts .. 'claude_session_hook.ps1"'
  else
    command = 'sh ' .. vim.fn.shellescape(scripts .. 'claude_session_hook.sh')
  end

  local settings_path = vim.fn.expand('~/.claude/settings.json')
  local settings = {}
  if vim.fn.filereadable(settings_path) == 1 then
    local ok, lines = pcall(vim.fn.readfile, settings_path)
    if ok and lines and lines[1] then
      local ok2, t = pcall(vim.json.decode, table.concat(lines, '\n'))
      if ok2 and type(t) == 'table' then settings = t end
    end
  end

  settings.hooks = settings.hooks or {}
  local groups = settings.hooks.SessionStart or {}

  -- Already installed? (match our script path, so path changes across machines
  -- still self-heal by adding the correct one.)
  local marker = vim.fn.has('win32') == 1 and 'claude_session_hook.ps1' or 'claude_session_hook.sh'
  for _, group in ipairs(groups) do
    if type(group) == 'table' and type(group.hooks) == 'table' then
      for _, h in ipairs(group.hooks) do
        if type(h) == 'table' and type(h.command) == 'string' and h.command:find(marker, 1, true) then
          return -- present; nothing to do
        end
      end
    end
  end

  table.insert(groups, { hooks = { { type = 'command', command = command } } })
  settings.hooks.SessionStart = groups

  pcall(vim.fn.mkdir, vim.fn.expand('~/.claude'), 'p')
  local ok = pcall(vim.fn.writefile, { vim.json.encode(settings) }, settings_path)
  if not ok then
    vim.schedule(function()
      vim.notify('Could not write ~/.claude/settings.json to install the Claude session hook', vim.log.levels.WARN)
    end)
  end
end

function M.setup()
  -- Global entry point the hook calls via `nvim --server $NVIM --remote-expr`.
  _G.__claude_session_hook = function(slot, sid)
    M.on_session(slot, sid)
    return 'ok'
  end
  pcall(ensure_hook_installed)

  -- Titles appear/change while Claude runs (first reply, /rename), with no event
  -- to hook, so poll. Cheap: one stat per Claude buffer unless the file changed.
  local timer = vim.uv.new_timer()
  timer:start(2000, 3000, vim.schedule_wrap(function()
    pcall(M.refresh_titles)
  end))
end

return M
