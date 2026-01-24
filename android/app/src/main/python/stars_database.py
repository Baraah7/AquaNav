"""
Lightweight Star and Celestial Body Database
قاعدة بيانات النجوم والأجرام السماوية

Contains coordinates for key navigation stars and celestial bodies
commonly used in astronomical navigation in the Gulf region.

© 2025, MIT License
"""

from typing import Dict, Optional


# =============================================================================
# Navigation Stars Database / قاعدة بيانات نجوم الملاحة
# =============================================================================

STARS_DB: Dict[str, Dict] = {
    # First Magnitude Stars / النجوم من الدرجة الأولى
    
    "Sirius": {
        "arabic": "الشعرى اليمانية",
        "ra": 101.2875,      # Right Ascension (degrees)
        "dec": -16.7161,     # Declination (degrees)
        "magnitude": -1.46,
        "type": "star",
        "constellation": "Canis Major"
    },
    
    "Canopus": {
        "arabic": "سهيل",
        "ra": 95.9879,
        "dec": -52.6957,
        "magnitude": -0.74,
        "type": "star",
        "constellation": "Carina"
    },
    
    "Arcturus": {
        "arabic": "السماك الرامح",
        "ra": 213.9153,
        "dec": 19.1824,
        "magnitude": -0.05,
        "type": "star",
        "constellation": "Boötes"
    },
    
    "Vega": {
        "arabic": "النسر الواقع",
        "ra": 279.2347,
        "dec": 38.7837,
        "magnitude": 0.03,
        "type": "star",
        "constellation": "Lyra"
    },
    
    "Capella": {
        "arabic": "العيوق",
        "ra": 79.1724,
        "dec": 45.9980,
        "magnitude": 0.08,
        "type": "star",
        "constellation": "Auriga"
    },
    
    "Rigel": {
        "arabic": "رجل الجوزاء",
        "ra": 78.6344,
        "dec": -8.2016,
        "magnitude": 0.13,
        "type": "star",
        "constellation": "Orion"
    },
    
    "Procyon": {
        "arabic": "الشعرى الشامية",
        "ra": 114.8253,
        "dec": 5.2250,
        "magnitude": 0.34,
        "type": "star",
        "constellation": "Canis Minor"
    },
    
    "Betelgeuse": {
        "arabic": "إبط الجوزاء",
        "ra": 88.7929,
        "dec": 7.4070,
        "magnitude": 0.50,
        "type": "star",
        "constellation": "Orion"
    },
    
    "Altair": {
        "arabic": "النسر الطائر",
        "ra": 297.6958,
        "dec": 8.8683,
        "magnitude": 0.77,
        "type": "star",
        "constellation": "Aquila"
    },
    
    "Aldebaran": {
        "arabic": "الدبران",
        "ra": 68.9802,
        "dec": 16.5093,
        "magnitude": 0.85,
        "type": "star",
        "constellation": "Taurus"
    },
    
    "Antares": {
        "arabic": "قلب العقرب",
        "ra": 247.3519,
        "dec": -26.4320,
        "magnitude": 1.06,
        "type": "star",
        "constellation": "Scorpius"
    },
    
    "Spica": {
        "arabic": "السماك الأعزل",
        "ra": 201.2983,
        "dec": -11.1614,
        "magnitude": 1.04,
        "type": "star",
        "constellation": "Virgo"
    },
    
    "Pollux": {
        "arabic": "الذراع المقبوضة",
        "ra": 116.3289,
        "dec": 28.0262,
        "magnitude": 1.14,
        "type": "star",
        "constellation": "Gemini"
    },
    
    "Fomalhaut": {
        "arabic": "فم الحوت",
        "ra": 344.4127,
        "dec": -29.6222,
        "magnitude": 1.16,
        "type": "star",
        "constellation": "Piscis Austrinus"
    },
    
    "Deneb": {
        "arabic": "ذنب الدجاجة",
        "ra": 310.3580,
        "dec": 45.2803,
        "magnitude": 1.25,
        "type": "star",
        "constellation": "Cygnus"
    },
    
    # Additional useful stars / نجوم إضافية مفيدة
    
    "Polaris": {
        "arabic": "النجم القطبي",
        "ra": 37.9545,
        "dec": 89.2641,
        "magnitude": 1.98,
        "type": "star",
        "constellation": "Ursa Minor",
        "note": "North Star - very useful for latitude determination"
    },
    
    "Regulus": {
        "arabic": "قلب الأسد",
        "ra": 152.0929,
        "dec": 11.9672,
        "magnitude": 1.35,
        "type": "star",
        "constellation": "Leo"
    },
    
    "Castor": {
        "arabic": "رأس التوأم المقدم",
        "ra": 113.6494,
        "dec": 31.8883,
        "magnitude": 1.58,
        "type": "star",
        "constellation": "Gemini"
    }
}


# =============================================================================
# Planets Database (Approximate) / قاعدة بيانات الكواكب (تقريبية)
# =============================================================================

# Note: Planet positions change constantly. These are example values only.
# For real navigation, use ephemeris data or astronomical calculations.
# ملاحظة: مواقع الكواكب تتغير باستمرار. هذه قيم توضيحية فقط.

PLANETS_DB: Dict[str, Dict] = {
    "Venus": {
        "arabic": "الزهرة",
        "type": "planet",
        "magnitude": -4.0,
        "note": "Position varies - use ephemeris data"
    },
    
    "Mars": {
        "arabic": "المريخ",
        "type": "planet",
        "magnitude": 0.0,
        "note": "Position varies - use ephemeris data"
    },
    
    "Jupiter": {
        "arabic": "المشتري",
        "type": "planet",
        "magnitude": -2.0,
        "note": "Position varies - use ephemeris data"
    },
    
    "Saturn": {
        "arabic": "زحل",
        "type": "planet",
        "magnitude": 0.5,
        "note": "Position varies - use ephemeris data"
    }
}


