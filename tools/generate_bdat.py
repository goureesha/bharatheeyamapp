"""
Bharatheeyam Panchanga Data Generator
Generates .bdat files for the Bharatheeyam app.
Uses PyEphem for astronomical calculations.

Usage:
  pip install ephem
  python generate_bdat.py --zone Bengaluru --years 20
  python generate_bdat.py --all-zones --years 20
"""

import argparse
import json
import gzip
import math
import os
from datetime import datetime, timedelta

import ephem

# ─── Ayanamsha (Lahiri) ─────────────────────────────────────

def lahiri_ayanamsha(jd):
    """Calculate Lahiri Ayanamsha for a given Julian Day.
    Approximation using IAU 2006 precession model.
    Reference epoch J2000.0 = JD 2451545.0, ayanamsha = 23.8530°
    Rate ~50.29 arcseconds per year.
    """
    T = (jd - 2451545.0) / 36525.0  # Julian centuries from J2000
    # Lahiri ayanamsha at J2000 ≈ 23.853°, rate ≈ 50.29"/year
    ayan = 23.853 + (50.29 * T * 100) / 3600.0
    return ayan

def tropical_to_sidereal(tropical_lon, jd):
    """Convert tropical longitude to sidereal (Lahiri)"""
    ayan = lahiri_ayanamsha(jd)
    sid = (tropical_lon - ayan + 360) % 360
    return sid

# ─── Kannada names ───────────────────────────────────────────

