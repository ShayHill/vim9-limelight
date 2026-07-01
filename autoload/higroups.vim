vim9script
# ---------------------------------------------------------------------------- #
# Build highlight groups for vim-9 limelight

import '../autoload/colormath.vim'


# Try to get at least this much squared Euclidean distance between the color
# of the 'Current Now' statusline and the 'Not Current' (StatusLineNC)
# statusline. If no candidate is found that meets this criterion, use the
# candidate with the best squared Euclidean distance from StatusLineNC.
const SUFFICIENT_CONTRAST = 16000


def GetConfig(key: string, default: any): any
  # Get a value from the colorscheme config. If not defined, return the default value.
  return get(g:, 'limelight_config', {})->get(g:colors_name, {})->get(key, default)
enddef


def GetConfigInList(key: string, default: list<string>): list<string>
  # Get a value from the colorscheme config. Return as list if not already a
  # list. By default, vim9-limelight will produce a list of candidate colors
  # for some highlight groups. If these candidates are overridden in the
  # g:limelight_config, they are overridden as ONE hightlight group that will
  # be used instead of any other candidate. Wrap this one candidate in a list
  # so it can be passed to functions expecting the default candidate list.
  var value = GetConfig(key, default)
  if type(value) != type([])
    return [value]
  endif
  return value
enddef


export def HlgetOrEmpty(hi_group: string): dict<any>
  # Get a highlight group dictionary. If the highlight group does not exist,
  # return an empty dictionary.
  var hi_dict: dict<any>
  try
    hi_dict = hlget(hi_group, v:true)[0]
  catch /^Vim\%((\a\+)\)\=:E684:/
    hi_dict = {}
  endtry
  return hi_dict
enddef


def HiFgOrBgJustOne(source: string, fg_or_bg: string): dict<string>
  # Try to get either the fg or bg colors from a highlight group.
  #
  # # Inputs:
  #   source: highlight group name
  #   fg_or_bg: 'fg' or 'bg'
  #
  # Returns:
  #   dict with keys ['gui' and 'cterm']
  var gui_g: string  # hold val of gui_attr (guifg or guibg)
  var cterm_g: string  # hold val of cterm_attr (ctermfg or ctermbg)
  var gui_attr = 'gui' .. fg_or_bg
  var cterm_attr = 'cterm' .. fg_or_bg

  var hidict = HlgetOrEmpty(source)
  var is_gui_reversed = hidict->get('gui', {})->get('reverse', v:false)
  var is_cterm_reversed = hidict->get('cterm', {})->get('reverse', v:false)

  if is_gui_reversed
    gui_attr = gui_attr == 'guifg' ? 'guibg' : 'guifg'
  endif
  if is_cterm_reversed
    cterm_attr = cterm_attr == 'ctermfg' ? 'ctermbg' : 'ctermfg'
  endif

  gui_g = colormath.TryHex(hidict->get(gui_attr, ''))
  cterm_g = colormath.TryHex(hidict->get(cterm_attr, ''))
  gui_g = gui_g != '' ? gui_g : cterm_g
  cterm_g = cterm_g != '' ? cterm_g : gui_g

  return {gui: gui_g, cterm: cterm_g}
enddef


def HiFgOrBgWithFallback(sources: list<string>, fg_or_bg: string): dict<string>
  # Get either the fg or bg colors from the first viable candidate in a list
  # of sources. Search order is.
  # * if the first source has both guifg and ctermfg, return both
  # * if the first source has one of guifg or ctermfg, match them as
  #   closely as possible
  # * if the first source has neither guifg or ctermfg, move to the next
  #   source
  # * if all sources are exhausted, return black for fg or white for bg
  #
  # Inputs:
  #  sources: list of highlight group names
  #  fg_or_bg: 'fg' or 'bg'
  #
  # Returns:
  #   dict with keys ['guifg' and 'ctermfg'] or ['guibg' and 'ctermbg']. Will
  #   always return hex values, even for cterm colors. These will need to be
  #   converted back for assignent to hi cterm values.
  var result: dict<string>
  for source in sources
    result = HiFgOrBgJustOne(source, fg_or_bg)
    if result.gui != ''
      return result
    endif
  endfor
  if fg_or_bg == 'fg'
    return {gui: '#000000', cterm: '#000000'}
  endif
  return {gui: '#ffffff', cterm: '#ffffff'}
enddef


