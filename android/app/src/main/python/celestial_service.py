"""
Celestial Navigation Service
خدمة الملاحة الفلكية

Unified service that orchestrates star detection and position calculation.
Connects Tetra3 detection with celestial navigation calculations.

© 2025, MIT License
"""

import json
from typing import Dict, List, Optional
from datetime import datetime

from starfix_simple import Sight, SightCollection, LatLon
from tetra3_service import create_tetra3_service
from stars_database import get_star_coordinates, get_star_by_name, STARS_DB


class CelestialNavigationService:
    """
    Main service for astronomical navigation
    الخدمة الرئيسية للملاحة الفلكية
    
    This service provides a complete workflow:
    1. Detect stars from camera image (using Tetra3)
    2. Get user-measured altitudes for detected stars
    3. Calculate observer position
    """
    
    def __init__(self, use_mock_tetra3: bool = False):
        """
        Initialize celestial navigation service
        
        Args:
            use_mock_tetra3: If True, use mock Tetra3 for testing
        """
        self.tetra3_service = create_tetra3_service(use_mock=use_mock_tetra3)
        print("Celestial Navigation Service initialized")
        print("تم تهيئة خدمة الملاحة الفلكية")
    
    def process_image(self, 
                     image_path: str,
                     user_altitudes: Optional[Dict[str, float]] = None,
                     observation_time: Optional[str] = None,
                     estimated_position: Optional[Dict] = None,
                     observer_height: float = 0.0,
                     temperature: float = 10.0,
                     pressure: float = 101.0) -> Dict:
        """
        Complete workflow: detect stars from image and calculate position
        سير عمل كامل: كشف النجوم من الصورة وحساب الموقع
        
        Args:
            image_path: Path to star field image
            user_altitudes: Dict mapping star names to measured altitudes
                          e.g., {"Sirius": 55.5, "Canopus": 40.2}
            observation_time: ISO format time string (uses now if None)
            estimated_position: Dict with 'lat' and 'lon' keys
            observer_height: Observer height above sea level (meters)
            temperature: Air temperature (Celsius)
            pressure: Atmospheric pressure (kPa)
            
        Returns:
            Dictionary with detection results and calculated position
        """
        result = {
            'success': False,
            'message': '',
            'detected_stars': [],
            'used_sights': [],
            'calculated_position': None,
            'metadata': {}
        }
        
        # Step 1: Detect stars from image
        detection = self.tetra3_service.detect_stars_from_file(image_path)
        
        if not detection or not detection.get('success'):
            result['message'] = 'Failed to detect stars in image'
            return result
        
        result['detected_stars'] = detection['stars']
        result['metadata']['detection'] = detection['metadata']
        
        # Step 2: Prepare observation time
        if observation_time is None:
            observation_time = datetime.now().isoformat()
        
        # Step 3: Create sights for stars with altitudes
        sights = []
        
        for star in detection['stars']:
            star_name = star.get('name')
            if not star_name:
                continue
            
            # Get altitude from user input
            altitude = None
            if user_altitudes and star_name in user_altitudes:
                altitude = user_altitudes[star_name]
            
            # Skip stars without altitude measurements
            if altitude is None:
                continue
            
            # Get star coordinates
            ra = star.get('ra')
            dec = star.get('dec')
            
            if ra is None or dec is None:
                continue
            
            try:
                # Create sight
                sight = Sight(
                    ra=ra,
                    dec=dec,
                    altitude=altitude,
                    time=observation_time,
                    observer_height=observer_height,
                    temperature=temperature,
                    pressure=pressure
                )
                sights.append(sight)
                
                result['used_sights'].append({
                    'star': star_name,
                    'ra': ra,
                    'dec': dec,
                    'altitude': altitude
                })
                
            except Exception as e:
                print(f"Warning: Could not create sight for {star_name}: {e}")
                continue
        
        # Step 4: Calculate position if we have enough sights
        if len(sights) < 2:
            result['message'] = f'Not enough sights with altitudes (need 2+, got {len(sights)})'
            return result
        
        try:
            # Create sight collection
            collection = SightCollection(sights)
            
            # Prepare estimated position
            est_pos = None
            if estimated_position:
                est_pos = LatLon(
                    estimated_position.get('lat', 0),
                    estimated_position.get('lon', 0)
                )
            
            # Calculate position
            position_result = collection.calculate_position(
                estimated_position=est_pos
            )
            
            result['calculated_position'] = position_result
            result['success'] = True
            result['message'] = 'Position calculated successfully'
            
        except Exception as e:
            result['message'] = f'Error calculating position: {e}'
            return result
        
        return result
    
    def calculate_position_from_data(self, stars_data: List[Dict]) -> Dict:
        """
        Calculate position from pre-provided star data
        حساب الموقع من بيانات النجوم المقدمة مسبقاً
        
        Args:
            stars_data: List of dictionaries with star observation data
                       Each dict should have: name, ra, dec, altitude, time
                       
        Returns:
            Dictionary with calculated position and metadata
        """
        result = {
            'success': False,
            'message': '',
            'used_sights': [],
            'calculated_position': None
        }
        
        # Validate input
        if not stars_data or len(stars_data) < 2:
            result['message'] = 'Need at least 2 star observations'
            return result
        
        # Create sights
        sights = []
        
        for star_data in stars_data:
            try:
                # Extract data
                name = star_data.get('name', 'Unknown')
                ra = star_data.get('ra')
                dec = star_data.get('dec')
                altitude = star_data.get('altitude')
                time = star_data.get('time')
                observer_height = star_data.get('observer_height', 0.0)
                temperature = star_data.get('temperature', 10.0)
                pressure = star_data.get('pressure', 101.0)
                
                # Validate required fields
                if ra is None or dec is None or altitude is None or time is None:
                    print(f"Warning: Skipping incomplete data for {name}")
                    continue
                
                # Create sight
                sight = Sight(
                    ra=ra,
                    dec=dec,
                    altitude=altitude,
                    time=time,
                    observer_height=observer_height,
                    temperature=temperature,
                    pressure=pressure
                )
                sights.append(sight)
                
                result['used_sights'].append({
                    'star': name,
                    'ra': ra,
                    'dec': dec,
                    'altitude': altitude
                })
                
            except Exception as e:
                print(f"Warning: Error processing star data: {e}")
                continue
        
        # Check if we have enough sights
        if len(sights) < 2:
            result['message'] = f'Not enough valid sights (need 2+, got {len(sights)})'
            return result
        
        # Calculate position
        try:
            collection = SightCollection(sights)
            position_result = collection.calculate_position()
            
            result['calculated_position'] = position_result
            result['success'] = True
            result['message'] = 'Position calculated successfully'
            
        except Exception as e:
            result['message'] = f'Error calculating position: {e}'
            return result
        
        return result
    
    def calculate_position_from_star_names(self,
                                          observations: List[Dict],
                                          observation_time: Optional[str] = None,
                                          estimated_position: Optional[Dict] = None) -> Dict:
        """
        Calculate position using star names (looks up coordinates from database)
        حساب الموقع باستخدام أسماء النجوم
        
        Args:
            observations: List of dicts with 'name' and 'altitude' keys
                         e.g., [{"name": "Sirius", "altitude": 55.5}, ...]
            observation_time: ISO format time (uses now if None)
            estimated_position: Dict with 'lat' and 'lon' keys
            
        Returns:
            Dictionary with calculated position
        """
        result = {
            'success': False,
            'message': '',
            'used_sights': [],
            'calculated_position': None
        }
        
        # Validate input
        if not observations or len(observations) < 2:
            result['message'] = 'Need at least 2 observations'
            return result
        
        # Set observation time
        if observation_time is None:
            observation_time = datetime.now().isoformat()
        
        # Build star data with database lookups
        stars_data = []
        
        for obs in observations:
            name = obs.get('name')
            altitude = obs.get('altitude')
            
            if not name or altitude is None:
                continue
            
            # Look up star coordinates
            coords = get_star_coordinates(name)
            if coords is None:
                print(f"Warning: Star '{name}' not found in database")
                continue
            
            ra, dec = coords
            
            # Build star data
            star_data = {
                'name': name,
                'ra': ra,
                'dec': dec,
                'altitude': altitude,
                'time': observation_time,
                'observer_height': obs.get('observer_height', 0.0),
                'temperature': obs.get('temperature', 10.0),
                'pressure': obs.get('pressure', 101.0)
            }
            stars_data.append(star_data)
        
        # Calculate position using the stars data
        return self.calculate_position_from_data(stars_data)
    
    def get_available_stars(self, min_magnitude: float = 2.0) -> List[Dict]:
        """
        Get list of available navigation stars from database
        الحصول على قائمة النجوم المتاحة من قاعدة البيانات
        
        Args:
            min_magnitude: Maximum magnitude (lower is brighter)
            
        Returns:
            List of star dictionaries
        """
        from stars_database import list_navigation_stars
        return list_navigation_stars(min_magnitude)


