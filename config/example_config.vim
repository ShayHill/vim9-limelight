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
# g:limelight_cn_candidates = ['IncSearch', 'Search', 'ErrorMsg']
# g:limelight_text_fade = 0.65
# g:limelight_bg_fade = 0.1

# def g:GenerateStatusline(winid: number): string
#   # build a statusline string using vim9-focalpoint
  
#   var stl = ""

#   # g:LimelightHiSelect chooses a highlight group based on winid
#   var hi_group = g:LimelightHiSelect(winid, 'StatusLine', 'StatusLineNC', 'StatusLineCN')

#   # g:LimelightSelect chooses a string based on winid
#   var state = g:LimelightSelect(winid, 'STATUS LINE', 'NOT CURRENT', 'CURRENT NOW')

#   # set your highlighting
#   stl ..= hi_group

#   # show the state, to help show what is going on
#   stl ..= ' ' .. state .. ' --->'

#   # show a few of the usual items
#   stl ..= ' %f %h%w%m%r %=%(%l,%c%V %= %P%'

#   return stl
# enddef


# -------------------------------------------------------------------------------- #
# Limelight configuration
#
# Keys for colorscheme-specific configuration:
#
#   cn: highlight group for active statusbar when split
#
#   bg: highlight group for shaded windows
#
#   bg_fade: fade factor for shaded windows. 0.0 means no fade, 1.0 means full fade.
#
#   text_fade: fade factor for 'soft' text in the statusline.
#
#   set_pmenu: bool - replace Pmenu with faded bg color. For attractive themes with
#   ugly popup_menu colors. Looking at you, zaibatsu.
# -------------------------------------------------------------------------------- #

# the defaults, but just to show the config variables
g:limelight_cn_candidates = ['IncSearch', 'Search', 'ErrorMsg']
g:limelight_text_fade = 0.65
g:limelight_bg_fade = 0.1


# comment this out to remove window shading
augroup ShadeNotCurrentWindow
  autocmd!
  autocmd WinEnter * setl wincolor=Normal
  autocmd WinLeave * setl wincolor=NormalNC
augroup END


# colorscheme-specific settings
g:limelight_config = {
  PaperColor: {cn: 'DiffAdd', bg: 'MatchParen', bg_fade: 0.25},
  blue: {bg_fade: 0.2},
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
  zaibatsu: {set_pmenu: v:true}
}


# -------------------------------------------------------------------------------- #
#  Put the Limelight functions to work
# -------------------------------------------------------------------------------- #


# nothing related to Limelight, just shorthand for statusline
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

  # hard when focused, whether split or unsplit, normal otherwise
  var hard_when_focused = g:LimelightHiSelect(winid, 'StatusLineHard', 'StatusLineNCSoft', 'StatusLineCNHard')
  # soft always
  var soft = g:LimelightHiSelect(winid, 'StatusLineSoft', 'StatusLineNCSoft', 'StatusLineCNSoft')
  # soft only when shaded, normal otherwise
  var soft_when_shaded = g:LimelightHiSelect(winid, 'StatusLine', 'StatusLineNCSoft', 'StatusLineCN')
  # normal always
  var plain = g:LimelightHiSelect(winid, 'StatusLine', 'StatusLineNC', 'StatusLineCN')

  # use plain hi group for all separators
  var sep = plain .. '|'

  # show current mode in bold (gvim) or reversed(terminal)
  stl ..= hard_when_focused .. ' %{g:line_mode_map[mode()]} ' .. sep

  # show branch (requires fugitive)
  if exists('g:loaded_fugitive')
    stl ..= soft_when_shaded .. ' %{FugitiveHead()} ' .. sep
  endif

  # relative file path
  stl ..= plain .. ' %f %M'
  # empty space to right-anchor remaining items
  stl ..= '%='

  # line and column numbers
  stl ..= plain .. ' %l' .. ':' .. '%L' .. ' ☰ ' .. '%v %c '
  stl ..= sep

  stl ..= soft .. ' b' .. plain .. '%n'

  # window number
  stl ..= soft .. ' w' .. plain .. '%{win_getid()} '
  return stl
enddef

set statusline=%!GenerateStatusline(g:statusline_winid)