KN_TITHI = [
    'ಪಾಡ್ಯಮಿ', 'ಬಿದಿಗೆ', 'ತದಿಗೆ', 'ಚವತಿ', 'ಪಂಚಮಿ',
    'ಷಷ್ಠೀ', 'ಸಪ್ತಮೀ', 'ಅಷ್ಟಮೀ', 'ನವಮೀ', 'ದಶಮೀ',
    'ಏಕಾದಶೀ', 'ದ್ವಾದಶೀ', 'ತ್ರಯೋದಶೀ', 'ಚತುರ್ದಶೀ', 'ಹುಣ್ಣಿಮೆ',
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

# Soura Masa = Sun's Rashi name (same as KN_RASHI)
KN_SOURA_MASA = KN_RASHI

# Chandra Masa (Amavasyanta, indexed by Sun's Rashi at previous Amavasya)
KN_CHANDRA_MASA = [
    'ವೈಶಾಖ', 'ಜ್ಯೇಷ್ಠ', 'ಆಷಾಢ', 'ಶ್ರಾವಣ', 'ಭಾದ್ರಪದ', 'ಆಶ್ವಿನ',
    'ಕಾರ್ತಿಕ', 'ಮಾರ್ಗಶಿರ', 'ಪುಷ್ಯ', 'ಮಾಘ', 'ಫಾಲ್ಗುಣ', 'ಚೈತ್ರ',
]

# Samvatsara (60-year cycle)
KN_SAMVATSARA = [
    'ಪ್ರಭವ','ವಿಭವ','ಶುಕ್ಲ','ಪ್ರಮೋದೂತ','ಪ್ರಜೋತ್ಪತ್ತಿ','ಆಂಗೀರಸ','ಶ್ರೀಮುಖ','ಭಾವ','ಯುವ','ಧಾತೃ',
    'ಈಶ್ವರ','ಬಹುಧಾನ್ಯ','ಪ್ರಮಾಥಿ','ವಿಕ್ರಮ','ವೃಷ','ಚಿತ್ರಭಾನು','ಸುಭಾನು','ತಾರಣ','ಪಾರ್ಥಿವ','ವ್ಯಯ',
    'ಸರ್ವಜಿತ್','ಸರ್ವಧಾರಿ','ವಿರೋಧಿ','ವಿಕೃತಿ','ಖರ','ನಂದನ','ವಿಜಯ','ಜಯ','ಮನ್ಮಥ','ದುರ್ಮುಖಿ',
    'ಹೇವಿಳಂಬಿ','ವಿಳಂಬಿ','ವಿಕಾರಿ','ಶಾರ್ವರಿ','ಪ್ಲವ','ಶುಭಕೃತ್','ಶೋಭಕೃತ್','ಕ್ರೋಧಿ','ವಿಶ್ವಾವಸು','ಪರಾಭವ',
    'ಪ್ಲವಂಗ','ಕೀಲಕ','ಸೌಮ್ಯ','ಸಾಧಾರಣ','ವಿರೋಧಕೃತ್','ಪರಿಧಾವಿ','ಪ್ರಮಾದೀಚ','ಆನಂದ','ರಾಕ್ಷಸ','ಅನಲ',
    'ಪಿಂಗಳ','ಕಾಳಯುಕ್ತಿ','ಸಿದ್ಧಾರ್ಥಿ','ರೌದ್ರಿ','ದುರ್ಮತಿ','ದುಂದುಭಿ','ರುಧಿರೋದ್ಗಾರಿ','ರಕ್ತಾಕ್ಷಿ','ಕ್ರೋಧನ','ಅಕ್ಷಯ',
]

# ─── PyEphem Helpers ─────────────────────────────────────────

def get_observer(lat, lon, date_obj):
    """Create PyEphem observer"""
    obs = ephem.Observer()
    obs.lat = str(lat)
    obs.lon = str(lon)
    obs.date = date_obj
    obs.elevation = 0
    obs.pressure = 0  # No atmospheric refraction (user request!)
    obs.horizon = '0'  # Geometric horizon
    return obs

def get_planet_lon(body, date_ephem, jd):
    """Get sidereal longitude of a body at given ephem date"""
    body.compute(date_ephem)
    trop_lon_deg = math.degrees(float(body.ra))
    # Actually, ephem gives ecliptic longitude via body.hlong or we need to compute
    # For Sun: use body.ra is RA not ecliptic longitude
    # Use ephem's ecliptic coordinates
    eq = ephem.Equatorial(body.ra, body.dec, epoch=date_ephem)
    ecl = ephem.Ecliptic(eq, epoch=date_ephem)
    trop_lon = math.degrees(float(ecl.lon))
    return tropical_to_sidereal(trop_lon, jd)

def find_sunrise_sunset(lat, lon, year, month, day, tz_offset=5.5):
    """Find sunrise and sunset times. Returns (sunrise_str, sunset_str)"""
    obs = ephem.Observer()
    obs.lat = str(lat)
    obs.lon = str(lon)
    obs.elevation = 0
    obs.pressure = 0  # No refraction
    obs.horizon = '-0:34'  # Disc center with standard semi-diameter
    # Actually user wants NO refraction, geometric horizon = 0 degrees
    obs.horizon = '0'
    
    # Set to midnight UTC of the given date
    obs.date = f'{year}/{month}/{day} 00:00:00'
    
    sun = ephem.Sun()
    
    try:
        rise = obs.next_rising(sun, use_center=True)
        rise_local = ephem.Date(rise + tz_offset / 24.0)
        rise_tuple = ephem.Date(rise_local).tuple()
        rise_str = f"{int(rise_tuple[3]):02d}:{int(rise_tuple[4]):02d}"
    except:
        rise_str = "06:00"
        rise = obs.date + 0.25
    
    try:
        sett = obs.next_setting(sun, use_center=True)
        set_local = ephem.Date(sett + tz_offset / 24.0)
        set_tuple = ephem.Date(set_local).tuple()
        set_str = f"{int(set_tuple[3]):02d}:{int(set_tuple[4]):02d}"
    except:
        set_str = "18:00"
        sett = obs.date + 0.75
    
    return rise_str, set_str, rise

def jd_from_ephem(ephem_date):
    """Convert PyEphem date to Julian Day"""
    return float(ephem_date) + 2415020.0

def ephem_date_to_time_str(ed, tz_offset=5.5):
    """Convert ephem date to local time string"""
    local = ephem.Date(ed + tz_offset / 24.0)
    t = local.tuple()
    return f"{int(t[3]):02d}:{int(t[4]):02d}"

def compute_day(year, month, day, lat, lon, tz_offset=5.5):
    """Compute all panchanga data for a single day"""
    # Sunrise
    rise_str, set_str, rise_ephem = find_sunrise_sunset(lat, lon, year, month, day, tz_offset)
    
    # Compute at sunrise
    jd = jd_from_ephem(rise_ephem)
    
    sun = ephem.Sun()
    moon = ephem.Moon()
    jupiter = ephem.Jupiter()
    venus = ephem.Venus()
    
    sun.compute(rise_ephem)
    moon.compute(rise_ephem)
    jupiter.compute(rise_ephem)
    venus.compute(rise_ephem)
    
    # Ecliptic longitudes (tropical)
    sun_ecl = ephem.Ecliptic(ephem.Equatorial(sun.ra, sun.dec, epoch=rise_ephem), epoch=rise_ephem)
    moon_ecl = ephem.Ecliptic(ephem.Equatorial(moon.ra, moon.dec, epoch=rise_ephem), epoch=rise_ephem)
    jup_ecl = ephem.Ecliptic(ephem.Equatorial(jupiter.ra, jupiter.dec, epoch=rise_ephem), epoch=rise_ephem)
    ven_ecl = ephem.Ecliptic(ephem.Equatorial(venus.ra, venus.dec, epoch=rise_ephem), epoch=rise_ephem)
    
    sun_trop = math.degrees(float(sun_ecl.lon))
    moon_trop = math.degrees(float(moon_ecl.lon))
    jup_trop = math.degrees(float(jup_ecl.lon))
    ven_trop = math.degrees(float(ven_ecl.lon))
    
    # Convert to sidereal
    sun_lon = tropical_to_sidereal(sun_trop, jd)
    moon_lon = tropical_to_sidereal(moon_trop, jd)
    jup_lon = tropical_to_sidereal(jup_trop, jd)
    ven_lon = tropical_to_sidereal(ven_trop, jd)
    
    # ─── Tithi (0-29) ───
    tithi_diff = (moon_lon - sun_lon + 360) % 360
    tithi_idx = int(tithi_diff / 12)
    if tithi_idx >= 30: tithi_idx = 29
    tithi_name = KN_TITHI[tithi_idx]
    
    # ─── Nakshatra (0-26) ───
    nak_span = 360.0 / 27.0
    nak_idx = int(moon_lon / nak_span) % 27
    nak_name = KN_NAK[nak_idx]
    nak_percent = (moon_lon % nak_span) / nak_span
    pada = min(int(nak_percent * 4) + 1, 4)
    
    # ─── Yoga (0-26) ───
    yoga_val = (sun_lon + moon_lon) % 360
    yoga_idx = int(yoga_val / nak_span) % 27
    yoga_name = KN_YOGA[yoga_idx]
    
    # ─── Karana ───
    karana_val = tithi_idx * 2 + (1 if (tithi_diff % 12) >= 6 else 0)
    if karana_val >= 57:
        fixed = [KN_KARANA[7], KN_KARANA[8], KN_KARANA[9], KN_KARANA[10]]
        karana_name = fixed[karana_val - 57] if (karana_val - 57) < 4 else KN_KARANA[0]
    else:
        karana_name = KN_KARANA[karana_val % 7]
    
    # ─── Vara ───
    dt = datetime(year, month, day)
    vara_idx = (dt.weekday() + 1) % 7  # Mon=0 → Sun=0
    vara_name = KN_VARA[vara_idx]
    
    # ─── Rashi ───
    sun_rashi = int(sun_lon / 30) % 12
    moon_rashi = int(moon_lon / 30) % 12
    jup_rashi = int(jup_lon / 30) % 12
    
    # ─── Combustion ───
    sun_ven_diff = abs(sun_trop - ven_trop)
    if sun_ven_diff > 180: sun_ven_diff = 360 - sun_ven_diff
    venus_combust = sun_ven_diff < 10
    
    sun_jup_diff = abs(sun_trop - jup_trop)
    if sun_jup_diff > 180: sun_jup_diff = 360 - sun_jup_diff
    guru_combust = sun_jup_diff < 11
    
    # ─── End times (approximate using stepping) ───
    tithi_end = _find_tithi_end(rise_ephem, tithi_idx, jd, tz_offset)
    nak_end = _find_nak_end(rise_ephem, nak_idx, jd, tz_offset)
    
    # ─── Chandra Rashi ───
    chandra_rashi = KN_RASHI[moon_rashi]
    
    # ─── Soura Masa (Sun's Rashi) ───
    soura_masa = KN_SOURA_MASA[sun_rashi]
    
    # ─── Chandra Masa (Amavasyanta system) ───
    chandra_masa = _compute_chandra_masa(rise_ephem, tithi_idx, sun_lon)
    
    # ─── Samvatsara (60-year cycle, Shalivahana Shaka) ───
    samvatsara = _compute_samvatsara(year, month, chandra_masa)
    
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
        rise_str, set_str,
        round(sun_lon * 100) / 100.0,
        round(moon_lon * 100) / 100.0,
        round(jup_lon * 100) / 100.0,
        pada, tithi_end, nak_end,
        round(nak_percent * 1000) / 1000.0,
        chandra_rashi,
        chandra_masa, soura_masa, samvatsara,
    ]

