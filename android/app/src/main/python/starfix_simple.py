"""
Simplified Astronomical Navigation System
نظام ملاحة فلكية مبسط

A lightweight celestial position fixing system using star observations.
Core mathematical functions only - no external files or visualization.

© 2025, MIT License
Simplified for mobile integration
"""

from math import pi, sin, cos, acos, sqrt, tan, atan2, radians, degrees
from datetime import datetime, timedelta
from typing import Optional, Tuple, List


# =============================================================================
# Constants / الثوابت
# =============================================================================

EARTH_RADIUS_KM = 6371.0  # نصف قطر الأرض بالكيلومتر
EARTH_EQUATORIAL_RADIUS = 6378.137  # km - نصف القطر الاستوائي
EARTH_POLAR_RADIUS = 6356.752  # km - نصف القطر القطبي


# =============================================================================
# Core Classes / الفئات الأساسية
# =============================================================================

class LatLon:
    """
    Base class for latitude/longitude coordinates
    فئة أساسية لإحداثيات خطوط الطول والعرض
    """
    
    def __init__(self, lat: float, lon: float):
        """
        Initialize with latitude and longitude in degrees
        
        Args:
            lat: Latitude in degrees (-90 to +90) - خط العرض بالدرجات
            lon: Longitude in degrees (-180 to +180) - خط الطول بالدرجات
        """
        self.lat = lat
        self.lon = lon
    
    def get_lat(self) -> float:
        """Get latitude in degrees"""
        return self.lat
    
    def get_lon(self) -> float:
        """Get longitude in degrees"""
        return self.lon
    
    def __str__(self) -> str:
        lat_dir = 'N' if self.lat >= 0 else 'S'
        lon_dir = 'E' if self.lon >= 0 else 'W'
        return f"{abs(self.lat):.4f}°{lat_dir}, {abs(self.lon):.4f}°{lon_dir}"
    
    def __repr__(self) -> str:
        return f"LatLon({self.lat:.4f}, {self.lon:.4f})"


# =============================================================================
# Vector Mathematics / الرياضيات الاتجاهية
# =============================================================================

def to_rectangular(latlon: LatLon) -> List[float]:
    """
    Convert latitude/longitude to 3D rectangular coordinates on unit sphere
    تحويل خطوط الطول والعرض إلى إحداثيات مستطيلة ثلاثية الأبعاد
    
    Args:
        latlon: Latitude/longitude position
        
    Returns:
        [x, y, z] coordinates on unit sphere
    """
    lat_rad = radians(latlon.get_lat())
    lon_rad = radians(latlon.get_lon())
    
    x = cos(lat_rad) * cos(lon_rad)
    y = cos(lat_rad) * sin(lon_rad)
    z = sin(lat_rad)
    
    return [x, y, z]


def to_latlon(vec: List[float]) -> LatLon:
    """
    Convert 3D rectangular coordinates to latitude/longitude
    تحويل الإحداثيات المستطيلة إلى خطوط طول وعرض
    
    Args:
        vec: [x, y, z] coordinates
        
    Returns:
        LatLon object
    """
    x, y, z = vec
    
    # Normalize vector
    magnitude = sqrt(x**2 + y**2 + z**2)
    if magnitude == 0:
        raise ValueError("Zero vector cannot be converted to LatLon")
    
    x, y, z = x/magnitude, y/magnitude, z/magnitude
    
    # Calculate latitude and longitude
    lat = degrees(atan2(z, sqrt(x**2 + y**2)))
    lon = degrees(atan2(y, x))
    
    return LatLon(lat, lon)


def normalize_vect(vec: List[float]) -> List[float]:
    """
    Normalize a 3D vector to unit length
    تطبيع متجه إلى طول وحدة
    """
    magnitude = sqrt(sum(v**2 for v in vec))
    if magnitude == 0:
        return vec
    return [v / magnitude for v in vec]


def add_vecs(vec1: List[float], vec2: List[float]) -> List[float]:
    """
    Add two 3D vectors
    جمع متجهين
    """
    return [vec1[i] + vec2[i] for i in range(3)]


def mult_scalar_vect(scalar: float, vec: List[float]) -> List[float]:
    """
    Multiply vector by scalar
    ضرب متجه بعدد
    """
    return [scalar * v for v in vec]