def HiGroundsWithFallback(sources: list<string>): dict<string>
  # Get **display** guifg, guibg, ctermfg, and ctermbg from the first viable
  # source in sources. The **display** part is important. Often, a highlight
  # group contains the instruction `gui=reverse` or `cterm=reverse`. In
  # those cases, this function will return the bg color for guifg and the fg
  # color for guibg. This can get confusing, because when these colors are
  # eventually reassigned to other highlight groups, you may be setting the
  # explicit (exactly as stated in the highlight group) guibg with the
  # **display** guifg.
  #
  # This differs from HiGroundsJustOne in that the fg and bg colors may not come from
  # the same highlight group.

  var fgs = HiFgOrBgWithFallback(sources, 'fg')
  var bgs = HiFgOrBgWithFallback(sources, 'bg')

  return {
    guifg: fgs.gui,
    guibg: bgs.gui,
    ctermfg: fgs.cterm,
    ctermbg: bgs.cterm,
  }
enddef


# ---------------------------------------------------------------------------- #
#
# Create new highlight groups
#
# ---------------------------------------------------------------------------- #

def IsGuiReversed(hi_dict: dict<any>): bool
  # Check if a highlight group is reversed in the GUI.
  # Inputs:
  #   hi_dict - highlight group dictionary
  # Returns:
  #   true if the highlight group is reversed, false otherwise
  return hi_dict->get('gui', {})->get('reverse', v:false) ||
         hi_dict->get('gui', {})->get('standout', v:false)
enddef


def IsCtermReversed(hi_dict: dict<any>): bool
  # Check if a highlight group is reversed in the terminal.
  # Inputs:
  #   hi_dict - highlight group dictionary
  # Returns:
  #   true if the highlight group is reversed, false otherwise
  return hi_dict->get('cterm', {})->get('reverse', v:false)
enddef


def MakeStandout(hi_dict: dict<any>, group: string): void
  # Reverse the fg and bg colors of a highlight group.
  # Inputs:
  #   hi_dict - highlight group dictionary
  #   group - name of the highlight group ('gui' or 'cterm')
  # Returns:
  #   hi_dict with reversed fg and bg colors
  #
  # If standout or reverse is set, unset it. Otherwise, set standout. This
  # doesn't always work, because the way colorschemes handle reverse and
  # standout vary wildly. Worse, it will work for some hi groups and not for
  # others ... in the same colorscheme.
  var is_reversed = v:false
  var value = hi_dict->get(group, {})
  if value->get('reverse', v:false)
    remove(value, 'reverse')
    is_reversed = v:true
  endif
  if value->get('standout', v:false)
    remove(value, 'standout')
    is_reversed = v:true
  endif
  if !is_reversed
    hi_dict.gui = hi_dict->get(group, {})->extend({ standout: v:true })
  endif
  # just to be tidy, remove the group if we've emptied it
  if hi_dict->get(group, { missing: v:true }) == {}
    remove(hi_dict, group)
  endif
enddef


def HardHi(base_hi_group: string, basename: string = ''): void
  # Create an emphasized version of a highlight group.
  #
  # Inputs:
  #   base_hi_group - highlight group from which to inherit default values
  #   basename - optionally pass a basename for the new highlight group, if
  #   no basename is given, a new group `base_hi_group .. 'Hard'` will be
  #   created.
  # Effects:
  #  Creates a new highlight group which should be an emphasized version of
  #  the input highlight group
  var hldict = HlgetOrEmpty(base_hi_group)
  hldict.name = basename == '' ? base_hi_group .. 'Hard' : basename .. 'Hard'

  # make text bold
  if has('gui_running')
    hldict.gui = hldict->get('gui', {})->extend({ bold: v:true })
  else
    MakeStandout(hldict, 'gui')
    MakeStandout(hldict, 'term')
    MakeStandout(hldict, 'cterm')
  endif

  hlset([hldict])
enddef


def SoftHi(base_hi_group: string, basename: string = ''): void
  # Create a de-emphasized version of a highlight group.
  #
  # Inputs:
  #   base_hi_group - highlight group from which to inherit default values
  #   basename - optionally pass a basename for the new highlight group, if
  #   no basename is given, a new group `base_hi_group .. 'Soft'` will be
  #   created.
  # Effects:
  #   Creates a new highlight group which should be a de-emphasized version of
  #   the input highlight group
  var new_name = basename == '' ? base_hi_group .. 'Soft' : basename .. 'Soft'
  var text_fade = GetConfig('text_fade', g:limelight_text_fade)
  if text_fade <= 0.0
    execute 'highlight! link ' .. new_name .. ' ' .. base_hi_group
    return
  endif

  var hldict = hlget(base_hi_group, v:true)[0]
  hldict.name = new_name

  var grounds = HiGroundsWithFallback([base_hi_group])

  if IsGuiReversed(hldict)
    hldict.guibg = colormath.MixColors(grounds.guifg, grounds.guibg, text_fade)
  else
    hldict.guifg = colormath.MixColors(grounds.guibg, grounds.guifg, text_fade)
  endif

  if IsCtermReversed(hldict)
    hldict.ctermbg = colormath.HexToCterm(colormath.MixColors(grounds.ctermfg, grounds.ctermbg, text_fade))
  else
    hldict.ctermfg = colormath.HexToCterm(colormath.MixColors(grounds.ctermbg, grounds.ctermfg, text_fade))
  endif

  hlset([hldict])
