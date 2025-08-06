# vim9-limelight

Shade unfocused windows. Give a bright statusline color for active windows *when splits are open*.

| ![focalpoint off](doc/focalpoint_off.jpg) | ![focalpoint on](doc/focalpoint_on.jpg) |
| - | - |
| without limelight | with limelight |

## One-line default config

Add one of these to your vimrc:

`g:limelight_source_simple_config = v:true`

`g:limelight_source_normal_config = v:true`

The simple config will will give you something to work from. It is created to *not* overwhelm you. It prints the window state in the statusline, so it's probably not something you're going to want to live with long term.

The normal config may be all you'll ever need. It's at its best if you are using git and pathogen.

Both example configs shade unfocused windows. To change this or make other changes, I recommend copying the example into your vim folder and sourcing it from your vimrc. You can find the example configs in the `config` folder of this repository.

Here it is with an assortment of colorschemes: [vim9-limelight](https://www.youtube.com/watch?v=xiXn2QDfUfs)

# More config

Statuslines in Vim are by default highlighted with the StatusLine and StatusLineNC (StatusLine Not Current) highlight groups. When no splits are open, you will only see the StatusLine highlight group. When splits are open, the focused split will have the same StatusLine highlight and unfocused splits will have the StatusLineNC highlight.

Often, I would prefer more contrast between these groups, so this module creates a third highlighting group for statuslines, StatusLineCN (StatusLine Current Now). When no splits are open, you will only see the StatusLine highlight group (a nice, coordinating color as the colorscheme designer intended it). When splits are open, the focused split will have the high-contrast StatusLineCN highlight and unfocused splits will have the StatusLineNC highlight.

If that's not enough contrast, Limelight will also shade unfocused windows when splits are open.

## Eight new highlight groups

Limelight creates 8 new highlight groups for a total of 9 StatusLine highlight groups and 2 background highlight groups.

- **StatusLineHard** (bold text for default statusline)
- StatusLine (previously existing)
- **StatusLineSoft** (grayed out text for default statusline)
- **StatusLineNCHard** (bold text for unfocused statusline)
- StatusLineNC (previously existing)
- **StatusLineNCSoft** (grayed out text for unfocused statusline)
- **StatusLineCNHard** (bold text for focused statusline with splits)
- **StatusLineCN** (normal text for focused statusline with splits)
- **StatusLineSoft** (grayed out test for focused statusline with splits)
- Normal (previously existing)
- **NormalNC** (Normal with a faded background color for shaded windows)

## Two functions for choosing content and format based on window state

Even if you aren't familiar with vim9script, I think the functions themselves are the best explanation.

~~~python
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
  # Select a highlight string for the statusline based on winid. The difference
  # between this and LimelightSelect is that LimelightHiSelect wraps highlight
  # groups in the correct symbols to be inserted directly into a statusline
  # string.
  return g:LimelightSelect(
    winid,
    '%#' .. statusline .. '#',
    '%#' .. not_current .. '#',
    '%#' .. current_now .. '#',
  )
enddef
~~~

The idea is to call these from a statusline-generating function. See `:h statusline`.

This function will have access to the `g:statusline_winid` variable, which Vim generates automatically. We will use that variable to select highlight groups based on one of three states:

- **normal**: only one split is open
- **not_current**: splits open, but this window is not in focus
- **current_now**: splits open, and this window is in focus

### A minimal working config

~~~python
vim9script

set laststatus=2

def g:GenerateStatusline(): string
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

set statusline=%!GenerateStatusline(g:statusline_winid)
~~~

If you are using vim9script, you can copy and paste the last code block into your vimrc. You'll have a simple statusline that performs the neat trick of brightening up when you have splits open. Once you understand how it works, you can build something more elaborate, changing highlight groups as many times as you like to make every element three unique (one per state) colors if you wish.

I've provided the 7 new highlight groups for convenience, but you can use `g:LimelightHiSelect` to select from any highlight group you desire or create.

`:hi<CR>` to see what's already defined.

## Configuration

### statusline colors

Limelight is configured to search for a contrasting statusline color in these highlight groups, most preferred to least.

~~~vim
g:limelight_cn_candidates = ['IncSearch', 'Search', 'ErrorMsg']
~~~

You can re-order, shrink, or expand this list in your vimrc. Be aware that if Limelight cannot find something appropriate in your list, it is written to fail silently and revert to the default Vim statusline highlight behavior.

### grayed-out text

Limelight "grays out" text for the [Basename]Soft hightlight groups by mixing foreground and background colors at a specified ratio. You can change this ratio in your vimrc. Be aware that terminal colors are defined in wide, discrete colors (there are only 256 of them in total), so a small ratio might not be enough mixing to change the text color at all. A too-large ratio might push the text color all the way into the background color.

~~~vim
g:limelight_text_fade = 0.65
~~~

### background shading

Limelight creates the NormalNC highlight group by mixing the default (Normal) foreground and background colors at a specified ratio. You can change this ratio in your vimrc. As with limelight_text_fade, be aware that too small or too large ratios can eliminate the effect entirely in the terminal.

~~~vim
g:limelight_bg_fade = 0.1
~~~

### colorscheme-specific settings

The above setting define a default strategy for creating highlight groups from any colorscheme. You can specify per-colorscheme settings with a dictionary of dictionaries.

~~~python
g:limelight_config = {
  blue: {bg_fade: 0.2, text_fade: 0.5},
  default: {cn: 'ErrorMsg', bg: 'Pmenu', bg_fade: 0.2, text_fade: 0.5},
  zaibatsu: {set_pmenu: v:true}
}
# -------------------------------------------------------------------------------- #
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
#   set_pmenu: bool - replace popup-window highlight group with NormalNC.
# -------------------------------------------------------------------------------- #
~~~

#### per-colorscheme config examples

Limelight creates a shaded background color by mixing foreground and background colors at a specified ratio. This creates a nice, muted shade for most achromatic backgrounds, but some colorschemes (peachpuff is a nice example) have a more chromatic "lowlight" color specified for their popup menus. 

| ![peachpuff default](doc/peachpuff_focalpoint.jpg) | ![peachpuff configured](doc/peachpuff_pmenu.jpg) |
| - | - |
| default peachpuff | `peachpuff {bg: 'Pmenu', bg_fade: 0.0}` |

Conversely, some colorscheme Pmenu backgrounds are terrible (white background with white text). Use key `set_pmenu` to replace the Pmenu background with the NormalNC color created by Limelight.

| ![zaibatsu_default](doc/zaibatsu_off.jpg) | ![zaibatsu configured](doc/zaibatsu_on.jpg) |
| - | - |
| default zaibatsu | `zaibatsu {set_pmenu: v:true}` |

## What if I don't use vim9script in my vimrc?

If you know just a bit of vimscript, you can revert the above functions to classic vimscript. You can run the plugin if you're using Vim9+, no matter what style you use in your vimrc. If you don't want to script anything, you could create a new file in your vimfolder, type vim9script on the top line, paste the above code sections into it, then source that from your vimrc.


![limelight, 1952](doc/Film_756_Limelight_original.jpg)
