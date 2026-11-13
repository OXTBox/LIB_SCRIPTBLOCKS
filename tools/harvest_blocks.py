#!/usr/bin/env python3
"""harvest_blocks.py (LIB_SCRIPTBLOCKS) - a stack's scripts (XTJSON harvest) -> INACTIVE generic script
examples, the way GAD's CollectScriptToBlocks cuts them. Default output: ~/projects/LIB_GENERICA/Data/Example

    python3 -I tools/harvest_blocks.py HARVEST [HARVEST ...] [--out FOLDER]

  Data/Example/scriptBlocks/<Category>.txt   the stack script's handlers by name prefix, GAD's
                                             categories (Clear, Global, Init, Define, Set, Get,
                                             Create, Adjust, Update, Refresh, UI, Base, Mobile,
                                             GameObject, Math, String, List, Menu, Mouse, Player,
                                             RawKey, Select, Toggle, Tool, Turn, Utility, View,
                                             Script); handlers no category takes go to Utility
  Data/Example/objects/<type>/<name>.txt     each object's script, by object type (button, card,
                                             field, graphic, group, ...), identical scripts once
  Data/Example/INDEX.md, index.tsv           what is where (the editor reads index.tsv)

Every file is plain text with a '--' header: it is NOT a script of anything until someone
applies it on purpose (the editor's Apply button, after a check). A second harvest adds to the
same folders; a block file gets one section per source.
"""
import glob, hashlib, json, os, re, sys

OUT = os.path.expanduser('~/projects/LIB_GENERICA/Data/Example')     # where the examples live (LIB_GENERICA)
# GAD_WORKING's CollectScriptToBlocks, both rows, in its order
CATEGORIES = ('Clear,Global,Init,Define,Set,Get,Create,Adjust,Update,Refresh,'
              'UI,Base,Mobile,GameObject,Math,String,List,Menu,Mouse,Player,RawKey,Select,'
              'Toggle,Tool,Turn,Utility,View,Script').split(',')
START = re.compile(r'^\s*(?:private\s+)?(on|function|command|getprop|setprop|before|after)\s+([\w.]+)', re.I)


def handlers(script):
    """[(name, kind, text)] in order; comment lines directly above a handler go with it."""
    lines = script.replace('\r\n', '\n').replace('\r', '\n').split('\n')
    out, i = [], 0
    while i < len(lines):
        m = START.match(lines[i])
        if not m:
            i += 1
            continue
        name, kind = m.group(2), m.group(1).lower()
        j = i
        while j > 0 and lines[j - 1].strip().startswith(('--', '#')) and not START.match(lines[j - 1]):
            j -= 1
        end = re.compile(r'^\s*end\s+' + re.escape(name) + r'(?![\w.])', re.I)
        k = i + 1
        while k < len(lines) and not end.match(lines[k]) and not START.match(lines[k]):
            k += 1
        if k < len(lines) and START.match(lines[k]):
            # no 'end <name>' line before the next handler: it ends here (noted in its text)
            out.append((name, kind, '\n'.join(lines[j:k]).rstrip('\n') + '\n-- (no "end %s" line in the source)' % name))
            i = k
            continue
        out.append((name, kind, '\n'.join(lines[j:k + 1])))
        i = k + 1
    return out


def category(name):
    low = name.lower()
    for c in sorted(CATEGORIES, key=len, reverse=True):      # GameObject before Game..., etc.
        if low.startswith(c.lower()):
            return c
    return 'Utility'


def objects(harvest):
    st = json.load(open(glob.glob(os.path.join(harvest, 'stack_*.json'))[0], encoding='utf-8'))

    def walk(node):
        yield node
        for c in node.get('cards', []):
            yield from walk(c)
        for c in node.get('controls', []):
            yield from walk(c)
    for node in walk(st):
        s = node.get('script')
        if isinstance(s, dict) and s.get('file'):
            text = open(os.path.join(harvest, s['file']), encoding='utf-8', errors='replace').read()
        elif isinstance(s, str):
            text = s
        else:
            continue
        if text.strip():
            yield node, text


def safe(name):
    return re.sub(r'[^\w.-]+', '_', str(name or 'unnamed')).strip('_') or 'unnamed'


def header(lines):
    return ''.join('-- %s\n' % l for l in lines) + '-- (INACTIVE example: plain text, the script of nothing until applied on purpose)\n\n'