enddef


def PickCurrentNowHi(candidates: list<string>): string
  # Search the highlight group candidates for a candidate with sufficient
  # background contrast with StatusLineNC. If no candidate with sufficient
  # contrast is found, return the best candidate.
  #
  # Unexpected things that could cause this to fail
  # - StatusLineNC is not defined (this is a default highlight group, so it
  #   should always exist)
  # - None of the candidates exist
  # - No candidates are provided
  # - None of the candidates has a background color
  #
  # If one of these or any other problem occurs, just return 'StatusLine',
  # the default statusline hightlight group.
  var candidates_prime = GetConfigInList('cn', candidates)
  try
    var statusline_nc_bg = HiGroundsWithFallback(['StatusLineNC']).guibg
    var contrast: number
    var guibg: string
    var best_contrast = 0
    var best_candidate = candidates_prime[0]

    for candidate in candidates_prime
      guibg = HiFgOrBgJustOne(candidate, 'bg')->get('gui', '')
      if guibg == '' | continue | endif

      contrast = colormath.SqColorSpan(statusline_nc_bg, guibg)
      if contrast > SUFFICIENT_CONTRAST
        return candidate
      endif
      if contrast > best_contrast
        best_contrast = contrast
        best_candidate = candidate
      endif
    endfor

    if best_contrast == 0
      return 'StatusLine'
    endif
    return best_candidate
  catch
    return 'StatusLine'
  endtry
enddef


def SplitHi(hi_group: string, basename: string = ''): void
  # Split a highlight group into three.
  # * base
  # * baseHard
  # * baseSoft
  #
  # Inputs:
  #   hi_group - name of an existing highlight group
  #   basename - optional basename for new highlight groups
  #
  # If a basename is given
  # * create basename identical to hi_group
  # * create basename .. 'Hard' from hi_group
  # * create basename .. 'Soft' from hi_group
  #
  # If no basename is given
  # * create hi_group .. 'Hard' from hi_group
  # * create hi_group .. 'Soft' from hi_group
  if basename == ''
    HardHi(hi_group)
    SoftHi(hi_group)
    return
  endif
  var hldict = hlget(hi_group, v:true)[0]
  hldict.name = basename
  hlset([hldict])

  HardHi(hi_group, basename)
  SoftHi(hi_group, basename)
enddef


def DefineNormalNC(): void
  # Define a Normal highlighting group for non-current windows. This will
  # provide a background color for shaded windows.
  var bg_fade = GetConfig('bg_fade', g:limelight_bg_fade)
  var grounds_candidates = GetConfigInList('bg', [])
  var do_set_pmenu = GetConfig('set_pmenu', v:false)

  if index(grounds_candidates, 'Normal') == -1
    add(grounds_candidates, 'Normal')
  endif

  if bg_fade <= 0.0
    execute 'highlight! link NormalNC ' .. grounds_candidates[0]
    if do_set_pmenu
      execute 'highlight! link Pmenu ' .. grounds_candidates[0]
    endif
    return
  endif

  var grounds = HiGroundsWithFallback(grounds_candidates)
  var grounds_nc = HlgetOrEmpty(grounds_candidates[0])
  grounds_nc.name = 'NormalNC'
  grounds_nc.guibg = colormath.MixColors(grounds.guifg, grounds.guibg, bg_fade)
  grounds_nc.ctermbg = colormath.HexToCterm(colormath.MixColors(grounds.ctermfg, grounds.ctermbg, bg_fade))
  hlset([grounds_nc])

  # overwrite the Pmenu hi group if user requests it
  if do_set_pmenu
    grounds_nc.name = 'Pmenu'
    hlset([grounds_nc])
  endif

  # any background defined for EndOfBuffer will prevent empty windows (like
  # terminals with no text) from shading
  highlight EndOfBuffer guibg=NONE ctermbg=NONE
enddef


export def LimelightReset(): void
  # Reset all the hi groups.
  # Reset the highlight groups defined by Limelight and fix some errors that can be
  # caused by switching to/from more/less featureful colorschemes. These errors are
  # not related to Limelight, but this is as good a place as any to fix them.
  #
  # Call this when the colorscheme changes
  var cursor_hi = PickCurrentNowHi(g:limelight_cn_candidates)
  SplitHi('StatusLine')
  SplitHi('StatusLineNC')
  SplitHi(cursor_hi, 'StatusLineCN')
  DefineNormalNC()
  # address errors not related to Limelight
  highlight link LspErrorHighlight Error
  highlight link LspWarningHighlight Todo
  highlight link LspInformationHighlight Normal
  highlight link LspHintHighlight Normal
enddef
