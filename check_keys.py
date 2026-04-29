import io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'd:\bharatheeyamapp sample\lib\widgets\common.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Keys needed for pdf_service.dart labels
needed = [
    'pdfBirthDetails','pdfName','pdfDob','pdfTime','pdfPlace','pdfLat','pdfLon',
    'pdfPanchanga','pdfTopic','pdfDetail',
    'samvatsara','rutu','vara','tithiLabel','nakshatra','yogaLabel','karanaLabel',
    'chandraRashiLabel','chandraMasaLabel','souraMasaLabel',
    'sunriseLabel','sunsetLabel','udayadiGhatiLabel','gataGhatiLabel',
    'paramaGhatiLabel','vishaPraghatiLabel','amrutaPraghatiLabel',
    'pdfPlanetPos','hGraha','hRashi','hSphuta','hNakPada','pdfVakriAsta',
    'pdfVakri','pdfAsta',
    'pdfDasha','pdfDashaLord','pdfStart','pdfEnd',
    'pdfBhavaMadhya','pdfBhava','pdfSphuta',
    'pdfUpagraha',
    'pdfShadbala','pdfTotalBala','pdfNeeded','pdfRatio',
    'pdfNotes','pdfKundali',
]

for k in needed:
    found = f"'{k}'" in content
    print(f"{'✓' if found else '✗'} {k}")
