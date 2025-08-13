vim9script
# ---------------------------------------------------------------------------- #
# Convert between color formats and mix hex colors.


def HexToRgb(hex_color: string): list<number>
  # convert a color in 16bit hex notation (e.g., '#ffffff') to three 16-bit
  # integers
  var red = str2nr('0x' .. strpart(hex_color, 1, 2), 16)
  var green = str2nr('0x' .. strpart(hex_color, 3, 2), 16)
  var blue = str2nr('0x' .. strpart(hex_color, 5, 2), 16)
  return [red, green, blue]
enddef


def RgbToHex(rgb: list<number>): string
  # Convert three floats [0 .. 255] to a 16-bit color hex string (e.g.,
  # '#ffffff')
  var three_hex = map(copy(rgb), (_, v) => printf('%02x', v))
  return '#' .. join(three_hex, '')
enddef


def ValueToColorIndex(v: number): number
  # Strength of color value [0 .. 5].
  # Subroutine of HexToCterm
  #
  # Inputs:
  #   v - [0 .. 255]
  # Returns:
  #   [0 .. 5]
  #
  # Red identifies a subset of the cterm colors [16 .. 231]
  # Green identifies a subset of that subset
  # Blue idenfities a member of *that* subset
  if v < 48
    return 0
  elseif v < 115
    return 1
  else
    return (v - 35) / 40
  endif
enddef


export def SqEuclidean(vec_a: list<number>, vec_b: list<number>): number
  # Squared Euclidean distance between two vectors
  var diffs = map(copy(vec_a), (i, v) => v - vec_b[i])
  var terms = map(copy(diffs), (_, v) => v * v)
  return terms[0] + terms[1] + terms[2]
enddef


export def SqColorSpan(hex_color_a: string, hex_color_b: string): number
  # Squared distance between two colors in the RGB color space
  #
  # Inputs:
  #   hex_color_a - '#ffffff'
  #   hex_color_b - '#000000'
  # Returns:
  #   [0 .. 195075]
  #
  # This is only useful for determining < = > relationships between pairs of
  # colors.
  var rgb_a = HexToRgb(hex_color_a)
  var rgb_b = HexToRgb(hex_color_b)
  return SqEuclidean(rgb_a, rgb_b)
enddef


export def HexToCterm(hex_color: string): string
  # The nearest cterm color to a hex color
  # This is apparently the algorithm used by tmux, but it won't necessarily
  # produce the same result as a brute force check. Definitely close enough
  # and a lot faster.
  #
  # Returns
  #   [16 .. 255] 1-15 (user-defined colors) are ignored
  var rgb = HexToRgb(hex_color)

  # nearest xterm color [0 .. 215] => [16 .. 231]
  var [ir, ig, ib] = map(copy(rgb), (_, v): number => ValueToColorIndex(v))
  var color_index = 36 * ir + 6 * ig + ib

  # nearest xterm grayscale [0 .. 23] => [232 .. 255]
  var average = (rgb[0] + rgb[1] + rgb[2]) / 3
  var gray_index = average > 238 ? 23 : (average - 3) / 10

  # Calculate the represented colors back from the indices
  var i2cv = [0, 0x5f, 0x87, 0xaf, 0xd7, 0xff]
  var cterm_color = map([ir, ig, ib], (_, v) => i2cv[v])
  var [cr, cg, cb] = cterm_color  # [[0 .. 255], [0 .. 255], [0 .. 255]]
  var gv = 8 + 10 * gray_index  # [0 .. 255]

  var gray_err = SqEuclidean(rgb, [gv, gv, gv])
  var color_err = SqEuclidean(rgb, cterm_color)
  return color_err <= gray_err ? string(16 + color_index) : string(232 + gray_index)
enddef


# The first 16 terminal colors (If the user hasn't changed them).
const TERM_COLORS = [
  '#000000', '#800000', '#008000', '#808000',
  '#000080', '#800080', '#008080', '#c0c0c0',
  '#808080', '#ff0000', '#00ff00', '#ffff00',
  '#0000ff', '#ff00ff', '#00ffff', '#ffffff'
]


def CtermToHex(cterm_color: string): string
  # An inverse of the transformation in HexToCterm. Not the same result as a
  # simple map, but keeping consistent with Hex2Cterm.
  var num = str2nr(cterm_color)
  if num == 0 && cterm_color != '0'
    throw 'Cannot create hex color from ' .. cterm_color
  endif
  if num < 16
    return TERM_COLORS[num]
  endif

  if num > 231
    var gray = 23 - (255 - num)
    gray = gray * 10 + 8
    return RgbToHex([gray, gray, gray])
  endif

  var rem = num - 16
  var red = rem / 36
  rem = rem % 36
  var grn = rem / 6
  var blu = rem % 6
  var i2cv = [0, 0x5f, 0x87, 0xaf, 0xd7, 0xff]
  return RgbToHex(map([red, grn, blu], (_, v) => i2cv[v]))
enddef


export def TryHex(color: string): string
  # Try to get a hex color from one of the (too) many color arguments Vim
  # allows. Return '' if failed.
  # Inputs:
  #   color - [0 .. 255] as a string
  # Returns:
  #   given ['0' .. '255'] - a hex-color value for a cterm index
  #   given '#ffffff' - '#ffffff'
  #   given 'red' = '#ff0000'
  #   given 'Red' = '#ff0000'
  #   given '' or invalid input = ''
  var hex: string

  # if color arg is already a hex string
  if len(color) == 7 && color[0] == '#' | return color | endif

  # if color arg is an empty string
  if color == '' | return '' | endif

  # try color arg as a [0 .. 255] palette index
  try
    hex = CtermToHex(color)
  catch /Cannot create hex color from/
    hex = ''
  endtry

  # try color arg as a key in v:colornames dict
  if hex == '' | hex = v:colornames->get(tolower(color), '') | endif

  return hex
enddef


# A large integer that won't break most systems. Used for
# FloatTo8BitNr.
const BIG_INT = pow(2, 32) - 1


def ClipTo0Through255(val: float): float
  # Clip a number to the closed interval [0 .. 255]
  #
  # Inputs:
  #   val - a number
  # Returns:
  #   a number in the closed interval [0 .. 255]
  if val < 0
    return 0.0
  elseif val > 255
    return 255.0
  endif
  return val
enddef


def FloatTo8BitNr(val: float): number
    # Convert a float between 0 and 255 to an int between 0 and 255.
    #
    # Inputs:
    #   float_ - a float in the closed interval [0 .. 255]. Values
    #   outside this range will be clipped.
    # Returns:
    #   number in the closed interval [0 .. 255]
    var val_prime = ClipTo0Through255(val)
    if float2nr(val_prime) == val_prime
      return float2nr(val_prime)
    endif
    var high_int = float2nr(val_prime / 255 * BIG_INT)
    return high_int >> 24
enddef


export def MixColors(hex_color_a: string, hex_color_b: string, ratio: float): string
  # Mix two hex colors.
  var rgb_a = HexToRgb(hex_color_a)
  var rgb_b = HexToRgb(hex_color_b)
  var mixed = map(copy(rgb_a), (i, v): float => v * ratio + rgb_b[i] * (1 - ratio))
  return RgbToHex(map(mixed, (_, v) => FloatTo8BitNr(v)))
enddef

