// ═══════════════════════════════════════════
// CLASSICAL JYOTISH ENHANCEMENT DATA
// Additional prediction layers from Saravali, Jataka Parijata,
// Chamatkar Chintamani, and Phaladeepika
// ═══════════════════════════════════════════

/// Karaka (significator) for each house — from BPHS & Jataka Parijata
/// Key = house number (1-12), Value = list of karaka planets (Kannada names)
const Map<int, List<String>> houseKarakas = {
  1: ['ರವಿ'],           // Sun = karaka for self, vitality
  2: ['ಗುರು'],          // Jupiter = karaka for wealth, family
  3: ['ಕುಜ'],           // Mars = karaka for courage, siblings
  4: ['ಚಂದ್ರ'],         // Moon = karaka for mother, happiness
  5: ['ಗುರು'],          // Jupiter = karaka for children, intelligence
  6: ['ಕುಜ', 'ಶನಿ'],   // Mars, Saturn = karaka for enemies, disease
  7: ['ಶುಕ್ರ'],         // Venus = karaka for marriage, partner
  8: ['ಶನಿ'],           // Saturn = karaka for longevity
  9: ['ರವಿ', 'ಗುರು'],  // Sun, Jupiter = karaka for father, dharma
  10: ['ರವಿ', 'ಶನಿ', 'ಬುಧ'], // Sun, Saturn, Mercury = karaka for career
  11: ['ಗುರು'],         // Jupiter = karaka for gains
  12: ['ಶನಿ', 'ಕೇತು'], // Saturn, Ketu = karaka for loss, moksha
};

/// Digbala (directional strength) positions
/// Planet -> house where it gets digbala (1-indexed)
const Map<String, int> digbalaHouse = {
  'ರವಿ': 10,    // Sun gets digbala in 10th house
  'ಕುಜ': 10,    // Mars gets digbala in 10th house
  'ಗುರು': 1,    // Jupiter gets digbala in 1st (Lagna)
  'ಬುಧ': 1,     // Mercury gets digbala in 1st (Lagna)
  'ಚಂದ್ರ': 4,   // Moon gets digbala in 4th house
  'ಶುಕ್ರ': 4,   // Venus gets digbala in 4th house
  'ಶನಿ': 7,     // Saturn gets digbala in 7th house
};

/// Moolatrikona signs (rashi index 0-11)
const Map<String, int> moolatrikonaSign = {
  'ರವಿ': 4,     // Leo
  'ಚಂದ್ರ': 1,   // Taurus
  'ಕುಜ': 0,     // Aries
  'ಬುಧ': 5,     // Virgo
  'ಗುರು': 8,    // Sagittarius
  'ಶುಕ್ರ': 6,   // Libra
  'ಶನಿ': 10,    // Aquarius
};