def spherical_distance(latlon1: LatLon, latlon2: LatLon) -> float:
    """
    Calculate great circle distance between two points on Earth
    حساب المسافة الكروية بين نقطتين على الأرض
    
    Uses the haversine formula for accuracy
    يستخدم معادلة هافرسين للدقة
    
    Args:
        latlon1: First position
        latlon2: Second position
        
    Returns:
        Distance in kilometers
    """
    lat1 = radians(latlon1.get_lat())
    lon1 = radians(latlon1.get_lon())
    lat2 = radians(latlon2.get_lat())
    lon2 = radians(latlon2.get_lon())
    
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    
    # Haversine formula
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    
    return EARTH_RADIUS_KM * c


# =============================================================================
# Atmospheric Corrections / التصحيحات الجوية
# =============================================================================

def atmospheric_refraction(altitude_deg: float, temperature: float = 10.0, 
                          pressure: float = 101.0) -> float:
    """
    Calculate atmospheric refraction correction
    حساب تصحيح الانكسار الجوي
    
    Args:
        altitude_deg: Observed altitude in degrees
        temperature: Temperature in Celsius
        pressure: Pressure in kPa
        
    Returns:
        Refraction correction in degrees (to subtract from observed altitude)
    """
    if altitude_deg <= 0 or altitude_deg >= 90:
        return 0.0
    
    # Bennett's formula for atmospheric refraction
    h = altitude_deg
    
    # Basic refraction in arcminutes
    R = 1.0 / tan(radians(h + 7.31/(h + 4.4)))
    
    # Temperature and pressure correction
    temp_kelvin = temperature + 273.15
    R = R * (pressure / 101.0) * (283.0 / temp_kelvin)
    
    # Convert arcminutes to degrees
    return R / 60.0


def horizon_dip(observer_height_m: float) -> float:
    """
    Calculate horizon dip correction due to observer height
    حساب تصحيح انخفاض الأفق بسبب ارتفاع الراصد
    
    Args:
        observer_height_m: Observer height above sea level in meters
        
    Returns:
        Dip correction in degrees (to subtract from observed altitude)
    """
    if observer_height_m <= 0:
        return 0.0
    
    # Standard formula: dip in arcminutes = 1.76 * sqrt(height in meters)
    dip_arcmin = 1.76 * sqrt(observer_height_m)
    
    # Convert to degrees
    return dip_arcmin / 60.0


# =============================================================================
# Celestial Calculations / الحسابات الفلكية
# =============================================================================

def calculate_gha(ra: float, observation_time: datetime) -> float:
    """
    Calculate Greenwich Hour Angle from Right Ascension
    حساب زاوية الساعة في غرينتش من الصعود المستقيم
    
    Args:
        ra: Right Ascension in degrees
        observation_time: Time of observation
        
    Returns:
        GHA in degrees
    """
    # Calculate GMST (Greenwich Mean Sidereal Time)
    # Simplified calculation - for production use more accurate formula
    
    j2000 = datetime(2000, 1, 1, 12, 0, 0)
    days_since_j2000 = (observation_time - j2000).total_seconds() / 86400.0
    
    # GMST at 0h UT
    gmst = 280.46061837 + 360.98564736629 * days_since_j2000
    
    # Add time of day
    hours_since_midnight = (observation_time.hour + 
                           observation_time.minute/60.0 + 
                           observation_time.second/3600.0)
    gmst += hours_since_midnight * 15.0  # 15 degrees per hour
    
    # Normalize to 0-360
    gmst = gmst % 360
    
    # GHA = GMST - RA
    gha = (gmst - ra) % 360
    
    return gha


def calculate_lha(gha: float, observer_lon: float) -> float:
    """
    Calculate Local Hour Angle from GHA and observer longitude
    حساب زاوية الساعة المحلية
    
    Args:
        gha: Greenwich Hour Angle in degrees
        observer_lon: Observer longitude in degrees (positive East)
        
    Returns:
        LHA in degrees
    """
    lha = (gha + observer_lon) % 360
    return lha


def calculate_altitude_azimuth(dec: float, lha: float, observer_lat: float) -> Tuple[float, float]:
    """
    Calculate altitude and azimuth of celestial body
    حساب الارتفاع والسمت للجرم السماوي
    
    Args:
        dec: Declination in degrees
        lha: Local Hour Angle in degrees
        observer_lat: Observer latitude in degrees
        
    Returns:
        (altitude, azimuth) in degrees
    """
    dec_rad = radians(dec)
    lha_rad = radians(lha)
    lat_rad = radians(observer_lat)
    
    # Calculate altitude using spherical trigonometry
    sin_alt = (sin(lat_rad) * sin(dec_rad) + 
               cos(lat_rad) * cos(dec_rad) * cos(lha_rad))
    altitude = degrees(acos(max(-1, min(1, sin_alt)))) - 90  # Correct for acos output
    altitude = degrees(atan2(sin_alt, sqrt(1 - sin_alt**2)))
    
    # Calculate azimuth
    cos_az = (sin(dec_rad) - sin(lat_rad) * sin(radians(altitude))) / (cos(lat_rad) * cos(radians(altitude)))
    cos_az = max(-1, min(1, cos_az))  # Clamp to valid range
    
    azimuth = degrees(acos(cos_az))
    
    # Adjust azimuth based on LHA
    if sin(lha_rad) > 0:
        azimuth = 360 - azimuth
    
    return altitude, azimuth


