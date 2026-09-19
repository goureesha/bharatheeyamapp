import os

file_path = r'd:\bharatheeyamapp sample\lib\core\prediction_texts_ml.dart'

planets = ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು']
planet_names_ml = ['സൂര്യൻ', 'ചന്ദ്രൻ', 'ചൊവ്വ', 'ബുധൻ', 'വ്യാഴം', 'ശുക്രൻ', 'ശനി', 'രാഹു', 'കേതു']

content = '''/// Malayalam prediction texts for Bharatheeyam app
import 'prediction_texts.dart';

const Map<String, PlanetRemedy> planetRemediesMl = {
  'ರವಿ': PlanetRemedy(
    mantra: 'ഓം സൂര്യായ നമഃ',
    gemstone: 'മാണിക്യം (Ruby)',
    charity: 'ഗോതമ്പ്, ശർക്കര, ചെമ്പ്',
    deity: 'ശിവൻ, ശ്രീരാമൻ',
    day: 'ഞായർ',
    color: 'ചുവപ്പ്',
  ),
  'ಚಂದ್ರ': PlanetRemedy(
    mantra: 'ഓം സോമായ നമഃ',
    gemstone: 'മുത്ത് (Pearl)',
    charity: 'അരി, പാൽ, വെള്ളി',
    deity: 'പാർവ്വതി ദേവി',
    day: 'തിങ്കൾ',
    color: 'വെളുപ്പ്',
  ),
  'ಕುಜ': PlanetRemedy(
    mantra: 'ഓം ഭൗമായ നമഃ',
    gemstone: 'പവിഴം (Coral)',
    charity: 'പരിപ്പ്, ചുവന്ന വസ്ത്രം',
    deity: 'സുബ്രഹ്മണ്യൻ, ഹനുമാൻ',
    day: 'ചൊവ്വ',
    color: 'ചുവപ്പ്',
  ),
  'ಬುಧ': PlanetRemedy(
    mantra: 'ഓം ബുധായ നമഃ',
    gemstone: 'മരതകം (Emerald)',
    charity: 'ചെറുപയർ, പച്ച വസ്ത്രം',
    deity: 'വിഷ്ണു',
    day: 'ബുധൻ',
    color: 'പച്ച',
  ),
  'ಗುರು': PlanetRemedy(
    mantra: 'ഓം ഗുരവേ നമഃ',
    gemstone: 'മഞ്ഞ പുഷ്യരാഗം (Yellow Sapphire)',
    charity: 'കടല, മഞ്ഞ വസ്ത്രം',
    deity: 'ദക്ഷിണാമൂർത്തി, ദത്താത്രേയൻ',
    day: 'വ്യാഴം',
    color: 'മഞ്ഞ',
  ),
  'ಶುಕ್ರ': PlanetRemedy(
    mantra: 'ഓം ശുക്രായ നമഃ',
    gemstone: 'വജ്രം (Diamond)',
    charity: 'അരി, പഞ്ചസാര, വെള്ള വസ്ത്രം',
    deity: 'മഹാലക്ഷ്മി',
    day: 'വെള്ളി',
    color: 'വെള്ള, പിങ്ക്',
  ),
  'ಶನಿ': PlanetRemedy(
    mantra: 'ഓം ശനൈശ്ചര്യായ നമഃ',
    gemstone: 'ഇന്ദ്രനീലം (Blue Sapphire)',
    charity: 'എള്ള്, കറുത്ത വസ്ത്രം, ഇരുമ്പ്',
    deity: 'ശാസ്താവ്, ഹനുമാൻ',
    day: 'ശനി',
    color: 'കറുപ്പ്, കടും നീല',
  ),
  'ರಾಹು': PlanetRemedy(
    mantra: 'ഓം രാഹവേ നമഃ',
    gemstone: 'ഗോമേദകം (Hessonite)',
    charity: 'ഉഴുന്ന്, കമ്പിളി',
    deity: 'ദുർഗ്ഗാ ദേവി',
    day: 'ശനി',
    color: 'കടും നിറങ്ങൾ',
  ),
  'ಕೇತು': PlanetRemedy(
    mantra: 'ഓം കേതവേ നമഃ',
    gemstone: 'വൈഡൂര്യം (Cats Eye)',
    charity: 'മുതിര, പലനിറത്തിലുള്ള വസ്ത്രം',
    deity: 'ഗണപതി',
    day: 'ചൊവ്വ',
    color: 'ചാര നിറം',
  ),
};

const List<BhavaInfo> bhavaInfoListMl = [
  BhavaInfo(nameKn: 'ലഗ്നം (Tanu)', significations: 'വ്യക്തിത്വം, ആരോഗ്യം, രൂപം, പ്രശസ്തി'),
  BhavaInfo(nameKn: 'ധനം (Dhana)', significations: 'കുടുംബം, സംസാരം, സമ്പാദ്യം, കണ്ണുകൾ'),
  BhavaInfo(nameKn: 'സഹജം (Sahaja)', significations: 'ധൈര്യം, ഇളയ സഹോദരങ്ങൾ, ആശയവിനിമയം'),
  BhavaInfo(nameKn: 'സുഖം (Sukha)', significations: 'അമ്മ, സ്വത്ത്, വാഹനങ്ങൾ, സമാധാനം'),
  BhavaInfo(nameKn: 'പുത്രം (Putra)', significations: 'വിദ്യാഭ്യാസം, ബുദ്ധി, കുട്ടികൾ, പൂർവ്വപുണ്യങ്ങൾ'),
  BhavaInfo(nameKn: 'ശത്രു (Ripu)', significations: 'രോഗം, കടം, ശത്രുക്കൾ, മത്സരം'),
  BhavaInfo(nameKn: 'കളത്രം (Kalatra)', significations: 'വിവാഹം, പങ്കാളിത്തം, ബിസിനസ്സ്'),
  BhavaInfo(nameKn: 'ആയുസ്സ് (Ayu)', significations: 'ആയുസ്സ്, തടസ്സങ്ങൾ, പെട്ടെന്നുള്ള ലാഭനഷ്ടങ്ങൾ'),
  BhavaInfo(nameKn: 'ഭാഗ്യം (Bhagya)', significations: 'ഭാഗ്യം, ധർമ്മം, അച്ഛൻ, ഗുരു, തീർത്ഥാടനം'),
  BhavaInfo(nameKn: 'കർമ്മം (Karma)', significations: 'തൊഴിൽ, പദവി, അധികാരം, പ്രശസ്തി'),
  BhavaInfo(nameKn: 'ലാഭം (Labha)', significations: 'വരുമാനം, ലാഭം, ആഗ്രഹങ്ങൾ, മൂത്ത സഹോദരങ്ങൾ'),
  BhavaInfo(nameKn: 'വ്യയം (Vyaya)', significations: 'നഷ്ടങ്ങൾ, മോക്ഷം, വിദേശവാസം, ആശുപത്രി'),
];

const Map<String, List<String>> planetInHousePhalaMl = {
'''

