-- Catppuccin Mocha, matching Kitty, tmux, SketchyBar and the window borders.
-- The catppuccin plugin ships with LazyVim; this only picks it.
return {
  { "catppuccin/nvim", name = "catppuccin", opts = { flavour = "mocha" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
