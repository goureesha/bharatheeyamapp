"""
Bharatheeyam Panchanga Data Generator
Generates .bdat files for the Bharatheeyam app.
Uses Swiss Ephemeris (pyswisseph) for accurate calculations.

Usage:
  pip install pyswisseph
  python generate_bdat.py --zone Bengaluru --lat 12.97 --lon 77.59 --years 20
"""

import argparse
import json
import gzip
import math
import os
from datetime import datetime, timedelta

try:
    import swisseph as swe
except ImportError:
    print("ERROR: pyswisseph not installed. Run: pip install pyswisseph")
    exit(1)

# ─── Constants ───────────────────────────────────────────────

KN_TITHI = [
    'ಪಾಡ್ಯಮಿ', 'ಬಿದಿಗೆ', 'ತದಿಗೆ', 'ಚವತಿ', 'ಪಂಚಮಿ',
    'ಷಷ್ಠೀ', 'ಸಪ್ತಮೀ', 'ಅಷ್ಟಮೀ', 'ನವಮೀ', 'ದಶಮೀ',
    'ಏಕಾದಶೀ', 'ದ್ವಾದಶೀ', 'ತ್ರಯೋದಶೀ', 'ಚತುರ್ದಶೀ', 'ಹುಣ್ಣಿಮೆ/ಅಮಾವಾಸ್ಯೆ',
    'ಪಾಡ್ಯಮಿ', 'ಬಿದಿಗೆ', 'ತದಿಗೆ', 'ಚವತಿ', 'ಪಂಚಮಿ',
    'ಷಷ್ಠೀ', 'ಸಪ್ತಮೀ', 'ಅಷ್ಟಮೀ', 'ನವಮೀ', 'ದಶಮೀ',
    'ಏಕಾದಶೀ', 'ದ್ವಾದಶೀ', 'ತ್ರಯೋದಶೀ', 'ಚತುರ್ದಶೀ', 'ಅಮಾವಾಸ್ಯೆ',
]

KN_NAK = [
    'ಅಶ್ವಿನಿ', 'ಭರಣಿ', 'ಕೃತ್ತಿಕ', 'ರೋಹಿಣಿ', 'ಮೃಗಶಿರ',
    'ಆರ್ದ್ರಾ', 'ಪುನರ್ವಸು', 'ಪುಷ್ಯ', 'ಆಶ್ಲೇಷ', 'ಮಘ',
    'ಪೂರ್ವ ಫಲ್ಗುಣಿ', 'ಉತ್ತರ ಫಲ್ಗುಣಿ', 'ಹಸ್ತ', 'ಚಿತ್ರ', 'ಸ್ವಾತಿ',
    'ವಿಶಾಖ', 'ಅನುರಾಧ', 'ಜ್ಯೇಷ್ಠ', 'ಮೂಲ', 'ಪೂರ್ವಾಷಾಢ',
    'ಉತ್ತರಾಷಾಢ', 'ಶ್ರವಣ', 'ಧನಿಷ್ಠ', 'ಶತಭಿಷ', 'ಪೂರ್ವಾಭಾದ್ರ',
    'ಉತ್ತರಾಭಾದ್ರ', 'ರೇವತಿ',
]

KN_YOGA = [
    'ವಿಷ್ಕಂಭ', 'ಪ್ರೀತಿ', 'ಆಯುಷ್ಮಾನ್', 'ಸೌಭಾಗ್ಯ', 'ಶೋಭನ',
    'ಅತಿಗಂಡ', 'ಸುಕರ್ಮ', 'ಧೃತಿ', 'ಶೂಲ', 'ಗಂಡ',
    'ವೃದ್ಧಿ', 'ಧ್ರುವ', 'ವ್ಯಾಘಾತ', 'ಹರ್ಷಣ', 'ವಜ್ರ',
    'ಸಿದ್ಧಿ', 'ವ್ಯತೀಪಾತ', 'ವರೀಯಾನ್', 'ಪರಿಘ', 'ಶಿವ',
    'ಸಿದ್ಧ', 'ಸಾಧ್ಯ', 'ಶುಭ', 'ಶುಕ್ಲ', 'ಬ್ರಹ್ಮ',
    'ಐಂದ್ರ', 'ವೈಧೃತಿ',
]

KN_KARANA = [
    'ಬವ', 'ಬಾಲವ', 'ಕೌಲವ', 'ತೈತಿಲ', 'ಗರ',
    'ವಣಿಜ', 'ವಿಷ್ಟಿ', 'ಶಕುನಿ', 'ಚತುಷ್ಪಾದ', 'ನಾಗ', 'ಕಿಂಸ್ತುಘ್ನ',
]

