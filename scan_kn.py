"""Scan for remaining hardcoded Kannada strings in dashboard_screen.dart."""
import sys, io, re
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

with open(r'd:\bharatheeyamapp sample\lib\screens\dashboard_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

skip = ['.l(', 'isHi', 'appRashi', 'appNak', 'appPlanet', 'planetOrder', 
        'knRashi', 'sphutas', 'formatDeg', 'case ', 'return ', '_selAro', 'planets[']

for i, line in enumerate(lines):
    # Check for Kannada characters (U+0C80 to U+0CFF range)
    has_kannada = any(0x0C80 <= ord(c) <= 0x0CFF for c in line)
    if not has_kannada:
        continue
    if any(s in line for s in skip):
        continue
    print(f'Line {i+1}: {line.strip()[:100]}')
