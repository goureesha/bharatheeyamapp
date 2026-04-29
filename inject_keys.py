"""Inject settings/subscription/NTP locale keys."""
filepath = r"d:\bharatheeyamapp sample\lib\widgets\common.dart"

keys = {
    'noSubscription': {
        'kn': 'ಚಂದಾದಾರಿಕೆ ಇಲ್ಲ',
        'hi': 'कोई सदस्यता नहीं',
        'ta': 'சந்தா இல்லை',
        'te': 'చందా లేదు',
        'ml': 'സബ്‌സ്‌ക്രിപ്ഷൻ ഇല്ല',
    },
    'trialActive': {
        'kn': 'ಟ್ರಯಲ್ ಸಕ್ರಿಯ - {h} ಗಂಟೆ ಬಾಕಿ',
        'hi': 'ट्रायल सक्रिय - {h} घंटे शेष',
        'ta': 'சோதனை செயலில் - {h} மணி நேரம் மீதம்',
        'te': 'ట్రయల్ యాక్టివ్ - {h} గంటలు మిగిలి',
        'ml': 'ട്രയൽ സജീവം - {h} മണിക്കൂർ ബാക്കി',
    },
    'premiumActive': {
        'kn': 'ಪ್ರೀಮಿಯಂ ಸಕ್ರಿಯ - {days} ದಿನ ಬಾಕಿ',
        'hi': 'प्रीमियम सक्रिय - {days} दिन शेष',
        'ta': 'பிரீமியம் செயலில் - {days} நாட்கள் மீதம்',
        'te': 'ప్రీమియం యాక్టివ్ - {days} రోజులు మిగిలి',
        'ml': 'പ്രീമിയം സജീവം - {days} ദിവസം ബാക്കി',
    },
    'subExpired': {
        'kn': 'ಚಂದಾದಾರಿಕೆ ಮುಗಿದಿದೆ',
        'hi': 'सदस्यता समाप्त हो गई',
        'ta': 'சந்தா முடிந்தது',
        'te': 'చందా ముగిసింది',
        'ml': 'സബ്‌സ്‌ക്രിപ്ഷൻ കഴിഞ്ഞു',
    },
    'graceActive': {
        'kn': 'ಗ್ರೇಸ್ ಸಕ್ರಿಯ - {hrs}h ಬಾಕಿ ({used}/{max} ಬಳಸಲಾಗಿದೆ)',
        'hi': 'ग्रेस सक्रिय - {hrs}h शेष ({used}/{max} उपयोग)',
        'ta': 'கிரேஸ் செயலில் - {hrs}h மீதம் ({used}/{max} பயன்படுத்தப்பட்டது)',
        'te': 'గ్రేస్ యాక్టివ్ - {hrs}h మిగిలి ({used}/{max} వాడబడింది)',
        'ml': 'ഗ്രേസ് സജീവം - {hrs}h ബാക്കി ({used}/{max} ഉപയോഗിച്ചു)',
    },
    'graceInactive': {
        'kn': 'ಗ್ರೇಸ್ ನಿಷ್ಕ್ರಿಯ ({used}/{max} ಬಳಸಲಾಗಿದೆ)',
        'hi': 'ग्रेस निष्क्रिय ({used}/{max} उपयोग)',
        'ta': 'கிரேஸ் செயலற்றது ({used}/{max} பயன்படுத்தப்பட்டது)',
        'te': 'గ్రేస్ నిష్క్రియ ({used}/{max} వాడబడింది)',
        'ml': 'ഗ്രേസ് നിഷ്‌ക്രിയം ({used}/{max} ഉപയോഗിച്ചു)',
    },
    'ntpNotSynced': {
        'kn': 'NTP ಸಿಂಕ್ ಆಗಿಲ್ಲ',
        'hi': 'NTP सिंक नहीं हुआ',
        'ta': 'NTP ஒத்திசைக்கப்படவில்லை',
        'te': 'NTP సింక్ కాలేదు',
        'ml': 'NTP സിങ്ക് ആയിട്ടില്ല',
    },
    'timeAccurate': {
        'kn': 'ಸಮಯ ನಿಖರ',
        'hi': 'समय सटीक',
        'ta': 'நேரம் சரியானது',
        'te': 'సమయం సరిగ్గా ఉంది',
        'ml': 'സമയം കൃത്യം',
    },
    'phoneClockAhead': {
        'kn': 'ಫೋನ್ ಗಡಿಯಾರ ಮುಂದೆ',
        'hi': 'फ़ोन की घड़ी आगे',
        'ta': 'போன் கடிகாரம் முன்னால்',
        'te': 'ఫోన్ గడియారం ముందు',
        'ml': 'ഫോൺ ക്ലോക്ക് മുന്നിൽ',
    },
    'phoneClockBehind': {
        'kn': 'ಫೋನ್ ಗಡಿಯಾರ ಹಿಂದೆ',
        'hi': 'फ़ोन की घड़ी पीछे',
        'ta': 'போன் கடிகாரம் பின்னால்',
        'te': 'ఫోన్ గడియారం వెనుక',
        'ml': 'ഫോൺ ക്ലോക്ക് പിന്നിൽ',
    },
    'ntpResync': {
        'kn': 'NTP ಮರುಸಿಂಕ್ / Re-sync Clock',
        'hi': 'NTP पुनः सिंक / Re-sync Clock',
        'ta': 'NTP மறு ஒத்திசைவு / Re-sync Clock',
        'te': 'NTP రీ-సింక్ / Re-sync Clock',
        'ml': 'NTP റീ-സിങ്ക് / Re-sync Clock',
    },
    'ntpSyncSuccess': {
        'kn': 'NTP ಸಿಂಕ್ ಯಶಸ್ವಿ!',
        'hi': 'NTP सिंक सफल!',
        'ta': 'NTP ஒத்திசைவு வெற்றி!',
        'te': 'NTP సింక్ విజయవంతం!',
        'ml': 'NTP സിങ്ക് വിജയം!',
    },
    'ntpSyncFailed': {
        'kn': 'NTP ಸಿಂಕ್ ವಿಫಲ — ಇಂಟರ್ನೆಟ್ ಪರಿಶೀಲಿಸಿ',
        'hi': 'NTP सिंक विफल — इंटरनेट जाँचें',
        'ta': 'NTP ஒத்திசைவு தோல்வி — இணையம் சரிபார்க்கவும்',
        'te': 'NTP సింక్ విఫలం — ఇంటర్నెట్ తనిఖీ చేయండి',
        'ml': 'NTP സിങ്ക് പരാജയം — ഇന്റർനെറ്റ് പരിശോധിക്കുക',
    },
    'signInForBackup': {
        'kn': 'Google Drive ಬ್ಯಾಕಪ್ ಬಳಸಲು ದಯವಿಟ್ಟು ಮೊದಲು ಸೈನ್ ಇನ್ ಮಾಡಿ.',
        'hi': 'Google Drive बैकअप के लिए कृपया पहले साइन इन करें.',
        'ta': 'Google Drive காப்புப்பதிவுக்கு முதலில் உள்நுழையவும்.',
        'te': 'Google Drive బ్యాకప్ కోసం దయచేసి ముందుగా సైన్ ఇన్ చేయండి.',
        'ml': 'Google Drive ബാക്കപ്പിനായി ദയവായി ആദ്യം സൈൻ ഇൻ ചെയ്യുക.',
    },
}

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

for lang in ['kn', 'hi', 'ta', 'te', 'ml']:
    entries = []
    for key, vals in keys.items():
        val = vals[lang].replace("'", "\\'")
        entries.append(f"      '{key}': '{val}'")
    injection = ",\n".join(entries) + ","

    section_start = content.find(f"'{lang}': {{")
    brace_count = 0
    close_idx = -1
    for i in range(section_start, len(content)):
        if content[i] == '{': brace_count += 1
        elif content[i] == '}':
            brace_count -= 1
            if brace_count == 0: close_idx = i; break

    content = content[:close_idx] + "\n" + injection + "\n" + content[close_idx:]
    print(f"Injected {len(keys)} keys into {lang}")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
