local wezterm = require 'wezterm';
local font_size = 10;

if os.getenv("XDG_SESSION_TYPE") == "wayland" then
  -- Tweak for Wayland sessions
  font_size = font_size - 1
end

return {
  audible_bell = "Disabled",
  color_scheme = "Material (base16)",
  colors = {
    cursor_bg = '#aaff00',
    cursor_fg = 'black',
  },
  font = wezterm.font_with_fallback({
    {
      family = "JetBrains Mono",
      -- weight = "Medium",
      harfbuzz_features = {"calt=0", "clig=0", "liga=0"}, -- disable ligature feature
    },
    "Hiragino Sans",
    "Noto Sans Mono CJK JP", -- fc-list | rg Noto | rg Mono | rg JP
  }),
  font_size = font_size,
  freetype_load_target = "Light",
  freetype_render_target = "HorizontalLcd",
  initial_cols = 160,
  initial_rows = 48,
  tab_bar_at_bottom = true,
  use_ime = true,
  window_frame = {
    font_size = font_size,
  },
  -- window_padding = {
  --   top = 5,
  --   bottom = 5,
  --   left = 5,
  --   right = 5,
  -- },
}