/// Karaka in own karaka house — "Karako Bhava Nashaya" principle
/// When a natural karaka sits in its own karaka house, it can cause
/// both enhancement AND damage to that house's significations (Saravali, BPHS)
const Map<String, Map<String, String>> karakaInHouseEffect = {
  'kn': {
    'boost': ' ಈ ಗ್ರಹವು ಈ ಭಾವದ ಕಾರಕನಾಗಿರುವುದರಿಂದ ಭಾವದ ವಿಷಯಗಳ ಕಡೆಗೆ ತೀವ್ರ ಒಲವು ಮತ್ತು ಸಾಧನೆಯ ಅವಕಾಶ ಇದೆ. ಆದರೆ "ಕಾರಕೋ ಭಾವ ನಾಶಾಯ" ಸೂತ್ರದಂತೆ ಅತಿಯಾದ ಪ್ರಭಾವ ಕೆಲವೊಮ್ಮೆ ಫಲವನ್ನು ಕುಗ್ಗಿಸಬಹುದು.',
    'warn': ' "ಕಾರಕೋ ಭಾವ ನಾಶಾಯ" — ಈ ಕಾರಕ ಗ್ರಹ ತನ್ನದೇ ಭಾವದಲ್ಲಿ ಕುಳಿತು ಭಾವದ ಫಲವನ್ನು ತಗ್ಗಿಸಬಹುದು. ಇತರ ಶುಭ ಗ್ರಹಗಳ ಸಂಬಂಧ ಇದ್ದರೆ ಈ ದೋಷ ಕಡಿಮೆಯಾಗುತ್ತದೆ.',
  },
  'hi': {
    'boost': ' यह ग्रह इस भाव का कारक होने से भाव के विषयों की ओर तीव्र रुझान और उपलब्धि की संभावना है। परन्तु "कारको भाव नाशाय" सूत्र के अनुसार अत्यधिक प्रभाव कभी-कभी फल को कम कर सकता है।',
    'warn': ' "कारको भाव नाशाय" — यह कारक ग्रह अपने ही भाव में बैठकर भाव के फल को कम कर सकता है। अन्य शुभ ग्रहों का संबंध हो तो यह दोष कम होता है।',
  },
  'ta': {
    'boost': ' இந்த கிரகம் இந்த பாவத்தின் காரகமாக இருப்பதால் பாவ விஷயங்களில் தீவிர ஈடுபாடும் சாதனை வாய்ப்பும் உள்ளது. ஆனால் "காரகோ பாவ நாசாய" சூத்திரப்படி அதிக பிரபாவம் சில நேரங்களில் பலனைக் குறைக்கலாம்.',
    'warn': ' "காரகோ பாவ நாசாய" — இந்த காரக கிரகம் தனது சொந்த பாவத்தில் அமர்ந்து பாவத்தின் பலனைக் குறைக்கலாம்.',
  },
  'te': {
    'boost': ' ఈ గ్రహం ఈ భావానికి కారకుడు కావడం వల్ల భావ విషయాలపై తీవ్ర ఆసక్తి మరియు సాధన అవకాశం ఉంది. అయితే "కారకో భావ నాశాయ" సూత్రం ప్రకారం అధిక ప్రభావం కొన్నిసార్లు ఫలాన్ని తగ్గించవచ్చు.',
    'warn': ' "కారకో భావ నాశాయ" — ఈ కారక గ్రహం తన సొంత భావంలో కూర్చొని భావ ఫలాన్ని తగ్గించవచ్చు.',
  },
  'ml': {
    'boost': ' ഈ ഗ്രഹം ഈ ഭാവത്തിന്റെ കാരകനായതിനാൽ ഭാവ വിഷയങ്ങളിൽ തീവ്രമായ താൽപര്യവും നേട്ടാവകാശവും ഉണ്ട്. എന്നാൽ "കാരകോ ഭാവ നാശായ" സൂത്രപ്രകാരം അമിത സ്വാധീനം ചിലപ്പോൾ ഫലം കുറയ്ക്കും.',
    'warn': ' "കാരകോ ഭാവ നാശായ" — ഈ കാരക ഗ്രഹം സ്വന്തം ഭാവത്തിൽ ഇരുന്ന് ഭാവ ഫലം കുറയ്ക്കാം.',
  },
  'en': {
    'boost': ' As the natural significator (karaka) of this house, this planet intensifies the house themes and brings strong potential for achievement. However, per the classical principle "Karako Bhava Nashaya," excessive karaka influence can sometimes diminish the house results.',
    'warn': ' "Karako Bhava Nashaya" — the natural significator placed in its own signification house may paradoxically weaken the house results. Benefic associations can mitigate this effect.',
  },
};