def _get_sid_lon(body, ephem_date, jd):
    """Get sidereal longitude at a given ephem date"""
    body.compute(ephem_date)
    ecl = ephem.Ecliptic(ephem.Equatorial(body.ra, body.dec, epoch=ephem_date), epoch=ephem_date)
    trop = math.degrees(float(ecl.lon))
    return tropical_to_sidereal(trop, jd)

def _find_tithi_end(start_ephem, tithi_idx, jd_start, tz_offset):
    """Find when current tithi ends"""
    ed = start_ephem
    sun = ephem.Sun()
    moon = ephem.Moon()
    step = 1.0 / 24.0  # 1 hour
    
    for _ in range(50):
        ed_next = ephem.Date(ed + step)
        jd_next = jd_from_ephem(ed_next)
        
        s_lon = _get_sid_lon(sun, ed_next, jd_next)
        m_lon = _get_sid_lon(moon, ed_next, jd_next)
        diff = (m_lon - s_lon + 360) % 360
        cur = int(diff / 12)
        if cur >= 30: cur = 29
        
        if cur != tithi_idx:
            # Binary search
            lo, hi = ed, ed_next
            for _ in range(20):
                mid = ephem.Date((float(lo) + float(hi)) / 2)
                jd_m = jd_from_ephem(mid)
                s = _get_sid_lon(sun, mid, jd_m)
                m = _get_sid_lon(moon, mid, jd_m)
                d = (m - s + 360) % 360
                t = int(d / 12)
                if t >= 30: t = 29
                if t == tithi_idx:
                    lo = mid
                else:
                    hi = mid
            return ephem_date_to_time_str(hi, tz_offset)
        ed = ed_next
    return '--:--'

