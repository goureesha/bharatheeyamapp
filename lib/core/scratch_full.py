import re

def camel_to_title(s):
    s = re.sub(r'([A-Z])', r' \1', s)
    s = s.replace('_', ' ')
    s = s.title()
    s = s.strip()
    return s

with open('d:/bharatheeyamapp sample/lib/widgets/common.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# User mentioned lines 231-943 as the kn section, let's grab all keys from 231 to 943 to be safe,
# even if it includes hindi, it's just keys. Wait, we want to make sure we don't duplicate or miss.
# The `kn` map usually ends where `hi` begins. Let's just grab keys from 231 to 943.
kn_lines = lines[230:943]
kn_text = ''.join(kn_lines)

keys_raw = re.findall(r"'([a-zA-Z0-9_]+)': '([^']+)'", kn_text)
# remove duplicates while preserving order
keys = []
seen = set()
for k, v in keys_raw:
    if k not in seen:
        seen.add(k)
        keys.append((k, v))

kar = ["Bava", "Balava", "Kaulava", "Taitila", "Gara", "Vanija", "Bhadra (Vishti)", "Kinstughna", "Shakuni", "Chatushpada", "Naga"]
cm = ["Vaishakha", "Jyeshtha", "Ashadha", "Shravana", "Bhadrapada", "Ashvina", "Kartika", "Margashira", "Pushya", "Magha", "Phalguna", "Chaitra"]
rashi = ["Aries/Mesha", "Taurus/Vrishabha", "Gemini/Mithuna", "Cancer/Karka", "Leo/Simha", "Virgo/Kanya", "Libra/Tula", "Scorpio/Vrishchika", "Sagittarius/Dhanu", "Capricorn/Makara", "Aquarius/Kumbha", "Pisces/Meena"]
nak = ["Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra", "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni", "Uttara Phalguni", "Hasta", "Chitra", "Swati", "Vishakha", "Anuradha", "Jyeshtha", "Moola", "Purvashadha", "Uttarashadha", "Shravana", "Dhanishtha", "Shatabhisha", "Purvabhadra", "Uttarabhadra", "Revati"]
yoga = ["Vishkambha", "Priti", "Ayushman", "Saubhagya", "Shobhana", "Atiganda", "Sukarma", "Dhriti", "Shula", "Ganda", "Vriddhi", "Dhruva", "Vyaghata", "Harshana", "Vajra", "Siddhi", "Vyatipata", "Variyan", "Parigha", "Shiva", "Siddha", "Sadhya", "Shubha", "Shukla", "Brahma", "Indra", "Vaidhriti"]
bt = ["Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami", "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami", "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima", "Amavasya"]
vara = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
upa = ["Dhuma", "Vyatipata", "Parivesha", "Indrachapa", "Upaketu", "Bhrigu B.", "Bija", "Kshetra", "Yogi", "Trisphuta", "Chatusphuta", "Panchasphuta", "Prana", "Deha", "Mrityu", "Sookshma Tri."]

custom_map = {
    'appName': 'Bharatheeyam',
    'nija': 'Nija', 'adhika': 'Adhika',
    'uttarayana': 'Uttarayana', 'dakshinayana': 'Dakshinayana', 'shakaLabel': 'Shaka',
    'gatiNera': 'Direct', 'gatiVakri': 'Retrograde', 'gatiNA': 'N/A',
    'planetRavi': 'Sun', 'planetChandra': 'Moon', 'planetKuja': 'Mars', 'planetBudha': 'Mercury', 
    'planetGuru': 'Jupiter', 'planetShukra': 'Venus', 'planetShani': 'Saturn', 'planetRahu': 'Rahu', 
    'planetKetu': 'Ketu', 'planetLagna': 'Ascendant', 'planetMandi': 'Mandi', 'planetSurya': 'Sun', 'planetMangala': 'Mars',
    'shPaksha': 'Shukla Paksha', 'krPaksha': 'Krishna Paksha',
    'houdu': 'Yes', 'illa': 'No', 'anvayisadu': 'N/A',
    'vargagalu': 'Vargas', 'rashi': 'Rashi', 'hora': 'Hora', 'drekkana': 'Drekkana', 
    'navamsha': 'Navamsha', 'dvadashamsha': 'Dvadashamsha', 'trimshamsha': 'Trimshamsha',
    'koota': 'Koota', 'varna': 'Varna', 'vashya': 'Vashya', 'tara': 'Tara', 'yoni': 'Yoni', 
    'grahaMaitri': 'Graha Maitri', 'gana': 'Gana', 'bhakoot': 'Bhakoot', 'naadi': 'Naadi', 'nakshatra': 'Nakshatra',
    'dob': 'Date of Birth', 'time': 'Time of Birth', 'place': 'Place of Birth',
    'muhurtaShodhane': 'Muhurta Search', 'searchMuhurta': 'Search Muhurta',
    'settings': 'Settings', 'aboutUs': 'About Us', 'language': 'Language', 'name': 'Name',
    'calculate': 'Calculate', 'selectDate': 'Select Date', 'selectTime': 'Select Time',
    'save': 'Save', 'delete': 'Delete', 'cancel': 'Cancel', 'confirm': 'Confirm',
    'share': 'Share', 'yes': 'Yes', 'no': 'No',
    'chart': 'Chart', 'sphuta': 'Sphuta', 'bhava': 'Bhava', 'varga': 'Varga',
    'dasha': 'Dasha', 'aroodha': 'Aroodha', 'ashtakavarga': 'Ashtakavarga',
    'taranukoola': 'Taranukoola', 'matchMaking': 'Match Making', 'notes': 'Notes',
    'jpAntardashaTitle': 'Antardasha Details', 'jpAntardasha': 'Antardasha', 'jpMahaDasha': 'Mahadasha',
    'jpStart': 'Start', 'jpEnd': 'End', 'jpVargaKundaliTitle': 'Varga Kundalis', 'jpAshtakavargaTitle': 'Ashtakavarga',
    'jpShadbalaTitle': 'Shadbala Details', 'jpD1Rashi': 'D1 Rashi', 'jpD2Hora': 'D2 Hora',
    'jpD3Drekkana': 'D3 Drekkana', 'jpD9Navamsha': 'D9 Navamsha', 'jpD12Dvadasha': 'D12 Dvadashamsha',
    'jpD30Trimsha': 'D30 Trimshamsha', 'sbGraha': 'Planet', 'sbSthana': 'Sthana', 'sbDik': 'Dik',
    'sbKala': 'Kala', 'sbCheshta': 'Cheshta', 'sbNaisargika': 'Naisargika', 'sbDrik': 'Drik',
    'sbTotal': 'Total (Rupas)', 'sbRequired': 'Required', 'sbStatus': 'Status', 'sbStrong': 'Strong', 'sbWeak': 'Weak',
    'noMuhurtaFound': 'No auspicious muhurta found in this month', 'selectRashi': 'Select Rashi',
    'selectMonth': 'Select Month', 'selectEvent': 'Select Event', 'avoidTime': 'Avoid Time',
    'rahuKala': 'Rahu Kala', 'vishaGhati': 'Visha Ghati', 'sunrise': 'Sunrise', 'sunset': 'Sunset',
    'searchPlace': 'Search Place', 'shadbalNoData': 'Shadbala data not available', 'shadbala': 'Shadbala',
    'shadbalDesc': 'Six types of planetary strengths are given in Rupas. Each planet needs a specific minimum strength (Shadbala Pinda).',
    'graha': 'Planet', 'sthana': 'Sthana', 'dik': 'Dik', 'kaala': 'Kala', 'cheshta': 'Cheshta', 'naisargika': 'Naisargika',
    'drik': 'Drik', 'ottu': 'Total', 'arhate': 'Required', 'phalitamsha': 'Result', 'balashali': 'Strong', 'durbala': 'Weak',
    'sarvashtaka': 'Sarvashtaka', 'sarvashtakaVarga': 'Sarvashtaka Varga', 'binduVitarane': 'Bindu Distribution',
    'grahaBinuSaramsha': 'Planet Bindu Summary', 'grahaSampurnaVivara': 'Complete Planet Details', 'mulaVivara': 'Basic Details',
    'gati': 'Motion', 'asta': 'Combust', 'upaVibhagagalu': 'Sub-divisions', 'rashiDrekkana': 'Rashi Drekkana',
    'navamshaDrekkana': 'Navamsha Drekkana', 'dvadashamshaDrekkana': 'Dvadashamsha Drekkana', 'navaNavamsha': 'Nava-Navamsha',
    'padeGuna': 'Obtained Guna', 'garishThaGuna': 'Maximum Guna', 'noTransits': 'No transits', 'noRetro': 'No planets in retrograde',
    'noCombust': 'No planets are combust', 'start': 'Start', 'end': 'End',
    'jan': 'January', 'feb': 'February', 'mar': 'March', 'apr': 'April', 'may': 'May', 'jun': 'June', 'jul': 'July', 'aug': 'August', 'sep': 'September', 'oct': 'October', 'nov': 'November', 'dec': 'December'
}

out = '/// English translations for Bharatheeyam app\nconst Map<String, String> enStrings = {\n'

for k, v in keys:
    val = camel_to_title(k)
    
    if k in custom_map: val = custom_map[k]
    elif k.startswith('kar') and k[3:].isdigit(): val = kar[int(k[3:])]
    elif k.startswith('cm') and k[2:].isdigit(): val = cm[int(k[2:])]
    elif k.startswith('rashi') and k[5:].isdigit(): val = rashi[int(k[5:])]
    elif k.startswith('nak') and k[3:].isdigit(): val = nak[int(k[3:])]
    elif k.startswith('yoga') and k[4:].isdigit(): val = yoga[int(k[4:])]
    elif k.startswith('bt') and k[2:].isdigit(): val = bt[int(k[2:])]
    elif k.startswith('varaS') and k[5:].isdigit(): val = vara[int(k[5:])]
    elif k.startswith('upa') and k[3:].isdigit(): val = upa[int(k[3:])]
    
    val = val.replace("Jp ", "")
    val = val.replace("Sb ", "")
    val = val.replace("Kn ", "")
    val = val.replace("'", "\\'")
    
    out += f"  '{k}': '{val}',\n"
out += '};\n'

with open('d:/bharatheeyamapp sample/lib/core/en_translations.dart', 'w', encoding='utf-8') as f:
    f.write(out)
