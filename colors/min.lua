-- 1. Clear existing highlights and reset syntax
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

-- 2. Tell Neovim the name of this colorscheme
vim.g.colors_name = "min"

-- 3. Ensure truecolor is on
vim.o.termguicolors = true

-- 4. Convenience helper
local set = vim.api.nvim_set_hl

-- 5. Define a simple palette
local black      = "#000000"
local blue_black = "#0a0a18"
local dark_grey  = "#606060"
local light_grey = "#c0c0c0"
local white      = "#ffffff"
local orange     = "#ff9000"
local red        = "#e04040"
local cyan       = "#80d0ff"
local blue       = "#00a0ff"
local yellow     = "#d0d000"
local green      = "#00ff00"

local cursor_sel = "#222244"


-- 6. Core UI groups
set(0, "Normal",       { fg = cyan,       bg = black })   -- background.
set(0, "CursorLine",   { bg = cursor_sel })               -- line cursor is on.
set(0, "NormalFloat",  { fg = cyan,       bg = black })   -- floating background.
set(0, "LineNr",       { fg = dark_grey,  bg = black })   -- line #s.
set(0, "CursorLineNr", { fg = light_grey, bg = black })   -- line # cursor is on.
set(0, "Visual",       { bg = cursor_sel })               -- visual mode highlight.
set(0, "Search",       { fg = black,      bg = yellow })  -- highlight on search.
set(0, "IncSearch",    { fg = black,      bg = orange })  -- highlight on current search match.
set(0, "WinSeparator", { fg = dark_grey,  bg = black })   -- window separator.

-- 7. Status line / tab line
set(0, "StatusLine",   { fg = cyan,  bg = "#1f2335" })
set(0, "StatusLineNC", { fg = cyan , bg = "#15172a" })
set(0, "TabLine",      { fg = cyan,  bg = "#15172a" })
set(0, "TabLineSel",   { fg = cyan,  bg = "#1f2335" })
set(0, "TabLineFill",  { fg = white, bg = black })

-- 8. Basic syntax groups
set(0, "Comment",      { fg = light_grey, italic = true })
set(0, "Constant",     { fg = cyan })
set(0, "String",       { fg = cyan })
set(0, "Number",       { fg = cyan })
set(0, "Boolean",      { fg = cyan })
set(0, "Identifier",   { fg = orange })
set(0, "Function",     { fg = blue })
set(0, "Keyword",      { fg = red, italic = true })
set(0, "Operator",     { fg = white })
set(0, "Type",         { fg = orange })

-- 9. Popup menu (completion)
set(0, "Pmenu",        { fg = cyan,     bg = blue_black })
set(0, "PmenuSel",     { fg = cyan,     bg = cursor_sel })
set(0, "PmenuSbar",    { bg = "#16161e" })
set(0, "PmenuThumb",   { bg = "#2f334d" })

set(0, "WhichKeyNormal",    {fg = cyan, bg = "#111122" })
set(0, "WhichKey",          {fg = orange})
set(0, "WhichKeyGroup",     {fg = cyan})
set(0, "WhichKeyDesc",      {fg = cyan})
set(0, "WhichKeySeparator", {fg = white})

-- 10. Diagnostics (LSP)
set(0, "DiagnosticError", { fg = red })
set(0, "DiagnosticWarn",  { fg = yellow })
set(0, "DiagnosticInfo",  { fg = cyan })
set(0, "DiagnosticHint",  { fg = green })
set(0, "DiagnosticUnderlineError", { undercurl = true, sp = red })
set(0, "DiagnosticUnderlineWarn",  { undercurl = true, sp = yellow })
set(0, "DiagnosticUnderlineInfo",  { undercurl = true, sp = cyan })
set(0, "DiagnosticUnderlineHint",  { undercurl = true, sp = green })

