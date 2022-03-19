local wezterm = require 'wezterm';
local font_size = 5.0;

return {
  color_scheme = "Molokai",
  font = wezterm.font({
    family = "JetBrains Mono",
    harfbuzz_features = {"calt=0", "clig=0", "liga=0"}, -- disable ligature feature
  }),
  font_size = font_size,
  tab_bar_at_bottom = true,
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