def main():
    global OUT
    args = [a for a in sys.argv[1:]]
    if not args or args[0] in ('-h', '--help'):
        print(__doc__)
        return
    if '--out' in args:
        i = args.index('--out')
        OUT = os.path.expanduser(args[i + 1])
        del args[i:i + 2]
    index = []
    blocks = {}
    for harvest in args:
        harvest = os.path.normpath(os.path.expanduser(harvest))
        src = os.path.basename(harvest)
        seen = {}
        for node, text in objects(harvest):
            kind = node['type']
            label = '%s "%s"%s' % (kind, node.get('name', ''), ' (id %s)' % node['id'] if node.get('id') is not None and kind != 'stack' else '')
            if kind == 'stack':
                for name, hkind, body in handlers(text):
                    blocks.setdefault(category(name), []).append((src, name, hkind, body))
            h = hashlib.sha1(text.encode('utf-8')).hexdigest()[:10]
            if h in seen:
                seen[h]['users'].append(label)
                continue
            seen[h] = {'kind': kind, 'name': safe(node.get('name') or kind), 'text': text, 'users': [label], 'hash': h}
        for h, e in seen.items():
            folder = os.path.join(OUT, 'objects', e['kind'])
            os.makedirs(folder, exist_ok=True)
            fname = '%s__%s.txt' % (e['name'], h)
            names = [n for n, _, _ in handlers(e['text'])]
            with open(os.path.join(folder, fname), 'w', encoding='utf-8') as f:
                f.write(header(['generic %s script' % e['kind'], 'source: %s' % src,
                                'used by %d object(s): %s' % (len(e['users']), '; '.join(e['users'][:6]) + (' ...' if len(e['users']) > 6 else '')),
                                'handlers: %s' % ', '.join(names)]))
                f.write(e['text'].replace('\r\n', '\n').replace('\r', '\n').rstrip('\n') + '\n')
            index.append(('objects/%s/%s' % (e['kind'], fname), e['kind'], '', len(names), src, len(e['users'])))
    for cat, items in sorted(blocks.items()):
        folder = os.path.join(OUT, 'scriptBlocks')
        os.makedirs(folder, exist_ok=True)
        with open(os.path.join(folder, cat + '.txt'), 'w', encoding='utf-8') as f:
            srcs = sorted({s for s, _, _, _ in items})
            f.write(header(['script block: %s (handlers whose names start with "%s"; GAD scriptBlocks)' % (cat, cat),
                            'source: %s' % ', '.join(srcs), 'handlers: %d' % len(items)]))
            for src in srcs:
                f.write('------------------------------------------------------------ from %s\n\n' % src)
                for s, name, hkind, body in items:
                    if s == src:
                        f.write(body.rstrip('\n') + '\n\n')
        index.append(('scriptBlocks/%s.txt' % cat, 'block', cat, len(items), ', '.join(sorted({s for s, _, _, _ in items})), 1))
    with open(os.path.join(OUT, 'index.tsv'), 'w', encoding='utf-8') as f:
        f.write('file\tkind\tcategory\thandlers\tsource\tusers\n')
        for row in sorted(index):
            f.write('\t'.join(str(x) for x in row) + '\n')
    with open(os.path.join(OUT, 'INDEX.md'), 'w', encoding='utf-8') as f:
        f.write('# Data/Example: generic scripts (INACTIVE)\n\nMade by `LIB_SCRIPTBLOCKS/tools/harvest_blocks.py` from: %s.\n'
                'Plain text: none of these is the script of anything until applied on purpose\n'
                '(`LIB_SCRIPTBLOCKS/livecode/ScriptBlocks.livecodescript`: Check, then Apply).\n\n'
                '| file | kind | handlers | users |\n|---|---|---|---|\n' % ', '.join(os.path.basename(os.path.normpath(a)) for a in args))
        for row in sorted(index):
            f.write('| `%s` | %s | %s | %s |\n' % (row[0], row[1] if row[1] != 'block' else 'block: ' + row[2], row[3], row[5]))
    print('%d files (%d blocks, %d object scripts) -> %s' % (len(index), sum(1 for r in index if r[1] == 'block'),
                                                            sum(1 for r in index if r[1] != 'block'), OUT))


if __name__ == '__main__':
    main()
