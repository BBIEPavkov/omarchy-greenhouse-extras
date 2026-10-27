-- Greenhouse extras: leaf green cursor while the Greenhouse theme is active.
-- Installed by omarchy-greenhouse-extras/install.sh.

local theme_file = io.open(os.getenv("HOME") .. "/.local/state/omarchy/current/theme.name")
local theme = theme_file and theme_file:read("l") or ""
if theme_file then theme_file:close() end

if theme == "greenhouse" then
  hl.env("XCURSOR_THEME", "greenhouse-leaf-cursors")
  hl.env("HYPRCURSOR_THEME", "greenhouse-leaf-cursors")
end
