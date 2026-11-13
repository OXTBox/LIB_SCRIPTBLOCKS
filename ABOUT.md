Friday, November 13, 2026
**LIB_SCRIPTBLOCKS**: ScriptBlocks

**What it is built to do:** cut any LiveCode stack's scripts into blocks of related handlers (by
category) and generic scripts per object type, let you browse and edit all of them in one window,
and export the ones you want as a library, without anything running or any stack editing itself.

**How:**
- `python3 -I tools/harvest_blocks.py <harvest folder>` makes the blocks (into LIB_GENERICA/Data/Example).
- Open `livecode/ScriptBlocks.livecodescript`; click an example on the left.
- Edit, then **Save**; **Check** to compile without running; **Find** to filter.
- **Replace in all** changes every example at once (a backup is made first).
- **Export** writes blocks into `exports/<name>.livecodescript`; **Apply** puts one on an object (it asks first).

**How to report:** the status line at the bottom says what happened; tell Claude the file and what looked wrong.
