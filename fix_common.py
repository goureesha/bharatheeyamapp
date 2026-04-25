"""Add remaining keys to all 5 language maps in common.dart."""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

path = r'd:\bharatheeyamapp sample\lib\widgets\common.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# New keys to add before closing '    },' of each map
new_keys = {
    'kn': """      'recalculating': 'ಕುಂಡಲಿ ಮರು ಲೆಕ್ಕಿಸಲಾಗುತ್ತಿದೆ...', 'calcFailed': 'ಕುಂಡಲಿ ಲೆಕ್ಕ ವಿಫಲ',
      'recalcBtn': 'ಮರು ಲೆಕ್ಕಿಸಿ', 'addPerson': 'ವ್ಯಕ್ತಿ ಸೇರಿಸಿ',
      'savedSuccess': 'ಜಾತಕವನ್ನು ಉಳಿಸಲಾಗಿದೆ!', 'loadingPrastuta': 'ಪ್ರಸ್ತುತ-ಕಾಲದ ಚಕ್ರವನ್ನು ಲೋಡ ಮಾಡಲಾಗುತ್ತಿದೆ...',
      'aroodhaChakra': 'ಆರೂಢ ಚಕ್ರ', 'addNoteHint': 'ಹೊಸ ಟಿಪ್ಪಣಿ ಸೇರಿಸಿ...',
      'noteSaved': 'ಟಿಪ್ಪಣಿ ಉಳಿಸಲಾಗಿದೆ', 'printPreview': 'ಪ್ರಿಂಟ್ ಪ್ರಿವ್ಯೂ', 'oldNote': 'ಹಳೆಯ ಟಿಪ್ಪಣಿ',
      'pdfThemeSelect': 'PDF ಥೀಮ್ ಆಯ್ಕೆ', 'pdfThemeDesc': 'ಪತ್ರಿಕೆಯ ವಿನ್ಯಾಸ ಮತ್ತು ಬಣ್ಣ ಬದಲಾಯಿಸಿ',
      'createPatrike': 'ಜನ್ಮ ಪತ್ರಿಕೆ ರಚಿಸಿ',
      'patrikeDesc': 'ಸಾಂಪ್ರದಾಯಿಕ ಶೈಲಿಯ ಜನ್ಮ ಪತ್ರಿಕೆಯನ್ನು PDF ರೂಪದಲ್ಲಿ ಪ್ರಿಂಟ್ ಮಾಡಲು ಈ ಕೆಳಗಿನ ವಿವರಗಳನ್ನು ತುಂಬಿ.',
      'familyDetails': 'ಕುಟುಂಬದ ವಿವರ', 'fatherName': 'ತಂದೆಯ ಹೆಸರು', 'motherName': 'ತಾಯಿಯ ಹೆಸರು',""",
    'hi': """      'recalculating': 'कुंडली पुनः गणना हो रही है...', 'calcFailed': 'कुंडली गणना विफल',
      'recalcBtn': 'पुनः गणना करें', 'addPerson': 'व्यक्ति जोड़ें',
      'savedSuccess': 'जातक सहेजा गया!', 'loadingPrastuta': 'प्रस्तुत-काल चक्र लोड हो रहा है...',
      'aroodhaChakra': 'आरूढ़ चक्र', 'addNoteHint': 'नया नोट जोड़ें...',
      'noteSaved': 'नोट सहेजा गया', 'printPreview': 'प्रिंट प्रीव्यू', 'oldNote': 'पुराना नोट',
      'pdfThemeSelect': 'PDF थीम चुनें', 'pdfThemeDesc': 'पत्रिका की शैली और रंग बदलें',
      'createPatrike': 'जन्म पत्रिका बनाएं',
      'patrikeDesc': 'पारंपरिक शैली की जन्म पत्रिका PDF में प्रिंट करने के लिए नीचे विवरण भरें.',
      'familyDetails': 'परिवार विवरण', 'fatherName': 'पिता का नाम', 'motherName': 'माता का नाम',""",
    'ta': """      'recalculating': 'ஜாதகம் மறுகணக்கிடப்படுகிறது...', 'calcFailed': 'ஜாதக கணக்கீடு தோல்வி',
      'recalcBtn': 'மறுகணக்கிடு', 'addPerson': 'நபர் சேர்',
      'savedSuccess': 'ஜாதகம் சேமிக்கப்பட்டது!', 'loadingPrastuta': 'நடப்பு கால சக்கரம் ஏற்றப்படுகிறது...',
      'aroodhaChakra': 'ஆரூட சக்கரம்', 'addNoteHint': 'புதிய குறிப்பு சேர்...',
      'noteSaved': 'குறிப்பு சேமிக்கப்பட்டது', 'printPreview': 'அச்சு முன்னோட்டம்', 'oldNote': 'பழைய குறிப்பு',
      'pdfThemeSelect': 'PDF தீம் தேர்வு', 'pdfThemeDesc': 'பத்திரிகை வடிவமைப்பு மற்றும் நிறம் மாற்று',
      'createPatrike': 'ஜன்ம பத்ரிகை உருவாக்கு',
      'patrikeDesc': 'பாரம்பரிய பாணியில் ஜன்ம பத்ரிகையை PDF-ல் அச்சிட கீழே விவரங்களை நிரப்பு.',
      'familyDetails': 'குடும்ப விவரம்', 'fatherName': 'தந்தை பெயர்', 'motherName': 'தாய் பெயர்',""",
    'te': """      'recalculating': 'కుండలి మళ్ళీ లెక్కిస్తున్నారు...', 'calcFailed': 'కుండలి లెక్క విఫలం',
      'recalcBtn': 'మళ్ళీ లెక్కించు', 'addPerson': 'వ్యక్తి చేర్చు',
      'savedSuccess': 'జాతకం సేవ్ అయింది!', 'loadingPrastuta': 'ప్రస్తుత-కాల చక్రం లోడ్ అవుతోంది...',
      'aroodhaChakra': 'ఆరూఢ చక్రం', 'addNoteHint': 'కొత్త నోట్ చేర్చు...',
      'noteSaved': 'నోట్ సేవ్ అయింది', 'printPreview': 'ప్రింట్ ప్రివ్యూ', 'oldNote': 'పాత నోట్',
      'pdfThemeSelect': 'PDF థీమ్ ఎంచుకోండి', 'pdfThemeDesc': 'పత్రిక డిజైన్ మరియు రంగు మార్చు',
      'createPatrike': 'జన్మ పత్రిక రచించు',
      'patrikeDesc': 'సంప్రదాయ శైలి జన్మ పత్రికను PDF లో ప్రింట్ చేయడానికి క్రింది వివరాలు నింపండి.',
      'familyDetails': 'కుటుంబ వివరాలు', 'fatherName': 'తండ్రి పేరు', 'motherName': 'తల్లి పేరు',""",
    'ml': """      'recalculating': 'ജാതകം വീണ്ടും കണക്കാക്കുന്നു...', 'calcFailed': 'ജാതക കണക്ക് പരാജയം',
      'recalcBtn': 'വീണ്ടും കണക്കാക്കുക', 'addPerson': 'വ്യക്തി ചേർക്കുക',
      'savedSuccess': 'ജാതകം സേവ് ചെയ്തു!', 'loadingPrastuta': 'പ്രസ്തുത-കാല ചക്രം ലോഡ് ചെയ്യുന്നു...',
      'aroodhaChakra': 'ആരൂഢ ചക്രം', 'addNoteHint': 'പുതിയ കുറിപ്പ് ചേർക്കുക...',
      'noteSaved': 'കുറിപ്പ് സേവ് ചെയ്തു', 'printPreview': 'പ്രിന്റ് പ്രിവ്യൂ', 'oldNote': 'പഴയ കുറിപ്പ്',
      'pdfThemeSelect': 'PDF തീം തിരഞ്ഞെടുക്കുക', 'pdfThemeDesc': 'പത്രികയുടെ ഡിസൈൻ, നിറം മാറ്റുക',
      'createPatrike': 'ജന്മ പത്രിക നിർമ്മിക്കുക',
      'patrikeDesc': 'പരമ്പരാഗത ശൈലിയിൽ ജന്മ പത്രിക PDF ആയി പ്രിന്റ് ചെയ്യാൻ താഴെ വിവരങ്ങൾ പൂരിപ്പിക്കുക.',
      'familyDetails': 'കുടുംബ വിവരം', 'fatherName': 'അച്ഛന്റെ പേര്', 'motherName': 'അമ്മയുടെ പേര്',""",
}

# Find the pdfCreating key line in each map and insert after it
for lang, keys_block in new_keys.items():
    marker = f"'pdfCreating':"
    # Find the line containing pdfCreating for this language
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if marker in line:
            # Check if next few lines belong to this lang's map
            # Insert the new keys after this line
            lines.insert(i + 1, keys_block)
            content = '\n'.join(lines)
            print(f"  Added keys after line {i+1} for {lang}")
            break

with open(path, 'w', encoding='utf-8', newline='') as f:
    f.write(content)

print("\nDone adding keys to common.dart")