# =============================================================================
# Helper Functions for JSON Serialization
# =============================================================================

def result_to_json(result: Dict) -> str:
    """
    Convert result dictionary to JSON string
    تحويل نتيجة القاموس إلى JSON
    
    Args:
        result: Result dictionary from service methods
        
    Returns:
        JSON string
    """
    return json.dumps(result, indent=2, ensure_ascii=False)


def json_to_result(json_str: str) -> Dict:
    """
    Parse JSON string to result dictionary
    تحليل JSON إلى قاموس نتيجة
    
    Args:
        json_str: JSON string
        
    Returns:
        Result dictionary
    """
    return json.loads(json_str)


# =============================================================================
# Usage Example
# =============================================================================

if __name__ == "__main__":
    print("Celestial Navigation Service Example")
    print("مثال على خدمة الملاحة الفلكية")
    print("=" * 70)
    
    # Initialize service
    service = CelestialNavigationService(use_mock_tetra3=True)
    
    # Example 1: Calculate position from star names
    print("\n" + "=" * 70)
    print("Example 1: Position from star names")
    print("مثال 1: الموقع من أسماء النجوم")
    print("=" * 70)
    
    observations = [
        {"name": "Sirius", "altitude": 55.5},
        {"name": "Canopus", "altitude": 40.2}
    ]
    
    estimated_pos = {"lat": 26.0, "lon": 50.0}  # Near Bahrain
    
    result1 = service.calculate_position_from_star_names(
        observations=observations,
        estimated_position=estimated_pos
    )
    
    if result1['success']:
        pos = result1['calculated_position']
        print(f"\n✓ Success!")
        print(f"  Latitude:  {pos['latitude']:.4f}°")
        print(f"  Longitude: {pos['longitude']:.4f}°")
        print(f"  Position:  {pos['position_string']}")
    else:
        print(f"\n✗ Failed: {result1['message']}")
    
    # Example 2: Calculate from pre-provided data
    print("\n" + "=" * 70)
    print("Example 2: Position from detailed data")
    print("مثال 2: الموقع من بيانات مفصلة")
    print("=" * 70)
    
    stars_data = [
        {
            "name": "Vega",
            "ra": 279.2347,
            "dec": 38.7837,
            "altitude": 60.0,
            "time": "2024-08-15T21:00:00",
            "observer_height": 5.0
        },
        {
            "name": "Altair",
            "ra": 297.6958,
            "dec": 8.8683,
            "altitude": 45.0,
            "time": "2024-08-15T21:00:00",
            "observer_height": 5.0
        }
    ]
    
    result2 = service.calculate_position_from_data(stars_data)
    
    if result2['success']:
        pos = result2['calculated_position']
        print(f"\n✓ Success!")
        print(f"  Latitude:  {pos['latitude']:.4f}°")
        print(f"  Longitude: {pos['longitude']:.4f}°")
        print(f"  Position:  {pos['position_string']}")
        print(f"  Stars used: {len(result2['used_sights'])}")
    else:
        print(f"\n✗ Failed: {result2['message']}")
    
    # Example 3: List available stars
    print("\n" + "=" * 70)
    print("Example 3: Available navigation stars")
    print("مثال 3: نجوم الملاحة المتاحة")
    print("=" * 70)
    
    available_stars = service.get_available_stars(min_magnitude=1.5)
    print(f"\nFound {len(available_stars)} bright stars:")
    for i, star in enumerate(available_stars[:5], 1):
        print(f"  {i}. {star['name']} ({star['arabic']}): Mag {star['magnitude']}")
    
    # Example 4: Convert to JSON
    print("\n" + "=" * 70)
    print("Example 4: JSON serialization")
    print("مثال 4: تحويل إلى JSON")
    print("=" * 70)
    
    json_result = result_to_json(result1)
    print("\nJSON output (first 500 chars):")
    print(json_result[:500] + "...")
    
    print("\n" + "=" * 70)
