"""Fix: Add keys to correct language maps by finding pdfCreating within each map section."""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

path = r'd:\bharatheeyamapp sample\lib\widgets\common.dart'

# First, undo the mess: remove all incorrectly added keys
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Remove lines containing our new keys that were wrongly inserted
new_key_markers = ["'recalculating':", "'recalcBtn':", "'savedSuccess':", "'aroodhaChakra':",
                   "'addNoteHint':", "'noteSaved':", "'pdfThemeSelect':", "'createPatrike':",
                   "'patrikeDesc':", "'familyDetails':"]

cleaned = []
for line in lines:
    if any(m in line for m in new_key_markers):
        continue  # skip wrongly added lines
    cleaned.append(line)

# Now find each language map's pdfCreating line
new_keys = {
    'kn': [
      "      'recalculating': 'ಕುಂಡಲಿ ಮರು ಲೆಕ್ಕಿಸಲಾಗುತ್ತಿದೆ...', 'calcFailed': 'ಕುಂಡಲಿ ಲೆಕ್ಕ ವಿಫಲ',\n",
      "      'recalcBtn': 'ಮರು ಲೆಕ್ಕಿಸಿ', 'addPerson': 'ವ್ಯಕ್ತಿ ಸೇರಿಸಿ',\n",
      "      'savedSuccess': 'ಜಾತಕವನ್ನು ಉಳಿಸಲಾಗಿದೆ!', 'loadingPrastuta': 'ಪ್ರಸ್ತುತ-ಕಾಲದ ಚಕ್ರವನ್ನು ಲೋಡ ಮಾಡಲಾಗುತ್ತಿದೆ...',\n",
      "      'aroodhaChakra': 'ಆರೂಢ ಚಕ್ರ', 'addNoteHint': 'ಹೊಸ ಟಿಪ್ಪಣಿ ಸೇರಿಸಿ...',\n",
      "      'noteSaved': 'ಟಿಪ್ಪಣಿ ಉಳಿಸಲಾಗಿದೆ', 'printPreview': 'ಪ್ರಿಂಟ್ ಪ್ರಿವ್ಯೂ', 'oldNote': 'ಹಳೆಯ ಟಿಪ್ಪಣಿ',\n",
      "      'pdfThemeSelect': 'PDF ಥೀಮ್ ಆಯ್ಕೆ', 'pdfThemeDesc': 'ಪತ್ರಿಕೆಯ ವಿನ್ಯಾಸ ಮತ್ತು ಬಣ್ಣ ಬದಲಾಯಿಸಿ',\n",
      "      'createPatrike': 'ಜನ್ಮ ಪತ್ರಿಕೆ ರಚಿಸಿ',\n",
      "      'patrikeDesc': 'ಸಾಂಪ್ರದಾಯಿಕ ಶೈಲಿಯ ಜನ್ಮ ಪತ್ರಿಕೆಯನ್ನು PDF ರೂಪದಲ್ಲಿ ಪ್ರಿಂಟ್ ಮಾಡಲು ಈ ಕೆಳಗಿನ ವಿವರಗಳನ್ನು ತುಂಬಿ.',\n",
      "      'familyDetails': 'ಕುಟುಂಬದ ವಿವರ', 'fatherName': 'ತಂದೆಯ ಹೆಸರು', 'motherName': 'ತಾಯಿಯ ಹೆಸರು',\n",
    ],
    'hi': [
      "      'recalculating': 'कुंडली पुनः गणना हो रही है...', 'calcFailed': 'कुंडली गणना विफल',\n",
      "      'recalcBtn': 'पुनः गणना करें', 'addPerson': 'व्यक्ति जोड़ें',\n",
      "      'savedSuccess': 'जातक सहेजा गया!', 'loadingPrastuta': 'प्रस्तुत-काल चक्र लोड हो रहा है...',\n",
      "      'aroodhaChakra': 'आरूढ़ चक्र', 'addNoteHint': 'नया नोट जोड़ें...',\n",
      "      'noteSaved': 'नोट सहेजा गया', 'printPreview': 'प्रिंट प्रीव्यू', 'oldNote': 'पुराना नोट',\n",
      "      'pdfThemeSelect': 'PDF थीम चुनें', 'pdfThemeDesc': 'पत्रिका की शैली और रंग बदलें',\n",
      "      'createPatrike': 'जन्म पत्रिका बनाएं',\n",
      "      'patrikeDesc': 'पारंपरिक शैली की जन्म पत्रिका PDF में प्रिंट करने के लिए नीचे विवरण भरें.',\n",
      "      'familyDetails': 'परिवार विवरण', 'fatherName': 'पिता का नाम', 'motherName': 'माता का नाम',\n",
    ],
    'ta': [
      "      'recalculating': 'ஜாதகம் மறுகணக்கிடப்படுகிறது...', 'calcFailed': 'ஜாதக கணக்கீடு தோல்வி',\n",
      "      'recalcBtn': 'மறுகணக்கிடு', 'addPerson': 'நபர் சேர்',\n",
      "      'savedSuccess': 'ஜாதகம் சேமிக்கப்பட்டது!', 'loadingPrastuta': 'நடப்பு கால சக்கரம் ஏற்றப்படுகிறது...',\n",
      "      'aroodhaChakra': 'ஆரூட சக்கரம்', 'addNoteHint': 'புதிய குறிப்பு சேர்...',\n",
      "      'noteSaved': 'குறிப்பு சேமிக்கப்பட்டது', 'printPreview': 'அச்சு முன்னோட்டம்', 'oldNote': 'பழைய குறிப்பு',\n",
      "      'pdfThemeSelect': 'PDF தீம் தேர்வு', 'pdfThemeDesc': 'பத்திரிகை வடிவமைப்பு மற்றும் நிறம் மாற்று',\n",
      "      'createPatrike': 'ஜன்ம பத்ரிகை உருவாக்கு',\n",
      "      'patrikeDesc': 'பாரம்பரிய பாணியில் ஜன்ம பத்ரிகையை PDF-ல் அச்சிட கீழே விவரங்களை நிரப்பு.',\n",
      "      'familyDetails': 'குடும்ப விவரம்', 'fatherName': 'தந்தை பெயர்', 'motherName': 'தாய் பெயர்',\n",
    ],
    'te': [
      "      'recalculating': 'కుండలి మళ్ళీ లెక్కిస్తున్నారు...', 'calcFailed': 'కుండలి లెక్క విఫలం',\n",
      "      'recalcBtn': 'మళ్ళీ లెక్కించు', 'addPerson': 'వ్యక్తి చేర్చు',\n",
      "      'savedSuccess': 'జాతకం సేవ్ అయింది!', 'loadingPrastuta': 'ప్రస్తుత-కాల చక్రం లోడ్ అవుతోంది...',\n",
      "      'aroodhaChakra': 'ఆరూఢ చక్రం', 'addNoteHint': 'కొత్త నోట్ చేర్చు...',\n",
      "      'noteSaved': 'నోట్ సేవ్ అయింది', 'printPreview': 'ప్రింట్ ప్రివ్యూ', 'oldNote': 'పాత నోట్',\n",
      "      'pdfThemeSelect': 'PDF థీమ్ ఎంచుకోండి', 'pdfThemeDesc': 'పత్రిక డిజైన్ మరియు రంగు మార్చు',\n",
      "      'createPatrike': 'జన్మ పత్రిక రచించు',\n",
      "      'patrikeDesc': 'సంప్రదాయ శైలి జన్మ పత్రికను PDF లో ప్రింట్ చేయడానికి క్రింది వివరాలు నింపండి.',\n",
      "      'familyDetails': 'కుటుంబ వివరాలు', 'fatherName': 'తండ్రి పేరు', 'motherName': 'తల్లి పేరు',\n",
    ],
    'ml': [
      "      'recalculating': 'ജാതകം വീണ്ടും കണക്കാക്കുന്നു...', 'calcFailed': 'ജാതക കണക്ക് പരാജയം',\n",
      "      'recalcBtn': 'വീണ്ടും കണക്കാക്കുക', 'addPerson': 'വ്യക്തി ചേർക്കുക',\n",
      "      'savedSuccess': 'ജാതകം സേവ് ചെയ്തു!', 'loadingPrastuta': 'പ്രസ്തുത-കാല ചക്രം ലോഡ് ചെയ്യുന്നു...',\n",
      "      'aroodhaChakra': 'ആരൂഢ ചക്രം', 'addNoteHint': 'പുതിയ കുറിപ്പ് ചേർക്കുക...',\n",
      "      'noteSaved': 'കുറിപ്പ് സേവ് ചെയ്തു', 'printPreview': 'പ്രിന്റ് പ്രിവ്യൂ', 'oldNote': 'പഴയ കുറിപ്പ്',\n",
      "      'pdfThemeSelect': 'PDF തീം തിരഞ്ഞെടുക്കുക', 'pdfThemeDesc': 'പത്രികയുടെ ഡിസൈൻ, നിറം മാറ്റുക',\n",
      "      'createPatrike': 'ജന്മ പത്രിക നിർമ്മിക്കുക',\n",
      "      'patrikeDesc': 'പരമ്പരാഗത ശൈലിയിൽ ജന്മ പത്രിക PDF ആയി പ്രിന്റ് ചെയ്യാൻ താഴെ വിവരങ്ങൾ പൂരിപ്പിക്കുക.',\n",
      "      'familyDetails': 'കുടുംബ വിവരം', 'fatherName': 'അച്ഛന്റെ പേര്', 'motherName': 'അമ്മയുടെ പേര്',\n",
    ],
}

# Map identifiers to find each section
lang_markers = {
    'kn': "'appName': 'ಭಾರತೀಯಮ್'",
    'hi': "'appName': 'भारतीयम्'",
    'ta': "'appName': 'பாரதீயம்'",
    'te': "'appName': 'భారతీయమ్'",
    'ml': "'appName': 'ഭാരതീയം'",
}

result = []
i = 0
while i < len(cleaned):
    line = cleaned[i]
    result.append(line)
    
    # Check if this line has pdfCreating
    if "'pdfCreating':" in line:
        # Figure out which language map we're in by scanning backwards
        for lang, marker in lang_markers.items():
            # Search backwards from current position
            for j in range(i, max(i-120, 0), -1):
                if marker in cleaned[j]:
                    # Insert the keys for this language
                    for key_line in new_keys[lang]:
                        result.append(key_line)
                    print(f"  Inserted {lang} keys after line {i+1}")
                    break
            else:
                continue
            break
    i += 1

with open(path, 'w', encoding='utf-8', newline='') as f:
    f.writelines(result)

print(f"\nDone. Lines: {len(cleaned)} -> {len(result)}")
