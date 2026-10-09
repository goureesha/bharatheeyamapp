import re

def devanagari_to_tamil(text):
    mapping = {
        'अ': 'அ', 'आ': 'ஆ', 'इ': 'இ', 'ई': 'ஈ', 'उ': 'உ', 'ऊ': 'ஊ', 'ऋ': 'ரு',
        'ए': 'ஏ', 'ऐ': 'ஐ', 'ओ': 'ஓ', 'औ': 'ஔ',
        'क': 'க', 'ख': 'க', 'ग': 'க', 'घ': 'க', 'ङ': 'ங',
        'च': 'ச', 'छ': 'ச', 'ज': 'ஜ', 'झ': 'ஜ', 'ञ': 'ஞ',
        'ट': 'ட', 'ठ': 'ட', 'ड': 'ட', 'ढ': 'ட', 'ण': 'ண',
        'त': 'த', 'थ': 'த', 'द': 'த', 'ध': 'த', 'न': 'ந',
        'प': 'ப', 'फ': 'ப', 'ब': 'ப', 'भ': 'ப', 'म': 'ம',
        'य': 'ய', 'र': 'ர', 'ल': 'ல', 'व': 'வ',
        'श': 'ஶ', 'ष': 'ஷ', 'स': 'ஸ', 'ह': 'ஹ',
        'ळ': 'ள',
        'ा': 'ா', 'ि': 'ி', 'ी': 'ீ', 'ु': 'ு', 'ू': 'ூ',
        'े': 'ே', 'ै': 'ை', 'ो': 'ோ', 'ौ': 'ௌ',
        'ं': 'ம்', 'ः': 'ஃ', '्': '்',
        'ऽ': 'ऽ', '।': '।', '॥': '॥'
    }
    
    # special handling for ृ
    text = text.replace('ृ', '்ரு')

    res = ''
    for char in text:
        if char in mapping:
            res += mapping[char]
        else:
            res += char
            
    # Fix ன் (na) for word ends and inner conjuncts
    # A simple pass: replace ந் at the end of word with ன்
    res = re.sub(r'ந்(\s|$)', r'ன்\1', res)
    return res

with open(r"d:\bharatheeyamapp sample\lib\core\prediction_shlokas.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Replace Map names
content = content.replace('planetInHouseShloka', 'planetInHouseShlokasTa')
content = content.replace('mahadashaShloka', 'mahadashaShlokasTa')
content = content.replace('lordInHouseShloka', 'lordInHouseShlokasTa')

# Find all Sanskrit strings and transliterate them
# They are enclosed in single quotes '...'
def replace_sanskrit(match):
    s = match.group(1)
    # Check if it has devanagari
    if any('\u0900' <= c <= '\u097F' for c in s):
        return "'" + devanagari_to_tamil(s) + "'"
    return match.group(0)

new_content = re.sub(r"'(.*?)'", replace_sanskrit, content, flags=re.DOTALL)

with open(r"d:\bharatheeyamapp sample\lib\core\prediction_shlokas_ta.dart", "w", encoding="utf-8") as f:
    f.write(new_content)
