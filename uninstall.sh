#!/bin/bash

# Removes everything install.sh added and brings back Omarchy's built-ins.
# Your screensaver and starship.toml backups are left in place to restore by hand.

set -euo pipefail

HYPR_CONFIG="$HOME/.config/hypr/hyprland.lua"
CURSOR_THEME="greenhouse-leaf-cursors"

for id in emilypavkov.greenhouse-lock emilypavkov.greenhouse-workspaces emilypavkov.greenhouse-osd emilypavkov.greenhouse-clock emilypavkov.greenhouse-notifications; do
  # Removing a clone switches back to the built-in it replaced.
  if [[ -e $HOME/.config/omarchy/plugins/$id ]]; then
    omarchy-plugin-remove "$id" --yes
  fi
done

rm -f "$HOME/.config/omarchy/hooks/theme-set.d/greenhouse-extras"

sed -i '/^require("hypr\.greenhouse_cursor")$/d' "$HYPR_CONFIG"
rm -f "$HOME/.config/hypr/greenhouse_cursor.lua"
if [[ $(gsettings get org.gnome.desktop.interface cursor-theme) == "'$CURSOR_THEME'" ]]; then
  gsettings reset org.gnome.desktop.interface cursor-theme
fi
rm -rf "$HOME/.local/share/icons/$CURSOR_THEME"

hyprctl reload >/dev/null
hyprctl configerrors

echo "Done. Run 'omarchy branding screensaver reset' to bring back Omarchy's screensaver."