/// Digbala effect texts
const Map<String, Map<String, String>> digbalaEffect = {
  'kn': {
    'has': ' ಈ ಸ್ಥಾನದಲ್ಲಿ ದಿಗ್ಬಲ ಪಡೆದಿರುವುದರಿಂದ ಗ್ರಹದ ಶಕ್ತಿ ಮತ್ತು ಫಲದಾಯಕತೆ ಅತ್ಯಧಿಕ. ಸಾರವಲಿಯ ಪ್ರಕಾರ ದಿಗ್ಬಲಿ ಗ್ರಹ ತನ್ನ ಕಾರಕತ್ವವನ್ನು ಪೂರ್ಣವಾಗಿ ಪ್ರಕಟಿಸುತ್ತಾನೆ.',
    'lost': ' ಈ ಸ್ಥಾನದಲ್ಲಿ ದಿಗ್ಬಲ ಕಳೆದುಕೊಂಡಿರುವುದರಿಂದ ಗ್ರಹದ ಬಲ ದುರ್ಬಲ. ಫಲಗಳಲ್ಲಿ ಕೊರತೆ ಅನುಭವಿಸಬಹುದು.',
  },
  'hi': {
    'has': ' इस स्थान में दिग्बल प्राप्त होने से ग्रह की शक्ति और फलदायकता अत्यधिक है। सारावली के अनुसार दिग्बली ग्रह अपने कारकत्व को पूर्ण रूप से प्रकट करता है।',
    'lost': ' इस स्थान में दिग्बल खोने से ग्रह का बल दुर्बल है। फलों में कमी अनुभव हो सकती है।',
  },
  'ta': {
    'has': ' இந்த இடத்தில் திக்பலம் பெறுவதால் கிரகத்தின் சக்தியும் பலன் தரும் தன்மையும் மிக அதிகம். சாரவளியின் படி திக்பலம் பெற்ற கிரகம் தனது காரகத்துவத்தை முழுமையாக வெளிப்படுத்தும்.',
    'lost': ' இந்த இடத்தில் திக்பலம் இழப்பதால் கிரகத்தின் பலம் குறைவு.',
  },
  'te': {
    'has': ' ఈ స్థానంలో దిగ్బలం పొందడం వల్ల గ్రహం యొక్క శక్తి మరియు ఫలదాయకత అత్యధికం. సారావళి ప్రకారం దిగ్బలం పొందిన గ్రహం తన కారకత్వాన్ని పూర్తిగా ప్రకటిస్తుంది.',
    'lost': ' ఈ స్థానంలో దిగ్బలం కోల్పోవడం వల్ల గ్రహ బలం బలహీనం.',
  },
  'ml': {
    'has': ' ഈ സ്ഥാനത്ത് ദിഗ്ബലം ലഭിക്കുന്നതിനാൽ ഗ്രഹത്തിന്റെ ശക്തിയും ഫലദായകതയും അത്യധികമാണ്. സാരവാളി പ്രകാരം ദിഗ്ബലമുള്ള ഗ്രഹം തന്റെ കാരകത്വം പൂർണമായി പ്രകടിപ്പിക്കും.',
    'lost': ' ഈ സ്ഥാനത്ത് ദിഗ്ബലം നഷ്ടപ്പെട്ടതിനാൽ ഗ്രഹ ബലം ദുർബലമാണ്.',
  },
  'en': {
    'has': ' Having Digbala (directional strength) in this position, the planet\'s power and ability to deliver results is greatly amplified. According to Saravali, a planet with Digbala fully manifests its significations.',
    'lost': ' Having lost Digbala (directional strength) in this position, the planet\'s strength is weakened and results may be diminished.',
  },
};