KN_VARA = ['ಭಾನುವಾರ', 'ಸೋಮವಾರ', 'ಮಂಗಳವಾರ', 'ಬುಧವಾರ', 'ಗುರುವಾರ', 'ಶುಕ್ರವಾರ', 'ಶನಿವಾರ']

KN_RASHI = [
    'ಮೇಷ', 'ವೃಷಭ', 'ಮಿಥುನ', 'ಕರ್ಕ', 'ಸಿಂಹ', 'ಕನ್ಯಾ',
    'ತುಲಾ', 'ವೃಶ್ಚಿಕ', 'ಧನು', 'ಮಕರ', 'ಕುಂಭ', 'ಮೀನ',
]

# ─── Swiss Ephemeris helpers ─────────────────────────────────

def init_swe():
    """Initialize Swiss Ephemeris with Lahiri ayanamsha"""
    swe.set_sid_mode(swe.SIDM_LAHIRI)

def jd_from_date(year, month, day, hour=0.0):
    """Get Julian Day from date"""
    return swe.julday(year, month, day, hour)

def get_sidereal_lon(jd, planet):
    """Get sidereal longitude of a planet"""
    flags = swe.FLG_SWIEPH | swe.FLG_SIDEREAL
    result = swe.calc_ut(jd, planet, flags)
    return result[0][0]  # longitude

def get_tropical_lon(jd, planet):
    """Get tropical longitude of a planet"""
    flags = swe.FLG_SWIEPH
    result = swe.calc_ut(jd, planet, flags)
    return result[0][0]

def find_sunrise_sunset(jd, lat, lon, tz_offset=5.5):
    """
    Find sunrise and sunset for a date.
    Returns (sunrise_jd, sunset_jd) or approximate if rise_trans fails.
    Uses geometric horizon (0 degrees, no refraction).
    """
    # Local midnight in UT
    local_midnight_ut = jd - (tz_offset / 24.0)
    
    try:
        # Sunrise - geometric (no refraction)
        rise_result = swe.rise_trans(
            local_midnight_ut, swe.SUN,
            geopos=(lon, lat, 0),
            rsmi=swe.CALC_RISE | swe.BIT_DISC_CENTER | swe.BIT_NO_REFRACTION
        )
        sunrise_jd = rise_result[1][0]
    except:
        # Fallback: approximate
        sunrise_jd = local_midnight_ut + 0.25  # ~6 AM
    
    try:
        # Sunset
        set_result = swe.rise_trans(
            local_midnight_ut, swe.SUN,
            geopos=(lon, lat, 0),
            rsmi=swe.CALC_SET | swe.BIT_DISC_CENTER | swe.BIT_NO_REFRACTION
        )
        sunset_jd = set_result[1][0]
    except:
        sunset_jd = local_midnight_ut + 0.75  # ~6 PM
    
    return sunrise_jd, sunset_jd

def jd_to_time_str(jd, tz_offset=5.5):
    """Convert JD to HH:MM time string in local time"""
    local_jd = jd + (tz_offset / 24.0)
    frac = (local_jd + 0.5) % 1.0
    hours = frac * 24.0
    h = int(hours)
    m = int((hours - h) * 60)
    return f"{h:02d}:{m:02d}"

def is_combust(jd, planet):
    """Check if a planet is combust (too close to Sun)"""
    sun_lon = get_tropical_lon(jd, swe.SUN)
    planet_lon = get_tropical_lon(jd, planet)
    diff = abs(sun_lon - planet_lon)
    if diff > 180:
        diff = 360 - diff
    
    # Combustion degrees
    if planet == swe.JUPITER:
        return diff < 11  # Jupiter combust within 11 degrees
    elif planet == swe.VENUS:
        return diff < 10  # Venus combust within 10 degrees
    return False

def find_tithi_end(jd_start, tithi_idx, tz_offset=5.5):
    """Find when the current tithi ends (approximate)"""
    # Average tithi duration ~0.98 days
    jd = jd_start
    for _ in range(50):
        sun_lon = get_sidereal_lon(jd, swe.SUN)
        moon_lon = get_sidereal_lon(jd, swe.MOON)
        diff = (moon_lon - sun_lon + 360) % 360
        cur_tithi = int(diff / 12)
        if cur_tithi != tithi_idx:
            # Binary search for exact transition
            lo, hi = jd - 0.05, jd
            for _ in range(20):
                mid = (lo + hi) / 2
                s = get_sidereal_lon(mid, swe.SUN)
                m = get_sidereal_lon(mid, swe.MOON)
                d = (m - s + 360) % 360
                t = int(d / 12)
                if t == tithi_idx:
                    lo = mid
                else:
                    hi = mid
            return jd_to_time_str(hi, tz_offset)
        jd += 0.05  # Step ~72 minutes
    return '--:--'

