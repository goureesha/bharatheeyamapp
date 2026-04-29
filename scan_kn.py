import re, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

files = [
    r'd:\bharatheeyamapp sample\lib\services\pdf_service.dart',
    r'd:\bharatheeyamapp sample\lib\services\janma_patrike_service.dart',
]

kn_pattern = re.compile(r'[\u0C80-\u0CFF]')

for filepath in files:
    print(f'\n=== {filepath.split(chr(92))[-1]} ===')
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    count = 0
    for i, line in enumerate(lines, 1):
        if kn_pattern.search(line):
            stripped = line.strip()[:160]
            if stripped.startswith('//'):
                continue
            print(f'L{i}: {stripped}')
            count += 1
    if count == 0:
        print('(no Kannada text found)')
    else:
        print(f'--- {count} lines with Kannada ---')