/// Moolatrikona effect texts
const Map<String, Map<String, String>> moolatrikonaEffect = {
  'kn': {
    'lord': ' ಈ ಭಾವಾಧಿಪತಿ ಮೂಲತ್ರಿಕೋಣದಲ್ಲಿರುವುದರಿಂದ ಅತ್ಯಂತ ಬಲಶಾಲಿ. ಜಾತಕ ಪಾರಿಜಾತದ ಪ್ರಕಾರ ಮೂಲತ್ರಿಕೋಣಸ್ಥ ಗ್ರಹ ಸ್ವಕ್ಷೇತ್ರಕ್ಕಿಂತಲೂ ಉತ್ತಮ ಫಲ ನೀಡುತ್ತಾನೆ.',
    'planet': ' ಈ ಗ್ರಹವು ಮೂಲತ್ರಿಕೋಣ ಸ್ಥಿತಿಯಲ್ಲಿದ್ದು ತನ್ನ ಸ್ವಭಾವಕ್ಕೆ ಅನುಗುಣವಾದ ಶ್ರೇಷ್ಠ ಫಲ ನೀಡುತ್ತಾನೆ.',
  },
  'hi': {
    'lord': ' इस भावाधिपति का मूलत्रिकोण में होने से अत्यंत बलशाली है। जातक पारिजात के अनुसार मूलत्रिकोण स्थित ग्रह स्वक्षेत्र से भी उत्तम फल देता है।',
    'planet': ' यह ग्रह मूलत्रिकोण स्थिति में होकर अपने स्वभाव के अनुरूप श्रेष्ठ फल देता है।',
  },
  'ta': {
    'lord': ' இந்த பாவாதிபதி மூலத்திரிகோணத்தில் இருப்பதால் மிகவும் பலசாலி. ஜாதக பாரிஜாதத்தின் படி மூலத்திரிகோண கிரகம் சுயட்சேத்திரத்தை விட சிறந்த பலன் தரும்.',
    'planet': ' இந்த கிரகம் மூலத்திரிகோண நிலையில் உள்ளதால் சிறந்த பலன் தரும்.',
  },
  'te': {
    'lord': ' ఈ భావాధిపతి మూలత్రికోణంలో ఉన్నందున అత్యంత బలశాలి. జాతక పారిజాతం ప్రకారం మూలత్రికోణ గ్రహం స్వక్షేత్రం కంటే మెరుగైన ఫలం ఇస్తుంది.',
    'planet': ' ఈ గ్రహం మూలత్రికోణ స్థితిలో ఉండి శ్రేష్ఠమైన ఫలం ఇస్తుంది.',
  },
  'ml': {
    'lord': ' ഈ ഭാവാധിപതി മൂലത്രികോണത്തിൽ ആയതിനാൽ അത്യന്തം ബലവാനാണ്. ജാതക പാരിജാതം പ്രകാരം മൂലത്രികോണ ഗ്രഹം സ്വക്ഷേത്രത്തെക്കാൾ മികച്ച ഫലം നൽകും.',
    'planet': ' ഈ ഗ്രഹം മൂലത്രികോണ സ്ഥിതിയിൽ ഉള്ളതിനാൽ ശ്രേഷ്ഠമായ ഫലം നൽകും.',
  },
  'en': {
    'lord': ' The house lord is in its Moolatrikona sign, making it exceptionally strong. According to Jataka Parijata, a planet in Moolatrikona delivers even better results than in its own sign.',
    'planet': ' This planet is in its Moolatrikona position, delivering excellent results aligned with its natural significations.',
  },
};