def _find_nak_end(start_ephem, nak_idx, jd_start, tz_offset):
    """Find when current nakshatra ends"""
    ed = start_ephem
    moon = ephem.Moon()
    nak_span = 360.0 / 27.0
    step = 1.0 / 24.0
    
    for _ in range(50):
        ed_next = ephem.Date(ed + step)
        jd_next = jd_from_ephem(ed_next)
        m_lon = _get_sid_lon(moon, ed_next, jd_next)
        cur = int(m_lon / nak_span) % 27
        
        if cur != nak_idx:
            lo, hi = ed, ed_next
            for _ in range(20):
                mid = ephem.Date((float(lo) + float(hi)) / 2)
                jd_m = jd_from_ephem(mid)
                m = _get_sid_lon(moon, mid, jd_m)
                t = int(m / nak_span) % 27
                if t == nak_idx:
                    lo = mid
                else:
                    hi = mid
            return ephem_date_to_time_str(hi, tz_offset)
        ed = ed_next
    return '--:--'

def _compute_chandra_masa(rise_ephem, tithi_idx, sun_lon):
    """Compute Chandra Masa (Pournimanta system).
    
    Pournimanta: month runs from Purnima to Purnima.
    Krishna Paksha comes first, then Shukla Paksha.
    In Pournimanta, Krishna paksha dates belong to the NEXT month.
    Output matches Dart app format: 'ನಿಜ ವೈಶಾಖ' or 'ಅಧಿಕ ವೈಶಾಖ'
    """
    try:
        # Find previous and next new moons
        prev_nm = ephem.previous_new_moon(rise_ephem)
        next_nm = ephem.next_new_moon(rise_ephem)
        
        # Sun's sidereal rashi at previous new moon
        jd_prev = jd_from_ephem(prev_nm)
        sun_prev = ephem.Sun()
        sun_prev.compute(prev_nm)
        ecl_prev = ephem.Ecliptic(ephem.Equatorial(sun_prev.ra, sun_prev.dec, epoch=prev_nm), epoch=prev_nm)
        sun_prev_sid = tropical_to_sidereal(math.degrees(float(ecl_prev.lon)), jd_prev)
        prev_rashi = int(sun_prev_sid / 30) % 12
        
        # Sun's sidereal rashi at next new moon
        jd_next = jd_from_ephem(next_nm)
        sun_next = ephem.Sun()
        sun_next.compute(next_nm)
        ecl_next = ephem.Ecliptic(ephem.Equatorial(sun_next.ra, sun_next.dec, epoch=next_nm), epoch=next_nm)
        sun_next_sid = tropical_to_sidereal(math.degrees(float(ecl_next.lon)), jd_next)
        next_rashi = int(sun_next_sid / 30) % 12
        
        # Check Adhika/Nija (Sankranti check)
        has_sankranti = (prev_rashi != next_rashi)
        
        # Pournimanta: Krishna paksha (tithi 15-29) belongs to next month
        if tithi_idx >= 15:
            masa_rashi = (prev_rashi + 1) % 12
        else:
            masa_rashi = prev_rashi
        
        masa_name = KN_CHANDRA_MASA[masa_rashi]
        
        if has_sankranti:
            return f"\u0ca8\u0cbf\u0c9c {masa_name}"   # ನಿಜ
        else:
            return f"\u0c85\u0ca7\u0cbf\u0c95 {masa_name}"  # ಅಧಿಕ
    except Exception:
        # Fallback: simple sun rashi mapping
        sun_rashi = int(sun_lon / 30) % 12
        if tithi_idx >= 15:
            masa_rashi = (sun_rashi + 1) % 12
        else:
            masa_rashi = sun_rashi
        return f"\u0ca8\u0cbf\u0c9c {KN_CHANDRA_MASA[masa_rashi]}"

