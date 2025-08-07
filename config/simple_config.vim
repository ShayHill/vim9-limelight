vim9script

# ---------------------------------------------------------------------------- #
#
#  Statusline with vim9-limelight
#
#  Source this file to see the vim9-limelight statusline plugin at work.
#
# ---------------------------------------------------------------------------- #

# show the statusline always
set laststatus=2

# ---------------------------------------------------------------------------- #
#  Limelight configuration
#
#  Keys for colorscheme-specific configuration:
#
#    cn: highlight group for active statusbar when split
#
#    bg: highlight group for shaded windows
#
#    bg_fade: fade factor for shaded windows. 0.0 to 1.0
#
#    text_fade: fade factor for 'soft' text in the statusline.
#
#    set_pmenu: bool - replace Pmenu with faded bg color.
# --------------------------------------------------------------------------- #

# the defaults, just to show the config variables
g:limelight_cn_candidates = ['IncSearch', 'Search', 'ErrorMsg']
g:limelight_text_fade = 0.65
g:limelight_bg_fade = 0.1

# colorscheme-specific settings
g:limelight_config = {
  blue: {bg_fade: 0.2, text_fade: 0.5},
  default: {cn: 'ErrorMsg', bg: 'Pmenu', bg_fade: 0.2, text_fade: 0.5},
  zaibatsu: {set_pmenu: v:true}
}

# ---------------------------------------------------------------------------- #
#  Put the Limelight functions to work
# ---------------------------------------------------------------------------- #

def g:MyStatusLine(): string
  # build a statusline string using vim9-limelight
  
  # a string that will hold the entire statusline argument
  var stl = ""

  # g:LimelightHiSelect chooses a highlight group based on winid
  var hi_group = g:LimelightHiSelect(g:statusline_winid, 'StatusLine', 'StatusLineNC', 'StatusLineCN')

  # g:LimelightSelect chooses a string based on winid
  var state = g:LimelightSelect(g:statusline_winid, 'STATUS LINE', 'NOT CURRENT', 'CURRENT NOW')

  # set your highlighting
  stl ..= hi_group

  # show the state, to help show what is going on
  stl ..= ' ' .. state .. ' --->'

  # show a few of the usual items
  stl ..= ' %f %h%w%m%r %=%(%l,%c%V %= %P%'

  return stl
enddef

set statusline=%!MyStatusLine()

