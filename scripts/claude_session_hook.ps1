# Claude Code SessionStart hook (Windows variant) -- managed by the nvim config
# (see lua/drdrak3/claude.lua; installed into ~/.claude/settings.json on startup).
#
# Phones the Claude session id home to the running nvim so it can show each
# terminal's conversation title on its tab. No-op unless running inside a
# <leader>ac terminal ($env:NVIM and $env:CLAUDE_NVIM_SLOT set).
# Always exits 0 so it can never block or fail Claude startup.

if (-not $env:NVIM) { exit 0 }
# CLAUDE_CODE_CHILD_SESSION is NOT a usable guard (Claude sets it to 1 on every
# hook subprocess). Gate on CLAUDE_NVIM_SLOT, which only <leader>ac terminals set.
if (-not $env:CLAUDE_NVIM_SLOT) { exit 0 }

try {
  $payload = [Console]::In.ReadToEnd()
  $sid = ($payload | ConvertFrom-Json).session_id
} catch { exit 0 }
if (-not $sid) { exit 0 }

$slot = if ($env:CLAUDE_NVIM_SLOT) { $env:CLAUDE_NVIM_SLOT } else { '0' }
$nvimBin = if ($env:CLAUDE_NVIM_BIN) { $env:CLAUDE_NVIM_BIN } else { 'nvim' }

try {
  & $nvimBin --server $env:NVIM --remote-expr "v:lua.__claude_session_hook('$slot', '$sid')" *> $null
} catch { }
exit 0
