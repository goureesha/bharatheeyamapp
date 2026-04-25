"""Replace remaining hardcoded Kannada strings in dashboard_screen.dart with AppLocale.l() calls."""
import re, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

path = r'd:\bharatheeyamapp sample\lib\screens\dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    # Line ~1475: edit tooltip
    ("tooltip: 'ಬದಲಾಯಿಸಿ'", "tooltip: AppLocale.l('editTooltip')"),
    # Line ~1735: prastuta button
    ("label: Text('ಪ್ರಸ್ತುತ',", "label: Text(AppLocale.l('prastuta'),"),
    # Line ~2166, 2226: getPlanetDetail calls (internal, keep as-is — these are calculation keys not UI)
    # Line ~2284: lagna label
    ("child: Text('ಲಗ್ನ', style: TextStyle(", "child: Text(AppLocale.l('lagna'), style: TextStyle("),
    # Line ~2694-2706: notes copy block 1
    ("buf.writeln('   ✨ ${\'ಭಾರತೀಯಮ್\'} ✨');", "buf.writeln('   ✨ ${AppLocale.l(\\'appName\\')} ✨');"),
    # Simpler approach — do line-by-line replacements
]

# Do simpler exact string replacements
pairs = [
    ("tooltip: 'ಬದಲಾಯಿಸಿ'", "tooltip: AppLocale.l('editTooltip')"),
    ("label: Text('ಪ್ರಸ್ತುತ',", "label: Text(AppLocale.l('prastuta'),"),
    ("child: Text('ಲಗ್ನ', style: TextStyle(", "child: Text(AppLocale.l('lagna'), style: TextStyle("),
    # Notes share block 1 (copy)
    ("'   ✨ ${\'ಭಾರತೀಯಮ್\'} ✨'", "'   ✨ ${AppLocale.l('appName')} ✨'"),
    ("'🪪 ${\'ಐಡಿ\'}: $clientId'", "'🪪 ${AppLocale.l('idLabel')}: $clientId'"),
    ("'👤 ${\'ಹೆಸರು\'}: $name'", "'👤 ${AppLocale.l('nameLabel')}: $name'"),
    ("'📅 ${\'ಜನ್ಮ ದಿನಾಂಕ\'}: $dobStr'", "'📅 ${AppLocale.l('birthDate')}: $dobStr'"),
    ("'🕰️ ${\'ಜನ್ಮ ಸಮಯ\'}: $timeStr'", "'🕰️ ${AppLocale.l('birthTime')}: $timeStr'"),
    ("'📍 ${\'ಜನ್ಮ ಸ್ಥಳ\'}: $birthPlace\\n'", "'📍 ${AppLocale.l('birthPlace')}: $birthPlace\\n'"),
    ("'   📝 ${\'ಟಿಪ್ಪಣಿಗಳು\'}'", "'   📝 ${AppLocale.l('notesLabel')}'"),
    ("buf.writeln('ಯಾವುದೇ ಟಿಪ್ಪಣಿಗಳಿಲ್ಲ');", "buf.writeln(AppLocale.l('noNotes'));"),
    # Share button label
    ("label: Text('ಹಂಚಿಕೊಳ್ಳಿ',", "label: Text(AppLocale.l('shareLabel'),"),
    # Print button label
    ("label: Text('ಪ್ರಿಂಟ್',", "label: Text(AppLocale.l('printLabel'),"),
    # Close button in print preview
    ("child: Text('ಮುಚ್ಚಿ', style: TextStyle(color: kMuted))", "child: Text(AppLocale.l('close'), style: TextStyle(color: kMuted))"),
    # Copy & Print button
    ("label: Text('${'ನಕಲಿಸಿ'} & ${'ಪ್ರಿಂಟ್'}')", "label: Text(AppLocale.l('copyAndPrint'))"),
    # Copied message
    ("SnackBar(content: Text('ನಕಲಿಸಲಾಗಿದೆ — ಯಾವುದೇ ಟೆಕ್ಸ್ಟ್ ಎಡಿಟರ್\u200cನಲ್ಲಿ ಪೇಸ್ಟ್ ಮಾಡಿ ಪ್ರಿಂಟ್ ಮಾಡಿ ✅'))",
     "SnackBar(content: Text(AppLocale.l('copiedMsg')))"),
    # Gotra label
    ("InputDecoration(labelText: 'ಗೋತ್ರ',", "InputDecoration(labelText: AppLocale.l('gotraLabel'),"),
    # Jyotishi section header
    ("Text('ಜ್ಯೋತಿಷಿಗಳ ವಿವರ (ಪ್ರಿಂಟ್ ಮಾಡಲು)',", "Text(AppLocale.l('jyotishiSection'),"),
    # Jyotishi name
    ("InputDecoration(labelText: 'ಜ್ಯೋತಿಷಿಗಳ ಹೆಸರು / ಸಂಸ್ಥೆ',", "InputDecoration(labelText: AppLocale.l('jyotishiName'),"),
    # Jyotishi phone
    ("InputDecoration(labelText: 'ಸಂಪರ್ಕ ಸಂಖ್ಯೆ',", "InputDecoration(labelText: AppLocale.l('jyotishiPhone'),"),
    # PDF print button label
    ("label: Text('PDF ಪ್ರಿಂಟ್ ಮಾಡಿ — ${selectedTheme.nameKn}',", "label: Text('${AppLocale.l('pdfPrint')} — ${selectedTheme.nameKn}',"),
    # PDF creating snackbar
    ("SnackBar(content: Text('⏳ ${selectedTheme.nameKn} ಥೀಮ್\u200cನಲ್ಲಿ PDF ಸೃಷ್ಟಿಸಲಾಗುತ್ತಿದೆ...'))",
     "SnackBar(content: Text('⏳ ${selectedTheme.nameKn} ${AppLocale.l('pdfCreating')}'))"),
    # Error in PDF section
    ("SnackBar(content: Text('❌ ${'ದೋಷ'}: $e'),", "SnackBar(content: Text('❌ ${AppLocale.l('errorLabel')}: $e'),"),
]

count = 0
for old, new in pairs:
    if old in content:
        content = content.replace(old, new)
        count += 1
        print(f"  ✓ Replaced: {old[:50]}...")
    else:
        print(f"  ✗ NOT FOUND: {old[:50]}...")

with open(path, 'w', encoding='utf-8', newline='') as f:
    f.write(content)

print(f"\nDone: {count} replacements applied.")
