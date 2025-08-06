vim9script

import "../autoload/colormath.vim"
import "../autoload/higroups.vim"

v:errors = []

if assert_equal(colormath.SqEuclidean([0, 0, 1], [0, 0, 0]), 1) | throw v:errors[-1] | endif
if assert_equal(colormath.SqEuclidean([255, 0, 0], [0, 0, 0]), 65025) | throw v:errors[-1] | endif

if assert_equal(colormath.TryHex('#ffffff'), '#ffffff') | throw v:errors[-1] | endif
if assert_equal(colormath.TryHex('0'), '#000000') | throw v:errors[-1] | endif
if assert_equal(colormath.TryHex(''), '') | throw v:errors[-1] | endif
if assert_equal(colormath.TryHex('garbage'), '') | throw v:errors[-1] | endif
if assert_equal(colormath.TryHex('Red'), '#ff0000') | throw v:errors[-1] | endif
if assert_equal(colormath.TryHex('White'), '#ffffff') | throw v:errors[-1] | endif

if assert_equal(higroups.HlgetOrEmpty('DoesNotExist'), {}) | throw v:errors[-1] | endif
