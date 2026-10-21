#!/bin/sh
# Claude Code SessionStart hook -- managed by the nvim config (see
# lua/drdrak3/claude.lua; installed into ~/.claude/settings.json on nvim startup).
#
# Phones the Claude session id home to the running nvim so it can show each
# terminal's conversation title on its tab. Fires on startup / resume / clear.
#
# Only acts for Claude terminals launched by <leader>ac (which sets
# CLAUDE_NVIM_SLOT) inside an nvim :terminal ($NVIM set). Always exits 0 so it can
# never block or fail Claude startup. NOTE: CLAUDE_CODE_CHILD_SESSION is NOT a
# usable guard -- Claude sets it to 1 on every hook subprocess, so it's always 1.

[ -n "$NVIM" ] || exit 0
[ -n "$CLAUDE_NVIM_SLOT" ] || exit 0

payload=$(cat)
# Extract the session id (a UUID: hex + dashes) without a hard dependency on jq.
sid=$(printf '%s' "$payload" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([0-9a-fA-F-]*\)".*/\1/p' | head -n1)
[ -n "$sid" ] || exit 0

# Use the absolute nvim path injected at terminal spawn; fall back to PATH.
nvim_bin="${CLAUDE_NVIM_BIN:-nvim}"

# slot and sid are digits / hex+dashes only, so they are safe to interpolate.
"$nvim_bin" --server "$NVIM" --remote-expr "v:lua.__claude_session_hook('${CLAUDE_NVIM_SLOT}', '${sid}')" >/dev/null 2>&1 || true
exit 0
