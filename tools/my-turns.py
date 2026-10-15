#!/usr/bin/env python3
"""Print your own messages from Claude Code transcripts, newest session first.

Usage:  python my-turns.py [number-of-sessions]

Transcripts live under ~/.claude/projects/<url-encoded-project-path>/*.jsonl,
one file per session. This strips out everything that is not actually you:
tool results, hook output, system reminders, task notifications and slash-command
expansions all appear as "user" entries in the raw file.
"""
import json, sys, pathlib

NOISE = ('<command-', '<system-reminder', '<task-notification',
         '<local-command', '[Request interrupted', 'Stop hook feedback')

root = pathlib.Path.home() / '.claude' / 'projects'
want = int(sys.argv[1]) if len(sys.argv) > 1 else 3

files = sorted(root.rglob('*.jsonl'), key=lambda f: f.stat().st_mtime, reverse=True)
if not files:
    sys.exit(f'no transcripts under {root}')

for f in files[:want]:
    turns = []
    for line in f.open(encoding='utf-8', errors='replace'):
        try:
            d = json.loads(line)
        except Exception:
            continue
        if d.get('type') != 'user' or d.get('isMeta') or d.get('isSidechain'):
            continue
        c = d.get('message', {}).get('content')
        if isinstance(c, list):
            c = ' '.join(b.get('text', '') for b in c
                         if isinstance(b, dict) and b.get('type') == 'text')
        if not isinstance(c, str) or not c.strip():
            continue
        if c.lstrip().startswith(NOISE):
            continue
        turns.append(' '.join(c.split()))
    print(f'\n=== {f.parent.name} / {f.stem[:8]} — {len(turns)} of your turns ===')
    for t in turns:
        print(f'  - {t[:200]}')