def _compute_samvatsara(year, month, chandra_masa):
    """Compute Samvatsara (60-year Shalivahana Shaka cycle).
    Current samvatsara (2026) = Parabhava.
    """
    shaka_year = year - 78
    
    # Shaka year increments at Ugadi (Chaitra Shukla Pratipada)
    # If we're in months before Chaitra in the early part of Gregorian year,
    # the Shaka year hasn't incremented yet
    old_year_months = ['ಮಾರ್ಗಶಿರ', 'ಪುಷ್ಯ', 'ಮಾಘ', 'ಫಾಲ್ಗುಣ']
    # Strip Adhika prefix for comparison
    masa_clean = chandra_masa.replace('ಅಧಿಕ ', '')
    before_ugadi = month <= 5 and masa_clean in old_year_months
    
    if before_ugadi:
        shaka_year -= 1
    
    samvatsara_idx = (shaka_year + 11) % 60
    return f"{KN_SAMVATSARA[samvatsara_idx]} (ಶಕ {shaka_year})"

# ─── Main ────────────────────────────────────────────────────

def generate_bdat(zone_name, lat, lon, years, tz_offset=5.5, output_dir='.'):
    """Generate .bdat file for a zone"""
    now = datetime.now()
    start = datetime(now.year, now.month, now.day)
    end = start + timedelta(days=365 * years)
    
    total_days = (end - start).days + 1
    days = []
    
    print(f"\n{'='*60}")
    print(f"  Generating: {zone_name}")
    print(f"  Location:   {lat}°N, {lon}°E")
    print(f"  Period:     {start.strftime('%Y-%m-%d')} to {end.strftime('%Y-%m-%d')}")
    print(f"  Total days: {total_days}")
    print(f"{'='*60}")
    
    cur = start
    count = 0
    errors = 0
    while cur <= end:
        try:
            day_data = compute_day(cur.year, cur.month, cur.day, lat, lon, tz_offset)
            days.append(day_data)
        except Exception as e:
            errors += 1
            if errors <= 5:
                print(f"  ERROR on {cur}: {e}")
        
        count += 1
        if count % 500 == 0:
            pct = (count / total_days) * 100
            print(f"  [{pct:5.1f}%] {count}/{total_days} days...")
        
        cur += timedelta(days=1)
    
    # Build JSON
    data = {
        'v': 3,
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
    print(f"  Days: {len(days)} | Errors: {errors}")
    print(f"  Raw: {raw_mb:.2f} MB | Compressed: {comp_mb:.2f} MB")
    print(f"  File: {filepath}")
    
    return filepath

# ─── Karnataka Zones ─────────────────────────────────────────

KARNATAKA_ZONES = {
    'Kalaburagi': (17.33, 76.83),
    'Bengaluru':  (12.97, 77.59),
    'Mysuru':     (12.30, 76.66),
    'Shivamogga': (13.93, 75.57),
    'Mangaluru':  (12.87, 74.88),
}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate Bharatheeyam Panchanga .bdat files')
    parser.add_argument('--zone', type=str, default='Bengaluru', help='Zone name')
    parser.add_argument('--lat', type=float, help='Latitude')
    parser.add_argument('--lon', type=float, help='Longitude')
    parser.add_argument('--years', type=int, default=20, help='Years to generate')
    parser.add_argument('--tz', type=float, default=5.5, help='Timezone UTC offset')
    parser.add_argument('--all-zones', action='store_true', help='Generate all Karnataka zones')
    parser.add_argument('--output', type=str, default='.', help='Output directory')
    
    args = parser.parse_args()
    
    os.makedirs(args.output, exist_ok=True)
    
    if args.all_zones:
        print("\n" + "=" * 60)
        print("  GENERATING ALL KARNATAKA ZONES")
        print("=" * 60)
        for zone_name, (lat, lon) in KARNATAKA_ZONES.items():
            generate_bdat(zone_name, lat, lon, args.years, args.tz, args.output)
    else:
        lat = args.lat
        lon = args.lon
        if lat is None or lon is None:
            if args.zone in KARNATAKA_ZONES:
                lat, lon = KARNATAKA_ZONES[args.zone]
            else:
                print(f"Unknown zone '{args.zone}'. Available: {list(KARNATAKA_ZONES.keys())}")
                exit(1)
        generate_bdat(args.zone, lat, lon, args.years, args.tz, args.output)
    
    print("\nAll done!")
