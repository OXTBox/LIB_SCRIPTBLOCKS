#!/usr/bin/env python3
"""LIB_SCRIPTBLOCKS's check that runs without LiveCode (A-50): a script is cut into handlers the way
harvest_blocks.py promises (comments above go with their handler, a missing end is noted) and
handler names land in GAD's categories.

    python3 -I tests/run_tests.py
"""
import os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import harvest_blocks as hb                 # noqa: E402

CHECKS, FAILS = [0], []


def check(name, ok, got=None):
    CHECKS[0] += 1
    if not ok:
        FAILS.append(name)
        print("FAIL  %s%s" % (name, "" if got is None else "  (got %r)" % (got,)))
    else:
        print("ok    %s" % name)


def done():
    print("\n%d of %d passed" % (CHECKS[0] - len(FAILS), CHECKS[0]))
    return 1 if FAILS else 0


SCRIPT = """-- adds one point
on Update.Score pN
   add pN to gScore
end Update.Score

function Math.Twice x
   return x * 2
end Math.Twice
command broken
   beep
on mouseUp
   beep
end mouseUp
"""


def main():
    hs = hb.handlers(SCRIPT)
    names = [h[0] for h in hs]
    check('four handlers in order', names == ['Update.Score', 'Math.Twice', 'broken', 'mouseUp'], names)
    check('the comment above goes with its handler', hs[0][2].startswith('-- adds one point'))
    check('the kind is kept', [h[1] for h in hs] == ['on', 'function', 'command', 'on'])
    check('a handler with no end line is noted', 'no "end broken" line' in hs[2][2])
    check('categories: GameObject before Game, unknown is Utility',
          (hb.category('Update.Score'), hb.category('GameObjectMove'), hb.category('zzz')) == ('Update', 'GameObject', 'Utility'),
          (hb.category('Update.Score'), hb.category('GameObjectMove'), hb.category('zzz')))
    return done()


if __name__ == '__main__':
    sys.exit(main())
