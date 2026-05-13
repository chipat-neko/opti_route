"""Fix les mojibakes UTF-8 residuels dans le code app + site.

Patterns cibles :
- C3 82 C2 B7 = 'A·' double-encode -> C2 B7 ('·')
- C3 A2 E2 82 AC E2 80 9D = 'a€"' double-encode em-dash -> ' - '
- C3 A2 E2 82 AC C2 A2 = 'a€¢' double-encode bullet -> '-'
- C3 A2 E2 80 A0 E2 80 99 = 'a†™' double-encode arrow -> '->'
- C3 83 C2 XX = double-encoding de char accent (XX UTF-8 cont) -> C3 XX

Usage : python scripts/fix_mojibakes.py [--dry-run]
"""
import os
import re
import sys

DRY = '--dry-run' in sys.argv

PATTERNS = [
    (b'\xc3\x82\xc2\xb7', b'\xc2\xb7'),
    (b'\xc3\xa2\xe2\x82\xac\xe2\x80\x9d', b' - '),
    (b'\xc3\xa2\xe2\x82\xac\xc2\xa2', b'-'),
    (b'\xc3\xa2\xe2\x80\xa0\xe2\x80\x99', b'->'),
]
DOUBLE_ENC_RE = re.compile(rb'\xc3\x83\xc2([\x80-\xbf])')


def fix_content(content: bytes) -> bytes:
    for pat, rep in PATTERNS:
        content = content.replace(pat, rep)
    content = DOUBLE_ENC_RE.sub(lambda m: b'\xc3' + m.group(1), content)
    return content


def main():
    total = 0
    files_touched = 0
    exts = ('.dart', '.html', '.js', '.css', '.md')
    for base in ['app/lib', 'docs/website', 'docs']:
        if not os.path.isdir(base):
            continue
        for root, _, files in os.walk(base):
            for f in files:
                if not f.endswith(exts):
                    continue
                path = os.path.join(root, f)
                with open(path, 'rb') as fh:
                    content = fh.read()
                fixed = fix_content(content)
                if fixed != content:
                    # Compte les patterns trouves
                    diff = 0
                    for pat, _ in PATTERNS:
                        diff += content.count(pat)
                    diff += len(DOUBLE_ENC_RE.findall(content))
                    total += diff
                    files_touched += 1
                    if not DRY:
                        with open(path, 'wb') as fh:
                            fh.write(fixed)
                    print(f'{"[DRY] " if DRY else ""}{path}: {diff} fix')
    print(f'\nTOTAL: {total} occurrences dans {files_touched} fichiers'
          + (' (dry-run)' if DRY else ''))


if __name__ == '__main__':
    main()
