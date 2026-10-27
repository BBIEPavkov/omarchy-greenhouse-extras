#!/bin/bash

# Installs the Greenhouse extras. Asks before each piece; run it again any
# time to add pieces you skipped. Undo with uninstall.sh.

set -euo pipefail

EXTRAS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
HYPR_CONFIG="$HOME/.config/hypr/hyprland.lua"
SCREENSAVER="$HOME/.config/omarchy/branding/screensaver.txt"
CURSOR_THEME="greenhouse-leaf-cursors"

ask() {
  gum confirm "$1"
}

copy_plugins() {
  local id
  mkdir -p "$PLUGINS_DIR"
  for id in "$@"; do
    if [[ -e $PLUGINS_DIR/$id || -L $PLUGINS_DIR/$id ]]; then
      echo "$id is already installed"
      continue
    fi
    cp -r "$EXTRAS/plugins/$id" "$PLUGINS_DIR/$id"
  done
}

if ask "Install the Greenhouse lock screen? (hanging pothos vines, leaf password dots, a leaf burst on unlock)"; then
  copy_plugins emilypavkov.greenhouse-lock
fi

if ask "Install the leaf bar? (serif clock, a leaf on the current workspace, leaf volume and brightness popups, a leaf on each notification)"; then
  copy_plugins emilypavkov.greenhouse-clock emilypavkov.greenhouse-workspaces emilypavkov.greenhouse-osd emilypavkov.greenhouse-notifications
fi

if ask "Install the leaf green cursor?"; then
  mkdir -p "$HOME/.local/share/icons"
  rm -rf "$HOME/.local/share/icons/$CURSOR_THEME"
  cp -r "$EXTRAS/cursors/$CURSOR_THEME" "$HOME/.local/share/icons/"
  cp "$EXTRAS/hypr/greenhouse_cursor.lua" "$HOME/.config/hypr/greenhouse_cursor.lua"
  grep -qxF 'require("hypr.greenhouse_cursor")' "$HYPR_CONFIG" || printf '\nrequire("hypr.greenhouse_cursor")\n' >>"$HYPR_CONFIG"
  hyprctl reload >/dev/null
  hyprctl configerrors
fi

if ask "Install the leaf terminal prompt? (replaces ~/.config/starship.toml; your current one is backed up)"; then
  if [[ -f $HOME/.config/starship.toml ]]; then
    cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak.$(date +%s)"
  fi
  cp "$EXTRAS/starship/starship.toml" "$HOME/.config/starship.toml"
fi

if ask "Use a monstera leaf for the screensaver? (your current one is backed up)"; then
  [[ -f $SCREENSAVER ]] && cp "$SCREENSAVER" "$SCREENSAVER.bak.$(date +%s)"
  omarchy-transcode-ascii "$EXTRAS/screensaver/monstera.png" "$SCREENSAVER"
fi

# The extras only show while the Greenhouse theme is active; this hook turns
# them on and off when the theme changes.
omarchy-hook-install theme-set "$EXTRAS/hooks/greenhouse-extras"
omarchy-shell shell rescanPlugins >/dev/null
sleep 1
"$EXTRAS/hooks/greenhouse-extras" "$(omarchy-theme-current | tr '[:upper:] ' '[:lower:]-')"

echo "Done. The extras turn on whenever the Greenhouse theme is set (omarchy theme set greenhouse)."
