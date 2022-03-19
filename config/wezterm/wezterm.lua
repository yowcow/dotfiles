local wezterm = require 'wezterm';
local font_size = 11.0;

if package.config:sub(1,1) == "/" then
  -- Unix-like
end

return {
  color_scheme = "Molokai",
  font = wezterm.font({
    family = "JetBrains Mono",
    harfbuzz_features = {"calt=0", "clig=0", "liga=0"}, -- disable ligature feature
  }),
  font_size = font_size,
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
