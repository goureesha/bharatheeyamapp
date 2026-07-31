"""
Generate world_cities.json from GeoNames cities15000 dataset.
Produces a compact JSON with: name, country, lat, lon, tz (UTC offset).
"""
import json
import os
import zipfile
import io
import urllib.request

TZ_OFFSETS = {
    'UTC': 0.0, 'GMT': 0.0,
    'Europe/London': 0.0, 'Europe/Dublin': 0.0, 'Europe/Lisbon': 0.0,
    'Europe/Paris': 1.0, 'Europe/Berlin': 1.0, 'Europe/Rome': 1.0,
    'Europe/Madrid': 1.0, 'Europe/Brussels': 1.0, 'Europe/Amsterdam': 1.0,
    'Europe/Vienna': 1.0, 'Europe/Zurich': 1.0, 'Europe/Stockholm': 1.0,
    'Europe/Oslo': 1.0, 'Europe/Copenhagen': 1.0, 'Europe/Warsaw': 1.0,
    'Europe/Prague': 1.0, 'Europe/Budapest': 1.0, 'Europe/Belgrade': 1.0,
    'Europe/Zagreb': 1.0, 'Europe/Ljubljana': 1.0, 'Europe/Bratislava': 1.0,
    'Europe/Luxembourg': 1.0, 'Europe/Monaco': 1.0, 'Europe/Andorra': 1.0,
    'Europe/Malta': 1.0, 'Europe/Tirane': 1.0, 'Europe/Podgorica': 1.0,
    'Europe/Skopje': 1.0, 'Europe/Sarajevo': 1.0, 'Europe/San_Marino': 1.0,
    'Europe/Vatican': 1.0,
    'Europe/Athens': 2.0, 'Europe/Bucharest': 2.0, 'Europe/Sofia': 2.0,
    'Europe/Helsinki': 2.0, 'Europe/Tallinn': 2.0, 'Europe/Riga': 2.0,
    'Europe/Vilnius': 2.0, 'Europe/Kiev': 2.0, 'Europe/Kyiv': 2.0,
    'Europe/Chisinau': 2.0, 'Europe/Kaliningrad': 2.0, 'Europe/Uzhgorod': 2.0,
    'Europe/Zaporozhye': 2.0, 'Europe/Mariehamn': 2.0, 'Europe/Nicosia': 2.0,
    'Europe/Moscow': 3.0, 'Europe/Minsk': 3.0, 'Europe/Istanbul': 3.0,
    'Europe/Simferopol': 3.0, 'Europe/Kirov': 3.0, 'Europe/Volgograd': 3.0,
    'Europe/Samara': 4.0, 'Europe/Saratov': 4.0, 'Europe/Ulyanovsk': 4.0,
    'Europe/Astrakhan': 4.0,
    'Africa/Casablanca': 1.0, 'Africa/Algiers': 1.0, 'Africa/Tunis': 1.0,
    'Africa/Lagos': 1.0, 'Africa/Kinshasa': 1.0, 'Africa/Luanda': 1.0,
    'Africa/Douala': 1.0, 'Africa/Libreville': 1.0, 'Africa/Brazzaville': 1.0,
    'Africa/Bangui': 1.0, 'Africa/Malabo': 1.0, 'Africa/Niamey': 1.0,
    'Africa/Ndjamena': 1.0, 'Africa/Porto-Novo': 1.0,
    'Africa/Abidjan': 0.0, 'Africa/Accra': 0.0, 'Africa/Bamako': 0.0,
    'Africa/Conakry': 0.0, 'Africa/Dakar': 0.0, 'Africa/Freetown': 0.0,
    'Africa/Lome': 0.0, 'Africa/Monrovia': 0.0, 'Africa/Nouakchott': 0.0,
    'Africa/Ouagadougou': 0.0, 'Africa/Sao_Tome': 0.0, 'Africa/Banjul': 0.0,
    'Africa/Bissau': 0.0, 'Africa/El_Aaiun': 1.0,
    'Africa/Cairo': 2.0, 'Africa/Tripoli': 2.0, 'Africa/Johannesburg': 2.0,
    'Africa/Harare': 2.0, 'Africa/Maputo': 2.0, 'Africa/Lusaka': 2.0,
    'Africa/Blantyre': 2.0, 'Africa/Bujumbura': 2.0, 'Africa/Gaborone': 2.0,
    'Africa/Kigali': 2.0, 'Africa/Lubumbashi': 2.0, 'Africa/Mbabane': 2.0,
    'Africa/Windhoek': 2.0, 'Africa/Maseru': 2.0, 'Africa/Ceuta': 1.0,
    'Africa/Juba': 2.0,
    'Africa/Addis_Ababa': 3.0, 'Africa/Nairobi': 3.0, 'Africa/Dar_es_Salaam': 3.0,
    'Africa/Kampala': 3.0, 'Africa/Mogadishu': 3.0, 'Africa/Asmara': 3.0,
    'Africa/Djibouti': 3.0, 'Africa/Khartoum': 2.0, 'Africa/Asmera': 3.0,
    'Asia/Kolkata': 5.5, 'Asia/Calcutta': 5.5, 'Asia/Colombo': 5.5,
    'Asia/Kathmandu': 5.75, 'Asia/Katmandu': 5.75,
    'Asia/Dhaka': 6.0, 'Asia/Thimphu': 6.0, 'Asia/Almaty': 6.0,
    'Asia/Bishkek': 6.0, 'Asia/Urumqi': 6.0, 'Asia/Omsk': 6.0,
    'Asia/Yangon': 6.5, 'Asia/Rangoon': 6.5,
    'Asia/Bangkok': 7.0, 'Asia/Jakarta': 7.0, 'Asia/Saigon': 7.0,
    'Asia/Ho_Chi_Minh': 7.0, 'Asia/Phnom_Penh': 7.0, 'Asia/Vientiane': 7.0,
    'Asia/Barnaul': 7.0, 'Asia/Krasnoyarsk': 7.0, 'Asia/Novokuznetsk': 7.0,
    'Asia/Novosibirsk': 7.0, 'Asia/Tomsk': 7.0, 'Asia/Pontianak': 7.0,
    'Asia/Singapore': 8.0, 'Asia/Hong_Kong': 8.0, 'Asia/Shanghai': 8.0,
    'Asia/Taipei': 8.0, 'Asia/Kuala_Lumpur': 8.0, 'Asia/Manila': 8.0,
    'Asia/Makassar': 8.0, 'Asia/Brunei': 8.0, 'Asia/Choibalsan': 8.0,
    'Asia/Ulaanbaatar': 8.0, 'Asia/Irkutsk': 8.0, 'Asia/Kuching': 8.0,
    'Asia/Chongqing': 8.0, 'Asia/Chungking': 8.0, 'Asia/Harbin': 8.0,
    'Asia/Hovd': 7.0,
    'Asia/Tokyo': 9.0, 'Asia/Seoul': 9.0, 'Asia/Pyongyang': 9.0,
    'Asia/Jayapura': 9.0, 'Asia/Dili': 9.0, 'Asia/Yakutsk': 9.0,
    'Asia/Chita': 9.0, 'Asia/Khandyga': 9.0,
    'Asia/Vladivostok': 10.0, 'Asia/Ust-Nera': 10.0, 'Asia/Magadan': 11.0,
    'Asia/Sakhalin': 11.0, 'Asia/Srednekolymsk': 11.0,
    'Asia/Kamchatka': 12.0, 'Asia/Anadyr': 12.0,
    'Asia/Dubai': 4.0, 'Asia/Muscat': 4.0, 'Asia/Baku': 4.0,
    'Asia/Tbilisi': 4.0, 'Asia/Yerevan': 4.0,
    'Asia/Kabul': 4.5,
    'Asia/Karachi': 5.0, 'Asia/Tashkent': 5.0, 'Asia/Ashgabat': 5.0,
    'Asia/Dushanbe': 5.0, 'Asia/Samarkand': 5.0, 'Asia/Aqtobe': 5.0,
    'Asia/Aqtau': 5.0, 'Asia/Atyrau': 5.0, 'Asia/Oral': 5.0,
    'Asia/Qyzylorda': 5.0, 'Asia/Qostanay': 6.0, 'Asia/Yekaterinburg': 5.0,
    'Asia/Tehran': 3.5, 'Asia/Baghdad': 3.0, 'Asia/Kuwait': 3.0,
    'Asia/Riyadh': 3.0, 'Asia/Aden': 3.0, 'Asia/Bahrain': 3.0,
    'Asia/Qatar': 3.0, 'Asia/Amman': 3.0, 'Asia/Beirut': 2.0,
    'Asia/Damascus': 3.0, 'Asia/Gaza': 2.0, 'Asia/Hebron': 2.0,
    'Asia/Jerusalem': 2.0, 'Asia/Tel_Aviv': 2.0, 'Asia/Nicosia': 2.0,
    'Asia/Famagusta': 2.0,
    'America/New_York': -5.0, 'America/Toronto': -5.0, 'America/Detroit': -5.0,
    'America/Montreal': -5.0, 'America/Havana': -5.0, 'America/Nassau': -5.0,
    'America/Port-au-Prince': -5.0, 'America/Jamaica': -5.0,
    'America/Panama': -5.0, 'America/Bogota': -5.0, 'America/Lima': -5.0,
    'America/Guayaquil': -5.0, 'America/Cayman': -5.0,
    'America/Chicago': -6.0, 'America/Mexico_City': -6.0,
    'America/Winnipeg': -6.0, 'America/Guatemala': -6.0,
    'America/Tegucigalpa': -6.0, 'America/El_Salvador': -6.0,
    'America/Managua': -6.0, 'America/Costa_Rica': -6.0,
    'America/Denver': -7.0, 'America/Edmonton': -7.0,
    'America/Phoenix': -7.0, 'America/Los_Angeles': -8.0,
    'America/Vancouver': -8.0, 'America/Tijuana': -8.0,
    'America/Anchorage': -9.0, 'Pacific/Honolulu': -10.0,
    'America/Caracas': -4.0, 'America/La_Paz': -4.0,
    'America/Santo_Domingo': -4.0, 'America/Puerto_Rico': -4.0,
    'America/Halifax': -4.0, 'America/Sao_Paulo': -3.0,
    'America/Argentina/Buenos_Aires': -3.0, 'America/Santiago': -3.0,
    'America/Montevideo': -3.0, 'America/Asuncion': -3.0,
    'America/St_Johns': -3.5,
    'Pacific/Auckland': 12.0, 'Pacific/Fiji': 12.0,
    'Pacific/Port_Moresby': 10.0, 'Pacific/Guam': 10.0,
    'Australia/Sydney': 10.0, 'Australia/Melbourne': 10.0,
    'Australia/Brisbane': 10.0, 'Australia/Hobart': 10.0,
    'Australia/Adelaide': 9.5, 'Australia/Darwin': 9.5,
    'Australia/Perth': 8.0,
    'Indian/Maldives': 5.0, 'Indian/Mauritius': 4.0,
    'Indian/Antananarivo': 3.0,
}

