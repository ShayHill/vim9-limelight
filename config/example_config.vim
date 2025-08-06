vim9script

# ---------------------------------------------------------------------------- #
#
#  Statusline with vim9-focalpoint
#
#  Source this file to see the vim9-focalpoint statusline plugin at work.
#
# ---------------------------------------------------------------------------- #

set laststatus=2

# default values for config variables. No need to include these unless you
# want to change them.
# g:focalpoint_cn_candidates = ['IncSearch', 'Search', 'ErrorMsg']
# g:focalpoint_text_fade = 0.65
# g:focalpoint_bg_fade = 0.1

# def g:GenerateStatusline(winid: number): string
#   # build a statusline string using vim9-focalpoint
  
#   var stl = ""

#   # g:FPHiSelect chooses a highlight group based on winid
#   var hi_group = g:FPHiSelect(winid, 'StatusLine', 'StatusLineNC', 'StatusLineCN')

#   # g:FPSelect chooses a string based on winid
#   var state = g:FPSelect(winid, 'STATUS LINE', 'NOT CURRENT', 'CURRENT NOW')

#   # set your highlighting
#   stl ..= hi_group

#   # show the state, to help show what is going on
#   stl ..= ' ' .. state .. ' --->'

#   # show a few of the usual items
#   stl ..= ' %f %h%w%m%r %=%(%l,%c%V %= %P%'

#   return stl
# enddef

g:line_mode_map = {
  n: 'N',
  v: 'V',
  V: 'V',
  '\<c-v>': 'V',
  i: 'I',
  R: 'R',
  r: 'R',
  Rv: 'R',
  c: 'C',
  s: 'S',
  S: 'S',
  '\<c-s>': 'S',
  t: 'T'
}

def g:GenerateStatusline(winid: number): string
  var stl = ""

  # inline highlight group strings
  var bold_f = g:FPHiSelect(winid, 'StatusLineHard', 'StatusLineNCSoft', 'StatusLineCNHard')
  var weak = g:FPHiSelect(winid, 'StatusLineSoft', 'StatusLineNCSoft', 'StatusLineCNSoft')
  var weak_u = g:FPHiSelect(winid, 'StatusLine', 'StatusLineNCSoft', 'StatusLineCN')
  var bold_u = g:FPHiSelect(winid, 'StatusLine', 'StatusLineNCHard', 'StatusLineCN')
  var plain = g:FPHiSelect(winid, 'StatusLine', 'StatusLineNC', 'StatusLineCN')

  var sep = plain .. '|'

  # show current mode in bold
  stl ..= bold_f .. ' %{g:line_mode_map[mode()]} ' .. sep

  # show branch (requires fugitive)
  if exists('g:loaded_fugitive')
    stl ..= weak_u .. ' %{FugitiveHead()} ' .. sep
  endif

  # relative file path
  stl ..= plain .. ' %f %M'
  # empty space to right-anchor remaining items
  stl ..= '%='

  # line and column numbers
  stl ..= plain .. ' %l' .. ':' .. '%L' .. ' ☰ ' .. '%v %c '
  stl ..= sep

  # buffer number
  stl ..= weak .. ' b' .. bold_u .. '%n'

  # window number
  stl ..= weak .. ' w' .. bold_u .. '%{win_getid()} '
  return stl
enddef

set statusline=%!GenerateStatusline(g:statusline_winid)

# comment this out to remove window shading
augroup ShadeNotCurrentWindow
  autocmd!
  autocmd WinEnter * setl wincolor=Normal
  autocmd WinLeave * setl wincolor=NormalNC
augroup END

g:focalpoint_explicate = {
  PaperColor: {cn: 'DiffAdd', bg: 'MatchParen', bg_fade: 0.25},
  blue: {bg_fade: 0.2, text_fade: 0.99},
  darkblue: {bg_fade: 0.2},
  default: {cn: 'ErrorMsg', bg: 'Pmenu', bg_fade: 0.1},
  delek: {bg: 'Pmenu', bg_fade: 0.0},
  elflord: {bg: 'Pmenu', bg_fade: 0.2},
  habamax: {bg: 'Pmenu', bg_fade: 0.0},
  industry: {bg: 'Pmenu', bg_fade: 0.0},
  koehler: {bg: 'Pmenu', bg_fade: 0.0},
  lunaperche: {bg: 'Pmenu', bg_fade: 0.0},
  morning: {bg: 'Pmenu', bg_fade: 0.0},
  murphy: {bg_fade: 0.2},
  pablo: {bg: 'Pmenu', bg_fade: 0.0},
  peachpuff: {bg: 'Pmenu', bg_fade: 0},
  quiet: {bg: 'Pmenu', bg_fade: 0.0},
  retrobox: {bg: 'Pmenu', bg_fade: 0.0},
  ron: {bg_fade: 0.2},
  solarized8: {bg_fade: 0.25},
  sunbather: {cn: 'Search'},
  torte: {bg: 'Pmenu', bg_fade: 0.0},
  wildcharm: {bg: 'Pmenu', bg_fade: 0.0},
}
