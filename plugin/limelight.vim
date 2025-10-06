vim9script
# ---------------------------------------------------------------------------- #
#
# StatusLineNC
#
# Statuslines in Vim are by default highlighted with the StatusLine and
# StatusLineNC (StatusLine Not Current) highlight groups. When no splits are
# open, you will only see the StatusLine highlight group. When splits are
# open, the focused split will have the same StatusLine highlight and
# unfocused splits will have the StatusLineNC highlight.
#
# Often, I would prefer more contrast between these groups, so this module
# creates a third highlighting group for statuslines, StatusLineCN (StatusLine
# Current Now). When no splits are open, you will only see the StatusLine
# highlight group (a nice, coordinating color as the colorscheme designer
# intended it). When splits are open, the focused split will have the
# high-contrast StatusLineCN highlight and unfocused splits will have the
# StatusLineNC highlight.
#
# That part is simple. A lot of the code here is for the secondary functions
# of highlighting and lowlighting text against a background. The main purpose
# *is* to create a new StatusLineCN highlight group, but the module actually
# creates 8 new highlight groups for a total of 9 StatusLine highlight groups
# and 2 background highlight groups.
#
# * StatusLineHard (bold text for default statusline)
# * StatusLine  " previously existing
# * StatusLineSoft (grayed out text for default statusline)
#
# * StatusLineNCHard (bold text for unfocused statusline)
# * StatusLineNC  " previously existing
# * StatusLineNCSoft (grayed out text for unfocused statusline)
#
# * StatusLineCNHard (bold text for focused statusline with splits)
# * StatusLineCN  (normal text for focused statusline with splits)
# * StatusLineSoft (grayed out test for focused statusline with splits)
#
# * Normal  " previously existing
# * NormalNC (Normal with a faded background color)
#
# ---------------------------------------------------------------------------- #

if exists('g:loaded_limelight') || &cp
  finish
endif
g:loaded_limelight = v:true


import '../autoload/colormath.vim'
import '../autoload/higroups.vim'


# The high-contrast StatusLineNC highlight is selected from high-contrast
# highlight groups in the current colorscheme. These are the candidates in
# order of preference.
if !exists('g:limelight_cn_candidates')
  g:limelight_cn_candidates = ['IncSearch', 'Search', 'ErrorMsg']
endif

if !exists('g:limelight_text_fade')
  g:limelight_text_fade = 0.65
endif

if !exists('g:limelight_bg_fade')
  g:limelight_bg_fade = 0.1
endif


higroups.LimelightReset()


augroup ResetStatuslineHiGroups
  autocmd!
  autocmd colorscheme *  higroups.LimelightReset()
augroup END


augroup ShadeNotCurrentWindow
  autocmd!
  autocmd WinEnter * setl wincolor=Normal
  autocmd WinLeave * setl wincolor=NormalNC
augroup END


def WinState(winid: number): number
  # Return the state of the window with winid
  # 0: focused, no splits
  # 1: unfocused, has splits (a priori)
  # 2: focused, has splits
  #
  # Normal bg color is usually set with a WinEnter autocommand, but Vim will
  # reuse settings and bypass the autocommand in some instances. This was
  # explained to me by Christian Brabant in
  # https://github.com/vim/vim/issues/16882
  # The WinLeave autocommand never fails.
  var win_state = 1
  if winid == win_getid()
    win_state = winnr('$') > 1 ? 2 : 0
  endif
  if win_state != 1 && &wincolor != 'Normal' && &wincolor != ''
    setl wincolor=Normal
  endif
  return win_state
enddef


def g:LimelightSelect(
    winid: number,
    statusline: string,
    not_current: string,
    current_now: string
  ): string
  # Select a string for the statusline based on winid
  # * if win is focused, only one window visible, statusline
  # * if win is unfocused, not_current
  # * if win is focused AND there are open splits, current_now
  return [statusline, not_current, current_now][WinState(winid)]
enddef


def g:LimelightHiSelect(
    winid: number,
    statusline: string,
    not_current: string,
    current_now: string
  ): string
  # Select a highlight string for the statusline based on winid. The
  # difference between this and LimelightSelect is that LimelightHiSelect
  # wraps highlight groups in the correct symbols to be inserted directly into
  # a statusline string.
  return g:LimelightSelect(
    winid,
    '%#' .. statusline .. '#',
    '%#' .. not_current .. '#',
    '%#' .. current_now .. '#',
  )
enddef


if get(g:, 'limelight_source_simple_config', v:false) == v:true
  var plugin_dir = fnamemodify(expand('<sfile>'), ':h:h')
  execute 'source ' .. plugin_dir .. '/config/simple_config.vim'
endif


if get(g:, 'limelight_source_normal_config', v:false) == v:true
  var plugin_dir = fnamemodify(expand('<sfile>'), ':h:h')
  execute 'source ' .. plugin_dir .. '/config/normal_config.vim'
endif