def find_nak_end(jd_start, nak_idx, tz_offset=5.5):
    """Find when the current nakshatra ends (approximate)"""
    nak_span = 360.0 / 27.0
    jd = jd_start
    for _ in range(50):
        moon_lon = get_sidereal_lon(jd, swe.MOON)
        cur_nak = int(moon_lon / nak_span) % 27
        if cur_nak != nak_idx:
            lo, hi = jd - 0.05, jd
            for _ in range(20):
                mid = (lo + hi) / 2
                m = get_sidereal_lon(mid, swe.MOON)
                t = int(m / nak_span) % 27
                if t == nak_idx:
                    lo = mid
                else:
                    hi = mid
            return jd_to_time_str(hi, tz_offset)
        jd += 0.05
    return '--:--'

# ─── Main computation ────────────────────────────────────────

def compute_day(year, month, day, lat, lon, tz_offset=5.5):
    """Compute all panchanga data for a single day"""
    jd_noon = jd_from_date(year, month, day, 12.0)
    
    # Sunrise/Sunset
    sr_jd, ss_jd = find_sunrise_sunset(jd_noon, lat, lon, tz_offset)
    sunrise_str = jd_to_time_str(sr_jd, tz_offset)
    sunset_str = jd_to_time_str(ss_jd, tz_offset)
    
    # Compute at sunrise
    sun_lon = get_sidereal_lon(sr_jd, swe.SUN)
    moon_lon = get_sidereal_lon(sr_jd, swe.MOON)
    jup_lon = get_sidereal_lon(sr_jd, swe.JUPITER)
    
    # Tithi (0-29)
    tithi_diff = (moon_lon - sun_lon + 360) % 360
    tithi_idx = int(tithi_diff / 12)
    tithi_name = KN_TITHI[tithi_idx]
    
    # Nakshatra (0-26)
    nak_span = 360.0 / 27.0
    nak_idx = int(moon_lon / nak_span) % 27
    nak_name = KN_NAK[nak_idx]
    nak_percent = (moon_lon % nak_span) / nak_span
    pada = int(nak_percent * 4) + 1
    if pada > 4: pada = 4
    
    # Yoga (0-26)
    yoga_val = (sun_lon + moon_lon) % 360
    yoga_idx = int(yoga_val / nak_span) % 27
    yoga_name = KN_YOGA[yoga_idx]
    
    # Karana
    karana_val = tithi_idx * 2 + int((tithi_diff % 12) / 6)
    if karana_val >= 57:
        fixed_karanas = [KN_KARANA[7], KN_KARANA[8], KN_KARANA[9], KN_KARANA[10]]
        karana_name = fixed_karanas[karana_val - 57] if (karana_val - 57) < 4 else KN_KARANA[0]
    else:
        karana_name = KN_KARANA[karana_val % 7]
    
    # Vara
    dt = datetime(year, month, day)
    vara_idx = dt.weekday()  # Monday=0
    # Convert to Sun=0 system
    vara_idx = (vara_idx + 1) % 7
    vara_name = KN_VARA[vara_idx]
    
    # Rashi
    sun_rashi = int(sun_lon / 30) % 12
    moon_rashi = int(moon_lon / 30) % 12
    jup_rashi = int(jup_lon / 30) % 12
    
    # Combustion
    guru_combust = is_combust(sr_jd, swe.JUPITER)
    venus_combust = is_combust(sr_jd, swe.VENUS)
    
    # End times
    tithi_end = find_tithi_end(sr_jd, tithi_idx, tz_offset)
    nak_end = find_nak_end(sr_jd, nak_idx, tz_offset)
    
    # Chandra Rashi name
    chandra_rashi = KN_RASHI[moon_rashi]
    
    # Compact format matching CachedPanchangaDay.toCompact()
    date_str = f"{year}-{month:02d}-{day:02d}"
    return [
        date_str,
        tithi_idx, tithi_name,
        nak_idx, nak_name,
        yoga_idx, yoga_name,
        karana_name,
        moon_rashi, jup_rashi, sun_rashi,
        1 if guru_combust else 0,
        1 if venus_combust else 0,
        sunrise_str, sunset_str,
        round(sun_lon * 100) / 100.0,
        round(moon_lon * 100) / 100.0,
        round(jup_lon * 100) / 100.0,
        pada, tithi_end, nak_end,
        round(nak_percent * 1000) / 1000.0,
        chandra_rashi,
    ]

