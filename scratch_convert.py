import sys

def convert_to_telugu(text):
    result = []
    for char in text:
        code = ord(char)
        if 0x0901 <= code <= 0x094F:
            result.append(chr(code + 0x0300))
        else:
            result.append(char)
    return "".join(result)

if __name__ == "__main__":
    with open("d:\\bharatheeyamapp sample\\lib\\core\\prediction_shlokas.dart", "r", encoding="utf-8") as f:
        content = f.read()
    
    # Rename maps
    content = content.replace("planetInHouseShloka", "planetInHouseShlokasTe")
    content = content.replace("mahadashaShloka", "mahadashaShlokasTe")
    content = content.replace("lordInHouseShloka", "lordInHouseShlokasTe")
    
    telugu_content = convert_to_telugu(content)
    
    with open("d:\\bharatheeyamapp sample\\lib\\core\\prediction_shlokas_te.dart", "w", encoding="utf-8") as f:
        f.write(telugu_content)
    
    print("Conversion complete.")