# =============================================================================
# Sight Class / فئة الرصد
# =============================================================================

class Sight:
    """
    Represents a single celestial observation
    يمثل رصد فلكي واحد
    
    This class holds all data for one star observation and performs
    necessary corrections to get the true altitude.
    """
    
    def __init__(self,
                 ra: float,
                 dec: float,
                 altitude: float,
                 time: str,
                 observer_height: float = 0.0,
                 temperature: float = 10.0,
                 pressure: float = 101.0,
                 apply_refraction: bool = True,
                 apply_dip: bool = True):
        """
        Initialize a sight observation
        
        Args:
            ra: Right Ascension in degrees (0-360) - الصعود المستقيم
            dec: Declination in degrees (-90 to +90) - الميل
            altitude: Observed altitude in degrees (0-90) - الارتفاع المرصود
            time: Observation time as ISO format string - وقت الرصد
            observer_height: Observer height above sea level in meters
            temperature: Air temperature in Celsius
            pressure: Atmospheric pressure in kPa
            apply_refraction: Whether to apply refraction correction
            apply_dip: Whether to apply horizon dip correction
        """
        # Store celestial coordinates / تخزين الإحداثيات الفلكية
        self.ra = ra % 360  # Normalize to 0-360
        self.dec = dec
        
        if not -90 <= dec <= 90:
            raise ValueError(f"Declination must be between -90 and +90, got {dec}")
        
        # Parse observation time / تحليل وقت الرصد
        self.time = datetime.fromisoformat(time)
        
        # Store observed altitude / تخزين الارتفاع المرصود
        self.observed_altitude = altitude
        
        if not 0 < altitude < 90:
            raise ValueError(f"Altitude must be between 0 and 90 degrees, got {altitude}")
        
        # Store observation conditions
        self.observer_height = observer_height
        self.temperature = temperature
        self.pressure = pressure
        
        # Apply corrections to get true altitude / تطبيق التصحيحات
        self.corrected_altitude = altitude
        
        if apply_refraction:
            refraction = atmospheric_refraction(altitude, temperature, pressure)
            self.corrected_altitude -= refraction
        
        if apply_dip and observer_height > 0:
            dip = horizon_dip(observer_height)
            self.corrected_altitude -= dip
        
        # Calculate GHA at observation time / حساب زاوية الساعة في غرينتش
        self.gha = calculate_gha(ra, self.time)
    
    def get_gp(self) -> LatLon:
        """
        Get the Geographic Position (GP) of the celestial body
        الحصول على الموقع الجغرافي للجرم السماوي
        
        Returns:
            LatLon representing the GP
        """
        # GP latitude = declination
        # GP longitude = -GHA (measured westward from Greenwich)
        gp_lat = self.dec
        gp_lon = -self.gha
        
        # Normalize longitude to -180 to +180
        while gp_lon < -180:
            gp_lon += 360
        while gp_lon > 180:
            gp_lon -= 360
        
        return LatLon(gp_lat, gp_lon)
    
    def get_distance_from_gp(self) -> float:
        """
        Calculate the distance from observer to GP based on altitude
        حساب المسافة من الراصد إلى الموقع الجغرافي
        
        Returns:
            Distance in kilometers
        """
        # Co-altitude = 90 - altitude (in degrees)
        # Arc length = co-altitude converted to radians * Earth radius
        co_altitude = 90 - self.corrected_altitude
        distance = radians(co_altitude) * EARTH_RADIUS_KM
        return distance
    
    def __str__(self) -> str:
        return (f"Sight(RA={self.ra:.2f}°, Dec={self.dec:.2f}°, "
                f"Alt={self.corrected_altitude:.2f}°, Time={self.time})")
    
    def __repr__(self) -> str:
        return self.__str__()


# =============================================================================
# Circle of Position / دائرة الموقع
# =============================================================================