for i, planet in enumerate(planets):
    content += f"  '{planet}': [\n"
    for house in range(1, 13):
        ml_planet = planet_names_ml[i]
        text = f"{house} ആം ഭാവത്തിൽ {ml_planet} നിൽക്കുന്നത് പ്രധാനപ്പെട്ട ഫലങ്ങൾ നൽകുന്നു. ഇത് ജീവിതത്തിൽ പല മാറ്റങ്ങൾക്കും കാരണമാകാം. സാമ്പത്തികവും മാനസികവുമായ കാര്യങ്ങളിൽ ശ്രദ്ധിക്കണം. സ്വന്തം പരിശ്രമത്തിലൂടെ വിജയം കൈവരിക്കാൻ സാധിക്കും."
        content += f"    '{text}',\n"
    content += "  ],\n"

content += "};\n\n"

content += "const List<List<String>> lordInHousePhalaMl = [\n"
for i in range(1, 13):
    content += "  [\n"
    for j in range(1, 13):
        text = f"{i} ആം ഭാവാധിപൻ {j} ആം ഭാവത്തിൽ നിൽക്കുന്നത് സമ്മിശ്ര ഫലങ്ങൾ നൽകും. ജീവിതത്തിൽ പുതിയ അവസരങ്ങൾ വന്നുചേരും. കഠിനാധ്വാനത്തിലൂടെ പുരോഗതി നേടാൻ കഴിയും."
        content += f"    '{text}',\n"
    content += "  ],\n"
content += "];\n\n"

content += "const Map<String, String> mahadashaPhalasMl = {\n"
for i, planet in enumerate(planets):
    ml_planet = planet_names_ml[i]
    text = f"{ml_planet} മഹാദശയിൽ ജീവിതത്തിൽ അനുകൂലവും പ്രതികൂലവുമായ ഫലങ്ങൾ ഉണ്ടാകാം. ഈ സമയത്ത് ഈശ്വരപ്രാർത്ഥനകൾ നടത്തുന്നത് നല്ലതാണ്. ആരോഗ്യം ശ്രദ്ധിക്കേണ്ടതുണ്ട്."
    content += f"  '{planet}': '{text}',\n"
content += "};\n\n"

content += "const Map<String, Map<String, String>> dashaBhuktiPhalasMl = {\n"
for i, p1 in enumerate(planets):
    content += f"  '{p1}': {{\n"
    for j, p2 in enumerate(planets):
        ml_p1 = planet_names_ml[i]
        ml_p2 = planet_names_ml[j]
        text = f"{ml_p1} ദശയിൽ {ml_p2} അപഹാരം നടക്കുമ്പോൾ സാമ്പത്തിക കാര്യങ്ങളിൽ ശ്രദ്ധിക്കണം. കുടുംബത്തിൽ സമാധാനം ഉണ്ടാകും. പൊതുവേ അനുകൂല സമയമാണ്."
        content += f"    '{p2}': '{text}',\n"
    content += "  },\n"
content += "};\n\n"

content += "const Map<String, String> dignityModifiersMl = {\n"
modifiers = ['ಉಚ್ಚ', 'ನೀಚ', 'ಸ್ವಕ್ಷೇತ್ರ', 'ಮೂಲತ್ರಿಕೋಣ', 'ವಕ್ರ', 'ಅಸ್ತ']
mod_ml = ['ഉച്ചം', 'നീചം', 'സ്വക്ഷേത്രം', 'മൂലത്രികോണം', 'വക്രം', 'മൗഢ്യം']
for k, v in zip(modifiers, mod_ml):
    text = f"ഗ്രഹത്തിന് {v} അവസ്ഥയായതിനാൽ ഫലങ്ങളിൽ മാറ്റം വരാം. ഗുണദോഷ സമ്മിശ്രമായ ഫലങ്ങൾ പ്രതീക്ഷിക്കാം."
    content += f"  '{k}': '{text}',\n"
content += "};\n"

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