def generate_bdat(zone_name, lat, lon, years, tz_offset=5.5, output_dir='.'):
    """Generate .bdat file for a zone"""
    init_swe()
    
    now = datetime.now()
    start = datetime(now.year, now.month, now.day)
    end = start + timedelta(days=365 * years)
    
    total_days = (end - start).days + 1
    days = []
    
    print(f"\nGenerating panchanga data for {zone_name}")
    print(f"  Location: {lat}N, {lon}E")
    print(f"  Period: {start.strftime('%Y-%m-%d')} to {end.strftime('%Y-%m-%d')}")
    print(f"  Total days: {total_days}")
    print()
    
    cur = start
    count = 0
    while cur <= end:
        try:
            day_data = compute_day(cur.year, cur.month, cur.day, lat, lon, tz_offset)
            days.append(day_data)
        except Exception as e:
            print(f"  ERROR on {cur}: {e}")
        
        count += 1
        if count % 100 == 0:
            pct = (count / total_days) * 100
            print(f"  [{pct:5.1f}%] {count}/{total_days} days processed...")
        
        cur += timedelta(days=1)
    
    # Build JSON
    data = {
        'v': 2,
        'zone': zone_name,
        'lat': lat,
        'lon': lon,
        'from': start.strftime('%Y-%m-%d'),
        'to': end.strftime('%Y-%m-%d'),
        'days': days,
    }
    
    json_str = json.dumps(data, ensure_ascii=False)
    compressed = gzip.compress(json_str.encode('utf-8'))
    
    zone_safe = ''.join(c if c.isalnum() else '_' for c in zone_name)
    filename = f"bharatheeyam_panchanga_{zone_safe}.bdat"
    filepath = os.path.join(output_dir, filename)
    
    with open(filepath, 'wb') as f:
        f.write(compressed)
    
    raw_mb = len(json_str.encode('utf-8')) / (1024 * 1024)
    comp_mb = len(compressed) / (1024 * 1024)
    
    print(f"\n  DONE!")
    print(f"  Days generated: {len(days)}")
    print(f"  Raw JSON size: {raw_mb:.2f} MB")
    print(f"  Compressed size: {comp_mb:.2f} MB")
    print(f"  File: {filepath}")
    
    return filepath

# ─── Karnataka Zones ─────────────────────────────────────────

KARNATAKA_ZONES = {
    'Kalaburagi': (17.33, 76.83),    # Zone 1: North-East
    'Bengaluru':  (12.97, 77.59),    # Zone 2: South-East
    'Mysuru':     (12.30, 76.66),    # Zone 3: Central
    'Shivamogga': (13.93, 75.57),    # Zone 4: West
    'Mangaluru':  (12.87, 74.88),    # Zone 5: Coastal
}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate Bharatheeyam Panchanga .bdat files')
    parser.add_argument('--zone', type=str, default='Bengaluru', help='Zone name (city)')
    parser.add_argument('--lat', type=float, help='Latitude (overrides zone default)')
    parser.add_argument('--lon', type=float, help='Longitude (overrides zone default)')
    parser.add_argument('--years', type=int, default=20, help='Number of years to generate')
    parser.add_argument('--tz', type=float, default=5.5, help='Timezone offset from UTC')
    parser.add_argument('--all-zones', action='store_true', help='Generate all 5 Karnataka zones')
    parser.add_argument('--output', type=str, default='.', help='Output directory')
    
    args = parser.parse_args()
    
    if args.all_zones:
        print("=" * 60)
        print("GENERATING ALL KARNATAKA ZONES")
        print("=" * 60)
        for zone_name, (lat, lon) in KARNATAKA_ZONES.items():
            generate_bdat(zone_name, lat, lon, args.years, args.tz, args.output)
            print()
    else:
        lat = args.lat
        lon = args.lon
        if lat is None or lon is None:
            if args.zone in KARNATAKA_ZONES:
                lat, lon = KARNATAKA_ZONES[args.zone]
            else:
                print(f"Unknown zone '{args.zone}'. Available: {list(KARNATAKA_ZONES.keys())}")
                print("Or specify --lat and --lon manually.")
                exit(1)
        
        generate_bdat(args.zone, lat, lon, args.years, args.tz, args.output)