/// House-type classical insights (Saravali & Chamatkar Chintamani)
/// Contextual text about benefics/malefics in different house types
const Map<String, Map<String, String>> houseTypeInsight = {
  'kn': {
    'benefic_kendra': ' ಕೇಂದ್ರ ಸ್ಥಾನದಲ್ಲಿ ಶುಭ ಗ್ರಹವಿರುವುದು ಅತ್ಯಂತ ಶ್ರೇಷ್ಠ ಯೋಗ. ಚಮತ್ಕಾರ ಚಿಂತಾಮಣಿಯ ಪ್ರಕಾರ ಕೇಂದ್ರದಲ್ಲಿ ಶುಭ ಗ್ರಹ ಜೀವನದ ಪ್ರಮುಖ ಕ್ಷೇತ್ರಗಳಲ್ಲಿ ಸ್ಥಿರತೆ ಮತ್ತು ಯಶಸ್ಸನ್ನು ತರುತ್ತದೆ.',
    'malefic_kendra': ' ಕೇಂದ್ರದಲ್ಲಿ ಪಾಪ ಗ್ರಹವು ಸವಾಲುಗಳ ಜೊತೆಗೆ ಶಕ್ತಿ ಮತ್ತು ಸಾಹಸವನ್ನೂ ನೀಡುತ್ತದೆ. ಸಾರವಲಿಯ ಪ್ರಕಾರ ಕೇಂದ್ರದ ಪಾಪ ಗ್ರಹ ನಿಧಾನವಾಗಿ ಶುಭನಾಗುತ್ತಾನೆ.',
    'benefic_trikona': ' ತ್ರಿಕೋಣದಲ್ಲಿ ಶುಭ ಗ್ರಹ ಇರುವುದು ಧರ್ಮ-ಪೂರ್ವಪುಣ್ಯ-ಭಾಗ್ಯ ವೃದ್ಧಿಗೆ ಕಾರಣ. ಫಲದೀಪಿಕೆಯ ಪ್ರಕಾರ ಇದು ಜೀವನದ ಅತ್ಯಂತ ಮಂಗಳಕರ ಸ್ಥಿತಿಗಳಲ್ಲೊಂದು.',
    'malefic_dusthana': ' ದುಃಸ್ಥಾನಗಳಲ್ಲಿ ಪಾಪ ಗ್ರಹಗಳು ವೀರ್ಯಪರಿಹಾರ ಯೋಗ ಮಾಡಿ ಶುಭ ಫಲ ನೀಡಬಲ್ಲವು. ಶತ್ರು ನಾಶ, ಸಾಲ ಮುಕ್ತಿ ಮತ್ತು ಸ್ಪರ್ಧೆಯಲ್ಲಿ ಜಯವನ್ನು ಸೂಚಿಸುತ್ತವೆ.',
    'benefic_dusthana': ' ದುಃಸ್ಥಾನದಲ್ಲಿ ಶುಭ ಗ್ರಹವು ತನ್ನ ಶುಭ ಗುಣಗಳನ್ನು ಪೂರ್ಣವಾಗಿ ತೋರಿಸಲು ಅಸಮರ್ಥ. ಜಾತಕ ಪಾರಿಜಾತದ ಪ್ರಕಾರ ಶುಭ ಗ್ರಹಕ್ಕೆ ಇದು ಕಷ್ಟಕರ ಸ್ಥಾನ.',
    'upachaya': ' ಉಪಚಯ ಸ್ಥಾನವಾಗಿರುವುದರಿಂದ ಕಾಲಕ್ರಮೇಣ ಫಲಗಳು ವೃದ್ಧಿಯಾಗುತ್ತವೆ. ಸಾರವಲಿಯ ಪ್ರಕಾರ ಉಪಚಯದಲ್ಲಿ ಪಾಪ ಗ್ರಹಗಳು ವಿಶೇಷ ಬಲವನ್ನು ಪಡೆಯುತ್ತವೆ.',
  },
  'hi': {
    'benefic_kendra': ' केन्द्र स्थान में शुभ ग्रह होना अत्यंत श्रेष्ठ योग है। चमत्कार चिन्तामणि के अनुसार केन्द्र में शुभ ग्रह जीवन के प्रमुख क्षेत्रों में स्थिरता और सफलता लाता है।',
    'malefic_kendra': ' केन्द्र में पाप ग्रह चुनौतियों के साथ शक्ति और साहस भी देता है। सारावली के अनुसार केन्द्र का पाप ग्रह धीरे-धीरे शुभ बनता है।',
    'benefic_trikona': ' त्रिकोण में शुभ ग्रह धर्म-पूर्वपुण्य-भाग्य की वृद्धि करता है। फलदीपिका के अनुसार यह सर्वाधिक मंगलकारी स्थितियों में से एक है।',
    'malefic_dusthana': ' दुःस्थान में पाप ग्रह वीर्यपरिहार योग बनाकर शुभ फल दे सकते हैं। शत्रु नाश, ऋण मुक्ति और प्रतिस्पर्धा में जय का संकेत है।',
    'benefic_dusthana': ' दुःस्थान में शुभ ग्रह अपने शुभ गुणों को पूर्ण रूप से प्रकट करने में असमर्थ है।',
    'upachaya': ' उपचय स्थान होने से कालक्रम में फल बढ़ते हैं। सारावली के अनुसार उपचय में पाप ग्रह विशेष बल प्राप्त करते हैं।',
  },
  'ta': {
    'benefic_kendra': ' கேந்திர ஸ்தானத்தில் சுப கிரகம் இருப்பது மிகச்சிறந்த யோகம். சமத்கார சிந்தாமணியின் படி கேந்திரத்தில் சுப கிரகம் வாழ்வின் முக்கிய துறைகளில் நிலைத்தன்மையும் வெற்றியும் தரும்.',
    'malefic_kendra': ' கேந்திரத்தில் பாப கிரகம் சவால்களுடன் சக்தியையும் தைரியத்தையும் தரும்.',
    'benefic_trikona': ' திரிகோணத்தில் சுப கிரகம் தர்மம், பூர்வ புண்ணியம், பாக்கியம் ஆகியவற்றை வளர்க்கும்.',
    'malefic_dusthana': ' துஷ்டானத்தில் பாப கிரகங்கள் வீர்ய பரிஹார யோகம் செய்து நல்ல பலன் தரக்கூடும்.',
    'benefic_dusthana': ' துஷ்டானத்தில் சுப கிரகம் தனது சுப குணங்களை முழுமையாக வெளிப்படுத்த இயலாது.',
    'upachaya': ' உபசய ஸ்தானமாக இருப்பதால் காலப்போக்கில் பலன்கள் அதிகரிக்கும்.',
  },
  'te': {
    'benefic_kendra': ' కేంద్ర స్థానంలో శుభ గ్రహం ఉండడం అత్యంత శ్రేష్ఠమైన యోగం. చమత్కార చింతామణి ప్రకారం కేంద్రంలో శుభ గ్రహం జీవితంలోని ప్రముఖ రంగాలలో స్థిరత్వాన్ని మరియు విజయాన్ని తెస్తుంది.',
    'malefic_kendra': ' కేంద్రంలో పాప గ్రహం సవాళ్లతో పాటు శక్తిని మరియు సాహసాన్ని కూడా ఇస్తుంది.',
    'benefic_trikona': ' త్రికోణంలో శుభ గ్రహం ధర్మ-పూర్వపుణ్య-భాగ్యాన్ని వృద్ధి చేస్తుంది.',
    'malefic_dusthana': ' దుస్థానాలలో పాప గ్రహాలు వీర్య పరిహార యోగం చేసి శుభ ఫలం ఇవ్వగలవు.',
    'benefic_dusthana': ' దుస్థానంలో శుభ గ్రహం తన శుభ గుణాలను పూర్తిగా వ్యక్తపరచడంలో అసమర్థం.',
    'upachaya': ' ఉపచయ స్థానం కావడం వల్ల కాలక్రమేణా ఫలాలు వృద్ధి అవుతాయి.',
  },
  'ml': {
    'benefic_kendra': ' കേന്ദ്ര സ്ഥാനത്ത് ശുഭ ഗ്രഹം ഉള്ളത് അത്യന്തം ശ്രേഷ്ഠമായ യോഗമാണ്. ചമത്കാര ചിന്താമണി പ്രകാരം കേന്ദ്രത്തിൽ ശുഭ ഗ്രഹം ജീവിതത്തിന്റെ പ്രധാന മേഖലകളിൽ സ്ഥിരതയും വിജയവും നൽകും.',
    'malefic_kendra': ' കേന്ദ്രത്തിൽ പാപ ഗ്രഹം വെല്ലുവിളികൾക്കൊപ്പം ശക്തിയും സാഹസികതയും നൽകും.',
    'benefic_trikona': ' ത്രികോണത്തിൽ ശുഭ ഗ്രഹം ധർമ-പൂർവപുണ്യ-ഭാഗ്യ വർധനയ്ക്ക് കാരണമാകും.',
    'malefic_dusthana': ' ദുഃസ്ഥാനങ്ങളിൽ പാപ ഗ്രഹങ്ങൾ വീര്യപരിഹാര യോഗം ചെയ്ത് ശുഭ ഫലം നൽകാൻ കഴിയും.',
    'benefic_dusthana': ' ദുഃസ്ഥാനത്ത് ശുഭ ഗ്രഹം തന്റെ ശുഭ ഗുണങ്ങൾ പൂർണമായി പ്രകടിപ്പിക്കാൻ അസമർഥമാണ്.',
    'upachaya': ' ഉപചയ സ്ഥാനമായതിനാൽ കാലക്രമേണ ഫലങ്ങൾ വർധിക്കും.',
  },
  'en': {
    'benefic_kendra': ' A benefic planet in a Kendra (angular house) is one of the most auspicious placements. According to Chamatkar Chintamani, this brings stability and success in the key areas of life governed by this house.',
    'malefic_kendra': ' A malefic in a Kendra brings challenges but also strength, drive, and courage. According to Saravali, malefics in Kendras gradually transform to deliver positive outcomes over time.',
    'benefic_trikona': ' A benefic in a Trikona (trinal house) greatly enhances dharma, past-life merit, and fortune. Phaladeepika considers this among the most auspicious planetary positions.',
    'malefic_dusthana': ' Malefics in Dusthana houses (6, 8, 12) create Viparita Raja Yoga, potentially converting adversity into advantage — victory over enemies, debt relief, and competitive success.',
    'benefic_dusthana': ' A benefic planet in a Dusthana house is unable to fully express its positive qualities. Jataka Parijata describes this as a challenging position for naturally beneficial planets.',
    'upachaya': ' Being an Upachaya (growing) house, results here improve progressively with age and effort. Saravali notes that malefic planets gain special strength in Upachaya positions.',
  },
};