def calculate_circle_intersection(gp1: LatLon, dist1: float, 
                                  gp2: LatLon, dist2: float) -> Optional[Tuple[LatLon, LatLon]]:
    """
    Calculate intersection points of two circles of position
    حساب نقاط تقاطع دائرتي موقع
    
    Each circle represents all possible observer positions for one star observation.
    The intersection gives the possible observer positions.
    
    Args:
        gp1: Geographic Position of first star
        dist1: Distance from observer to first GP (km)
        gp2: Geographic Position of second star
        dist2: Distance from observer to second GP (km)
        
    Returns:
        Tuple of two LatLon intersection points, or None if no intersection
    """
    # Convert to rectangular coordinates
    vec1 = to_rectangular(gp1)
    vec2 = to_rectangular(gp2)
    
    # Convert distances to angular radii (radians)
    r1 = dist1 / EARTH_RADIUS_KM
    r2 = dist2 / EARTH_RADIUS_KM
    
    # Calculate angle between the two GPs
    dot_product = sum(vec1[i] * vec2[i] for i in range(3))
    dot_product = max(-1, min(1, dot_product))  # Clamp for numerical stability
    d = acos(dot_product)
    
    # Check if circles intersect
    if d > r1 + r2:  # Circles too far apart
        return None
    if d < abs(r1 - r2):  # One circle inside the other
        return None
    if d == 0 and abs(r1 - r2) > 1e-10:  # Same center but different radii
        return None
    
    # Calculate the intersection
    # Using spherical trigonometry
    cos_a = (cos(r1) - cos(r2) * cos(d)) / (sin(r2) * sin(d))
    cos_a = max(-1, min(1, cos_a))  # Clamp
    a = acos(cos_a)
    
    # Find perpendicular vector to the plane containing vec1 and vec2
    perp = [
        vec1[1]*vec2[2] - vec1[2]*vec2[1],
        vec1[2]*vec2[0] - vec1[0]*vec2[2],
        vec1[0]*vec2[1] - vec1[1]*vec2[0]
    ]
    perp = normalize_vect(perp)
    
    # Rotate vec1 around perp by angle a to get first intersection
    # This is a simplified approach - for production use full 3D rotation
    cos_a_val = cos(a)
    sin_a_val = sin(a)
    
    # First intersection point
    int1_vec = [
        vec1[i] * cos_a_val + perp[i] * sin_a_val * sin(d)
        for i in range(3)
    ]
    int1_vec = normalize_vect(int1_vec)
    
    # Second intersection point (rotate in opposite direction)
    int2_vec = [
        vec1[i] * cos_a_val - perp[i] * sin_a_val * sin(d)
        for i in range(3)
    ]
    int2_vec = normalize_vect(int2_vec)
    
    return to_latlon(int1_vec), to_latlon(int2_vec)


# =============================================================================
# SightCollection Class / فئة مجموعة الأرصاد
# =============================================================================

