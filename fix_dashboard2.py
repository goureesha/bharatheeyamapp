"""Batch-replace ALL remaining hardcoded Kannada strings in dashboard_screen.dart."""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

path = r'd:\bharatheeyamapp sample\lib\screens\dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

pairs = [
    # Batch 1 leftovers (dialogs/profile)
    ("Text('ಬೇರೆ ಪ್ರೊಫೈಲ್\u200cಗಳಿಲ್ಲ',", "Text(AppLocale.l('noOtherProfiles'),"),
    ("geoStatus = 'ಸ್ಥಳ ಕಂಡುಬಂದಿಲ್ಲ.'", "geoStatus = AppLocale.l('placeNotFoundDash')"),
    ("geoStatus = 'ಸ್ಥಳ ಸಂಪರ್ಕ ದೋಷ.'", "geoStatus = AppLocale.l('placeError')"),
    ("Text('ದಿನಾಂಕ:", "Text('${AppLocale.l('dateLabel')}:"),
    ("Text('ಸಮಯ:", "Text('${AppLocale.l('timeLabel')}:"),
    ("labelText: 'ಊರು ಹುಡುಕಿ',", "labelText: AppLocale.l('searchPlace'),"),
    ("Text('⏳ $name ಕುಂಡಲಿ ಮರು ಲೆಕ್ಕಿಸಲಾಗುತ್ತಿದೆ...')", "Text('⏳ $name ${AppLocale.l('recalculating')}')"),
    ("Text('❌ ಕುಂಡಲಿ ಲೆಕ್ಕ ವಿಫಲ'", "Text('❌ ${AppLocale.l('calcFailed')}'"),
    ("Text('✅ $name ಕುಂಡಲಿ ಯಶಸ್ವಿಯಾಗಿ ಬದಲಾಯಿಸಲಾಗಿದೆ'", "Text('✅ $name ${AppLocale.l('calcSuccess')}'"),
    ("Text('❌ ದೋಷ: $e')", "Text('❌ ${AppLocale.l('errorLabel')}: $e')"),
    ("child: Text('ಮರು ಲೆಕ್ಕಿಸಿ',", "child: Text(AppLocale.l('recalcBtn'),"),
    ("tooltip: 'ವ್ಯಕ್ತಿ ಸೇರಿಸಿ',", "tooltip: AppLocale.l('addPerson'),"),
    ("Text('✅ ಜಾತಕವನ್ನು ಉಳಿಸಲಾಗಿದೆ!", "Text('✅ ${AppLocale.l('savedSuccess')}"),
    ("label: Text('ವ್ಯಕ್ತಿ ಸೇರಿಸಿ',", "label: Text(AppLocale.l('addPerson'),"),
    ("Text('ಪ್ರಸ್ತುತ-ಕಾಲದ ಚಕ್ರವನ್ನು ಲೋಡ ಮಾಡಲಾಗುತ್ತಿದೆ...'", "Text(AppLocale.l('loadingPrastuta')"),
    ("Text('ದೋಷ: $e')", "Text('${AppLocale.l('errorLabel')}: $e')"),
    ("SectionTitle('ಆರೂಢ ಚಕ್ರ')", "SectionTitle(AppLocale.l('aroodhaChakra'))"),
    # Notes section
    ("hintText: 'ಹೊಸ ಟಿಪ್ಪಣಿ ಸೇರಿಸಿ...',", "hintText: AppLocale.l('addNoteHint'),"),
    ("Text('✅ ${\'ಟಿಪ್ಪಣಿ ಉಳಿಸಲಾಗಿದೆ\'}'),", "Text('✅ ${AppLocale.l('noteSaved')}'),"),
    ("Text('ಇನ್ನೂ ಟಿಪ್ಪಣಿಗಳಿಲ್ಲ",  "Text(AppLocale.l('noNotes')"),
    ("Text('ಪ್ರಿಂಟ್ ಪ್ರಿವ್ಯೂ',", "Text(AppLocale.l('printPreview'),"),
    ("'date': 'ಹಳೆಯ ಟಿಪ್ಪಣಿ',", "'date': AppLocale.l('oldNote'),"),
    # Janma Patrike section
    ("Text('PDF ಥೀಮ್ ಆಯ್ಕೆ',", "Text(AppLocale.l('pdfThemeSelect'),"),
    ("Text('ಪತ್ರಿಕೆಯ ವಿನ್ಯಾಸ ಮತ್ತು ಬಣ್ಣ ಬದಲಾಯಿಸಿ',", "Text(AppLocale.l('pdfThemeDesc'),"),
    ("Text('ಜನ್ಮ ಪತ್ರಿಕೆ ರಚಿಸಿ',", "Text(AppLocale.l('createPatrike'),"),
    ("'ಸಾಂಪ್ರದಾಯಿಕ ಶೈಲಿಯ ಜನ್ಮ ಪತ್ರಿಕೆಯನ್ನು PDF ರೂಪದಲ್ಲಿ ಪ್ರಿಂಟ್ ಮಾಡಲು ಈ ಕೆಳಗಿನ ವಿವರಗಳನ್ನು ತುಂಬಿ.',",
     "AppLocale.l('patrikeDesc'),"),
    ("Text('ಕುಟುಂಬದ ವಿವರ',", "Text(AppLocale.l('familyDetails'),"),
    ("labelText: 'ತಂದೆಯ ಹೆಸರು',", "labelText: AppLocale.l('fatherName'),"),
    ("labelText: 'ತಾಯಿಯ ಹೆಸರು',", "labelText: AppLocale.l('motherName'),"),
]

count = 0
for old, new in pairs:
    if old in content:
        content = content.replace(old, new)
        count += 1
        print(f"  OK: {old[:60]}...")
    else:
        print(f"  MISS: {old[:60]}...")

with open(path, 'w', encoding='utf-8', newline='') as f:
    f.write(content)

print(f"\nDone: {count} replacements applied.")
