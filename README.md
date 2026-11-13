# LIB_SCRIPTBLOCKS

**Harvest, manage and export script blocks.** GAD's script-block system (handlers grouped by
category, one click away) made its own stack and library, so no running game ever has to edit
its own source (the owner, 2026-11-13: "it should be its own harvest/manage/and export stack/lib").

| Part | What | Where |
|---|---|---|
| **Harvest** | any stack's scripts (an XTJSON harvest) cut into **blocks** by handler-name category (GAD's `CollectScriptToBlocks`: Clear, Global, Init, Define, Set, Get, Create, Adjust, Update, Refresh, UI, Base, Mobile, GameObject, Math, String, List, Menu, Mouse, Player, RawKey, Select, Toggle, Tool, Turn, Utility, View, Script; the rest to Utility) and into **generic object scripts** by type (button, card, field, graphic, group, ...), identical scripts once | `tools/harvest_blocks.py` |
| **Manage** | browse every block and object script; edit; Save; Check (compile on a hidden scratch button, nothing runs); Find; **Replace in all** (every example at once, backup first); Apply (makes one the real script of an object you name, after a confirm) | `livecode/ScriptBlocks.livecodescript` |
| **Export** | the open example, or whole blocks by category, as a script-only library file | Export button -> `exports/<name>.livecodescript` |
| **The examples** | the data itself: INACTIVE plain text with a `--` header | `~/projects/LIB_GENERICA/Data/Example/` (`INDEX.md`, `index.tsv`) |

Everything is **inactive** until applied on purpose: the examples are `.txt`, exports are files
nobody uses until they choose to.

## Use

```bash
python3 -I tools/harvest_blocks.py ~/projects/XTJSON/batch/GAD_WORKING_03_16_2026 [more harvests] [--out FOLDER]
```
Then open `livecode/ScriptBlocks.livecodescript` in LiveCode (IDE or the LIB_MCP standalone).

## Next (LIB_SYSTEM TODO A-64, A-65, A-73)

- **Live stacks:** harvest the blocks of an open stack through LIB_MCP, not only from a harvest.
- **Developer tools from GAD, done safely:** insert a global, build `initNewGlobals` (Generica's
  `b`/`i`/`f`/`s` prefix defaults), add or remove trace codes (`ops.setDebug "00025 ..."`), compare
  blocks with a stack script. They edit OTHER stacks or script files, with a backup before every
  write, never their own source. GAD's bugs are fixed on the way (`LIB_GAD/GAD_SELF_WRITING_SCRIPTS.md`).
- **Block palette view:** the categories as a row of buttons, like GAD's `scriptBlocks` group.