class SightCollection:
    """
    Collection of multiple sight observations for position fixing
    مجموعة من الأرصاد الفلكية لتحديد الموقع
    """
    
    def __init__(self, sights: List[Sight]):
        """
        Initialize with list of Sight objects
        
        Args:
            sights: List of at least 2 Sight objects
        """
        if len(sights) < 2:
            raise ValueError("SightCollection requires at least 2 sights")
        
        self.sights = sights
    
    def get_intersections(self, estimated_position: Optional[LatLon] = None) -> LatLon:
        """
        Calculate observer position from multiple sights
        حساب موقع الراصد من عدة أرصاد
        
        For 2 sights: returns the intersection closest to estimated position
        For 3+ sights: uses weighted average of all pairwise intersections
        
        Args:
            estimated_position: Estimated observer position (helps select correct intersection)
            
        Returns:
            Calculated observer position as LatLon
        """
        if len(self.sights) == 2:
            return self._calculate_two_sight_fix(estimated_position)
        else:
            return self._calculate_multi_sight_fix(estimated_position)
    
    def _calculate_two_sight_fix(self, estimated_position: Optional[LatLon]) -> LatLon:
        """
        Calculate position from exactly two sights
        حساب الموقع من رصدين فقط
        """
        sight1, sight2 = self.sights[0], self.sights[1]
        
        gp1 = sight1.get_gp()
        gp2 = sight2.get_gp()
        dist1 = sight1.get_distance_from_gp()
        dist2 = sight2.get_distance_from_gp()
        
        intersections = calculate_circle_intersection(gp1, dist1, gp2, dist2)
        
        if intersections is None:
            raise ValueError("No intersection found - circles don't meet")
        
        int1, int2 = intersections
        
        # If estimated position provided, choose closest intersection
        if estimated_position is not None:
            dist_to_int1 = spherical_distance(estimated_position, int1)
            dist_to_int2 = spherical_distance(estimated_position, int2)
            
            return int1 if dist_to_int1 < dist_to_int2 else int2
        else:
            # Return first intersection (arbitrary choice without estimate)
            return int1
    
    def _calculate_multi_sight_fix(self, estimated_position: Optional[LatLon]) -> LatLon:
        """
        Calculate position from three or more sights using pairwise intersections
        حساب الموقع من ثلاثة أرصاد أو أكثر
        """
        positions = []
        
        # Calculate all pairwise intersections
        for i in range(len(self.sights)):
            for j in range(i + 1, len(self.sights)):
                sight1, sight2 = self.sights[i], self.sights[j]
                
                gp1 = sight1.get_gp()
                gp2 = sight2.get_gp()
                dist1 = sight1.get_distance_from_gp()
                dist2 = sight2.get_distance_from_gp()
                
                intersections = calculate_circle_intersection(gp1, dist1, gp2, dist2)
                
                if intersections is not None:
                    int1, int2 = intersections
                    
                    # Choose intersection closest to estimated position
                    if estimated_position is not None:
                        dist_to_int1 = spherical_distance(estimated_position, int1)
                        dist_to_int2 = spherical_distance(estimated_position, int2)
                        
                        chosen = int1 if dist_to_int1 < dist_to_int2 else int2
                    else:
                        chosen = int1  # Arbitrary choice
                    
                    positions.append(chosen)
        
        if len(positions) == 0:
            raise ValueError("No valid intersections found")
        
        # Calculate weighted average position
        # Convert all positions to rectangular coordinates
        vectors = [to_rectangular(pos) for pos in positions]
        
        # Average the vectors
        avg_vector = [
            sum(vec[i] for vec in vectors) / len(vectors)
            for i in range(3)
        ]
        
        # Normalize and convert back to LatLon
        avg_vector = normalize_vect(avg_vector)
        return to_latlon(avg_vector)
    
    def calculate_position(self, estimated_position: Optional[LatLon] = None) -> dict:
        """
        Calculate position and return detailed results
        حساب الموقع وإرجاع نتائج مفصلة
        
        Returns:
            Dictionary with position and metadata
        """
        position = self.get_intersections(estimated_position)
        
        return {
            "latitude": position.get_lat(),
            "longitude": position.get_lon(),
            "position_string": str(position),
            "number_of_sights": len(self.sights),
            "observation_times": [sight.time.isoformat() for sight in self.sights]
        }


# =============================================================================
# Usage Example / مثال على الاستخدام
# =============================================================================

if __name__ == "__main__":
    print("Celestial Navigation Example / مثال على الملاحة الفلكية")
    print("=" * 60)
    
    # Example: Create sights for two stars
    # مثال: إنشاء رصدين لنجمين
    
    # Sirius observation / رصد الشعرى اليمانية
    sight1 = Sight(
        ra=101.2875,      # Right Ascension of Sirius
        dec=-16.7161,     # Declination of Sirius
        altitude=55.5,    # Observed altitude
        time="2024-05-05T22:00:00",
        observer_height=10.0  # 10 meters above sea level
    )
    
    # Canopus observation / رصد سهيل
    sight2 = Sight(
        ra=95.9879,       # Right Ascension of Canopus
        dec=-52.6957,     # Declination of Canopus
        altitude=40.2,    # Observed altitude
        time="2024-05-05T22:00:00",
        observer_height=10.0
    )
    
    print(f"\nSight 1: {sight1}")
    print(f"Sight 2: {sight2}")
    
    # Create collection and calculate position
    # إنشاء مجموعة وحساب الموقع
    collection = SightCollection([sight1, sight2])
    
    # Provide estimated position (e.g., from GPS or dead reckoning)
    # توفير موقع تقديري
    estimated_pos = LatLon(25.0, 50.0)  # Near Bahrain
    
    result = collection.calculate_position(estimated_position=estimated_pos)
    
    print("\n" + "=" * 60)
    print("Calculated Position / الموقع المحسوب:")
    print("=" * 60)
    print(f"Latitude:  {result['latitude']:.4f}°")
    print(f"Longitude: {result['longitude']:.4f}°")
    print(f"Position:  {result['position_string']}")
    print(f"Based on {result['number_of_sights']} observations")
    print("=" * 60)