# =============================================================================
# Lookup Functions / وظائف البحث
# =============================================================================

def get_star_by_name(name: str) -> Optional[Dict]:
    """
    Get star data by name (case-insensitive)
    الحصول على بيانات النجم بالاسم
    
    Args:
        name: Star name in English
        
    Returns:
        Dictionary with star data or None if not found
    """
    name_upper = name.upper()
    
    for star_name, star_data in STARS_DB.items():
        if star_name.upper() == name_upper:
            return {**star_data, "name": star_name}
    
    return None


def get_star_by_arabic_name(arabic_name: str) -> Optional[Dict]:
    """
    Get star data by Arabic name
    الحصول على بيانات النجم بالاسم العربي
    
    Args:
        arabic_name: Star name in Arabic
        
    Returns:
        Dictionary with star data or None if not found
    """
    for star_name, star_data in STARS_DB.items():
        if star_data.get("arabic") == arabic_name:
            return {**star_data, "name": star_name}
    
    return None


def get_celestial_body(name: str) -> Optional[Dict]:
    """
    Get celestial body data (star or planet) by name
    الحصول على بيانات الجرم السماوي (نجم أو كوكب)
    
    Args:
        name: Body name in English
        
    Returns:
        Dictionary with body data or None if not found
    """
    # Try stars first
    star = get_star_by_name(name)
    if star:
        return star
    
    # Then try planets
    name_upper = name.upper()
    for planet_name, planet_data in PLANETS_DB.items():
        if planet_name.upper() == name_upper:
            return {**planet_data, "name": planet_name}
    
    return None


def list_navigation_stars(min_magnitude: float = 2.0) -> list:
    """
    List all navigation stars brighter than specified magnitude
    قائمة بنجوم الملاحة الأكثر سطوعاً من القدر المحدد
    
    Args:
        min_magnitude: Maximum magnitude (lower is brighter)
        
    Returns:
        List of star dictionaries sorted by brightness
    """
    stars = []
    
    for star_name, star_data in STARS_DB.items():
        if star_data.get("magnitude", 99) <= min_magnitude:
            stars.append({**star_data, "name": star_name})
    
    # Sort by magnitude (brightest first)
    stars.sort(key=lambda x: x.get("magnitude", 99))
    
    return stars


def get_stars_in_region(ra_min: float, ra_max: float, 
                        dec_min: float, dec_max: float) -> list:
    """
    Get stars in a specific region of sky
    الحصول على النجوم في منطقة محددة من السماء
    
    Args:
        ra_min: Minimum Right Ascension (degrees)
        ra_max: Maximum Right Ascension (degrees)
        dec_min: Minimum Declination (degrees)
        dec_max: Maximum Declination (degrees)
        
    Returns:
        List of stars in the region
    """
    stars = []
    
    for star_name, star_data in STARS_DB.items():
        ra = star_data.get("ra", 0)
        dec = star_data.get("dec", 0)
        
        if ra_min <= ra <= ra_max and dec_min <= dec <= dec_max:
            stars.append({**star_data, "name": star_name})
    
    return stars


def star_exists(name: str) -> bool:
    """
    Check if a star exists in database
    التحقق من وجود نجم في قاعدة البيانات
    
    Args:
        name: Star name
        
    Returns:
        True if star exists, False otherwise
    """
    return get_celestial_body(name) is not None


def get_star_coordinates(name: str) -> Optional[tuple]:
    """
    Get RA and DEC coordinates for a star
    الحصول على إحداثيات RA و DEC للنجم
    
    Args:
        name: Star name
        
    Returns:
        Tuple of (ra, dec) or None if not found
    """
    star = get_celestial_body(name)
    
    if star and "ra" in star and "dec" in star:
        return (star["ra"], star["dec"])
    
    return None


# =============================================================================
# Usage Example / مثال على الاستخدام
# =============================================================================

if __name__ == "__main__":
    print("Star Database Example / مثال على قاعدة بيانات النجوم")
    print("=" * 70)
    
    # List brightest navigation stars
    print("\nBrightest Navigation Stars:")
    bright_stars = list_navigation_stars(min_magnitude=1.5)
    for i, star in enumerate(bright_stars[:5], 1):
        print(f"{i}. {star['name']} ({star['arabic']}): "
              f"RA={star['ra']:.2f}°, Dec={star['dec']:.2f}°, "
              f"Mag={star['magnitude']}")
    
    # Look up specific star
    print("\n" + "=" * 70)
    print("Looking up Sirius / البحث عن الشعرى اليمانية:")
    sirius = get_star_by_name("Sirius")
    if sirius:
        print(f"  Name: {sirius['name']}")
        print(f"  Arabic: {sirius['arabic']}")
        print(f"  RA: {sirius['ra']:.4f}°")
        print(f"  Dec: {sirius['dec']:.4f}°")
        print(f"  Magnitude: {sirius['magnitude']}")
        print(f"  Constellation: {sirius['constellation']}")
    
    # Look up by Arabic name
    print("\n" + "=" * 70)
    print("Looking up by Arabic name / البحث بالاسم العربي:")
    suhail = get_star_by_arabic_name("سهيل")
    if suhail:
        print(f"  {suhail['arabic']} = {suhail['name']}")
        print(f"  RA: {suhail['ra']:.4f}°, Dec: {suhail['dec']:.4f}°")
    
    # Get coordinates
    print("\n" + "=" * 70)
    coords = get_star_coordinates("Vega")
    if coords:
        print(f"Vega coordinates: RA={coords[0]:.2f}°, Dec={coords[1]:.2f}°")
    
    print("\n" + "=" * 70)
