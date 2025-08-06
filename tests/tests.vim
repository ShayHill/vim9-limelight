vim9script

import "../plugin/limelight.vim"

v:errors = []

if assert_equal(limelight.SqEuclidean([0, 0, 1], [0, 0, 0]), 1) | throw v:errors[-1] | endif
if assert_equal(limelight.SqEuclidean([255, 0, 0], [0, 0, 0]), 65025) | throw v:errors[-1] | endif

if assert_equal(limelight.TryHex('#ffffff'), '#ffffff') | throw v:errors[-1] | endif
if assert_equal(limelight.TryHex('0'), limelight.TERM_COLORS[0]) | throw v:errors[-1] | endif
if assert_equal(limelight.TryHex(''), '') | throw v:errors[-1] | endif
if assert_equal(limelight.TryHex('garbage'), '') | throw v:errors[-1] | endif
if assert_equal(limelight.TryHex('Red'), '#ff0000') | throw v:errors[-1] | endif
if assert_equal(limelight.TryHex('White'), '#ffffff') | throw v:errors[-1] | endif

if assert_equal(limelight.HlgetOrEmpty('DoesNotExist'), {}) | throw v:errors[-1] | endif
