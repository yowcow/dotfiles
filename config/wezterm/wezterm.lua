local wezterm = require 'wezterm';
local font_size = 11.0;

if os.getenv("GDK_DPI_SCALE") ~= nil then
  -- Tweak for HiDPI X Window System
  font_size = math.floor(os.getenv("GDK_DPI_SCALE") * font_size) * 1.0 - 1.0;
elseif os.getenv("XDG_SESSION_TYPE") == "wayland" then
  -- Tweak for Wayland sessions
  font_size = font_size - 2.0
end

return {
  audible_bell = "Disabled",
  color_scheme = "Molokai",
  font = wezterm.font_with_fallback({
    {
      family = "JetBrains Mono",
      weight = "Medium",
      harfbuzz_features = {"calt=0", "clig=0", "liga=0"}, -- disable ligature feature
    },
    "Hiragino Sans",
    "Noto Sans Mono CJK JP", -- fc-list | rg Noto | rg Mono | rg JP
  }),
  font_size = font_size,
  --freetype_load_target = "HorizontalLcd",
  initial_cols = 160,
  initial_rows = 48,
  tab_bar_at_bottom = true,
  use_ime = true,
  window_frame = {
    font_size = font_size,
  },
  window_padding = {
    top = 5,
    bottom = 5,
    left = 5,
    right = 5,
  },
}
