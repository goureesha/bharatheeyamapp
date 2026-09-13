import re

with open('d:/bharatheeyamapp sample/lib/widgets/common.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
kn_lines = lines[230:712]
kn_text = ''.join(kn_lines)

keys = re.findall(r"'([a-zA-Z0-9_]+)': '([^']+)'", kn_text)

# We will just write a dart file where we start with English translations.
# First, mapping some common ones:
kar = ["Bava", "Balava", "Kaulava", "Taitila", "Gara", "Vanija", "Bhadra (Vishti)", "Kinstughna", "Shakuni", "Chatushpada", "Naga"]
cm = ["Vaishakha", "Jyeshtha", "Ashadha", "Shravana", "Bhadrapada", "Ashvina", "Kartika", "Margashira", "Pushya", "Magha", "Phalguna", "Chaitra"]
rashi = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
nak = ["Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra", "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni", "Uttara Phalguni", "Hasta", "Chitra", "Swati", "Vishakha", "Anuradha", "Jyeshtha", "Moola", "Purvashadha", "Uttarashadha", "Shravana", "Dhanishtha", "Shatabhisha", "Purvabhadra", "Uttarabhadra", "Revati"]
yoga = ["Vishkambha", "Priti", "Ayushman", "Saubhagya", "Shobhana", "Atiganda", "Sukarma", "Dhriti", "Shula", "Ganda", "Vriddhi", "Dhruva", "Vyaghata", "Harshana", "Vajra", "Siddhi", "Vyatipata", "Variyan", "Parigha", "Shiva", "Siddha", "Sadhya", "Shubha", "Shukla", "Brahma", "Indra", "Vaidhriti"]
bt = ["Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami", "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami", "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima", "Amavasya"]
vara = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

out = '/// English translations for Bharatheeyam app\nconst Map<String, String> enStrings = {\n'
for k, v in keys:
    val = k # Default to key for manual review or default
    if k.startswith('kar') and k[3:].isdigit(): val = kar[int(k[3:])]
    elif k.startswith('cm') and k[2:].isdigit(): val = cm[int(k[2:])]
    elif k.startswith('rashi') and k[5:].isdigit(): val = rashi[int(k[5:])]
    elif k.startswith('nak') and k[3:].isdigit(): val = nak[int(k[3:])]
    elif k.startswith('yoga') and k[4:].isdigit(): val = yoga[int(k[4:])]
    elif k.startswith('bt') and k[2:].isdigit(): val = bt[int(k[2:])]
    elif k.startswith('varaS') and k[5:].isdigit(): val = vara[int(k[5:])]
    out += f"  '{k}': '{val}',\n"
out += '};\n'

with open('d:/bharatheeyamapp sample/lib/core/en_translations_tmp.dart', 'w', encoding='utf-8') as f:
    f.write(out)