// ─── Friendly / Enemy sign effects (Saravali) ───
const Map<String, Map<String, String>> friendEnemyEffect = {
  'kn': {
    'friend': ' ಮಿತ್ರ ಕ್ಷೇತ್ರದಲ್ಲಿರುವುದರಿಂದ ಗ್ರಹವು ಸಹಕಾರಿ ಫಲ ನೀಡುತ್ತಾನೆ. ಸಾರವಲಿಯ ಪ್ರಕಾರ ಮಿತ್ರ ಕ್ಷೇತ್ರದ ಗ್ರಹ ನೈಸರ್ಗಿಕ ಶುಭತ್ವವನ್ನು ಹೆಚ್ಚಿಸುತ್ತಾನೆ.',
    'enemy': ' ಶತ್ರು ಕ್ಷೇತ್ರದಲ್ಲಿರುವುದರಿಂದ ಗ್ರಹದ ಫಲದಾಯಕತೆ ಕಡಿಮೆ. ಫಲಗಳಲ್ಲಿ ಅಡಚಣೆ ಮತ್ತು ಹಿನ್ನಡೆ ಅನುಭವಿಸಬಹುದು.',
  },
  'hi': {
    'friend': ' मित्र क्षेत्र में होने से ग्रह सहयोगी फल देता है। सारावली के अनुसार मित्र क्षेत्र का ग्रह प्राकृतिक शुभत्व बढ़ाता है।',
    'enemy': ' शत्रु क्षेत्र में होने से ग्रह की फलदायकता कम है। फलों में बाधा और पिछड़ापन अनुभव हो सकता है।',
  },
  'ta': {
    'friend': ' நட்பு வீட்டில் இருப்பதால் கிரகம் ஒத்துழைப்பான பலன் தரும்.',
    'enemy': ' பகை வீட்டில் இருப்பதால் கிரகத்தின் பலன் தரும் தன்மை குறைவு.',
  },
  'te': {
    'friend': ' మిత్ర క్షేత్రంలో ఉన్నందున గ్రహం సహకార ఫలం ఇస్తుంది.',
    'enemy': ' శత్రు క్షేత్రంలో ఉన్నందున గ్రహ ఫలదాయకత తక్కువ.',
  },
  'ml': {
    'friend': ' മിത്ര ക്ഷേത്രത്തിൽ ഉള്ളതിനാൽ ഗ്രഹം സഹകരണ ഫലം നൽകും.',
    'enemy': ' ശത്രു ക്ഷേത്രത്തിൽ ഉള്ളതിനാൽ ഗ്രഹ ഫലദായകത കുറവാണ്.',
  },
  'en': {
    'friend': ' Being placed in a friendly sign, the planet delivers cooperative and enhanced results. Per Saravali, a planet in a friend\'s sign amplifies its natural beneficence.',
    'enemy': ' Being placed in an enemy sign, the planet\'s ability to deliver results is diminished. Obstacles and setbacks may be experienced in the related areas.',
  },
};

/// Planetary friendship chart (naisargika maitri)
const Map<String, Set<String>> naturalFriends = {
  'ರವಿ': {'ಚಂದ್ರ', 'ಕುಜ', 'ಗುರು'},
  'ಚಂದ್ರ': {'ರವಿ', 'ಬುಧ'},
  'ಕುಜ': {'ರವಿ', 'ಚಂದ್ರ', 'ಗುರು'},
  'ಬುಧ': {'ರವಿ', 'ಶುಕ್ರ'},
  'ಗುರು': {'ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ'},
  'ಶುಕ್ರ': {'ಬುಧ', 'ಶನಿ'},
  'ಶನಿ': {'ಬುಧ', 'ಶುಕ್ರ'},
};

const Map<String, Set<String>> naturalEnemies = {
  'ರವಿ': {'ಶುಕ್ರ', 'ಶನಿ'},
  'ಚಂದ್ರ': {},
  'ಕುಜ': {'ಬುಧ'},
  'ಬುಧ': {'ಚಂದ್ರ'},
  'ಗುರು': {'ಬುಧ', 'ಶುಕ್ರ'},
  'ಶುಕ್ರ': {'ರವಿ', 'ಚಂದ್ರ'},
  'ಶನಿ': {'ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ'},
};
