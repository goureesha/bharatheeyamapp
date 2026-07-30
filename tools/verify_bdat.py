import json, gzip

with open('tools/output/bharatheeyam_panchanga_Bengaluru.bdat', 'rb') as f:
    data = json.loads(gzip.decompress(f.read()))

print('Zone:', data['zone'])
print('Days:', len(data['days']))
print('From:', data['from'], 'To:', data['to'])
print()
print('First 3 days:')
for d in data['days'][:3]:
    print(f"  {d[0]} | Tithi: {d[2]} ({d[1]}) | Nak: {d[4]} ({d[3]}) | Yoga: {d[6]} ({d[5]}) | SR: {d[13]} SS: {d[14]}")
print()
print('Compact format sample:')
print(data['days'][0])