def main():
    url = "http://download.geonames.org/export/dump/cities15000.zip"
    print(f"Downloading {url}...")
    response = urllib.request.urlopen(url)
    zip_data = response.read()
    print(f"Downloaded {len(zip_data)} bytes")

    cities = []
    with zipfile.ZipFile(io.BytesIO(zip_data)) as zf:
        with zf.open('cities15000.txt') as f:
            for line in f:
                parts = line.decode('utf-8').strip().split('\t')
                if len(parts) < 18:
                    continue
                name = parts[1]
                lat = round(float(parts[4]), 4)
                lon = round(float(parts[5]), 4)
                country = parts[8]
                population = int(parts[14]) if parts[14] else 0
                tz_id = parts[17]
                tz_offset = TZ_OFFSETS.get(tz_id)
                if tz_offset is None:
                    tz_offset = round(lon / 15.0 * 2) / 2.0
                cities.append({'n': name, 'c': country, 'la': lat, 'lo': lon, 'tz': tz_offset, 'p': population})

    cities.sort(key=lambda x: x['p'], reverse=True)
    for c in cities:
        del c['p']

    output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'world_cities.json')
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(cities, f, ensure_ascii=False, separators=(',', ':'))

    size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"Generated {output_path}")
    print(f"Total cities: {len(cities)}, Size: {size_mb:.2f} MB")

if __name__ == '__main__':
    main()
