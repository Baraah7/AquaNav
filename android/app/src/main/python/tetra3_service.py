"""
Tetra3 Star Detection Service
خدمة كشف النجوم باستخدام Tetra3

Wrapper around Tetra3 library for detecting stars from camera images.
Tetra3 uses pattern matching to identify stars in night sky photos.

© 2025, MIT License
"""

import os
from typing import List, Dict, Optional, Tuple
from datetime import datetime


class Tetra3Service:
    """
    Service for detecting and identifying stars from images using Tetra3
    خدمة لكشف وتحديد النجوم من الصور باستخدام Tetra3
    """
    
    def __init__(self, database_path: Optional[str] = None):
        """
        Initialize Tetra3 service
        
        Args:
            database_path: Path to Tetra3 database file. If None, uses default.
        """
        self.t3 = None
        self.database_path = database_path
        self.initialized = False
        
        # Try to import and initialize Tetra3
        try:
            import tetra3
            self.tetra3_available = True
            
            # Initialize Tetra3 with database
            if database_path and os.path.exists(database_path):
                self.t3 = tetra3.Tetra3(database_path)
            else:
                # Try to use default database
                self.t3 = tetra3.Tetra3()
            
            self.initialized = True
            print("Tetra3 initialized successfully / تم تهيئة Tetra3 بنجاح")
            
        except ImportError:
            self.tetra3_available = False
            print("WARNING: Tetra3 not installed. Install with: pip install tetra3")
            print("تحذير: Tetra3 غير مثبت. قم بالتثبيت باستخدام: pip install tetra3")
        
        except Exception as e:
            self.tetra3_available = False
            print(f"WARNING: Could not initialize Tetra3: {e}")
            print(f"تحذير: فشل تهيئة Tetra3: {e}")
    
    def is_available(self) -> bool:
        """
        Check if Tetra3 is available and initialized
        التحقق من توفر Tetra3
        
        Returns:
            True if Tetra3 is ready to use
        """
        return self.tetra3_available and self.initialized
    
    def detect_stars_from_file(self, image_path: str, 
                               fov_estimate: Optional[float] = None,
                               return_matches: int = 5) -> Optional[Dict]:
        """
        Detect and identify stars from an image file
        كشف وتحديد النجوم من ملف صورة
        
        Args:
            image_path: Path to image file
            fov_estimate: Estimated field of view in degrees (helps matching)
            return_matches: Number of star matches to return
            
        Returns:
            Dictionary with detection results or None if failed
        """
        if not self.is_available():
            print("ERROR: Tetra3 not available")
            return None
        
        if not os.path.exists(image_path):
            print(f"ERROR: Image file not found: {image_path}")
            return None
        
        try:
            # Load image
            from PIL import Image
            import numpy as np
            
            image = Image.open(image_path)
            image_array = np.array(image)
            
            # If color image, convert to grayscale
            if len(image_array.shape) == 3:
                # Convert to grayscale (simple average method)
                image_array = image_array.mean(axis=2)
            
            # Solve for star field
            result = self.t3.solve_from_image(
                image_array,
                fov_estimate=fov_estimate,
                return_matches=return_matches
            )
            
            return self._process_tetra3_result(result)
            
        except Exception as e:
            print(f"ERROR detecting stars: {e}")
            return None
    
    def detect_stars_from_array(self, image_array, 
                                fov_estimate: Optional[float] = None,
                                return_matches: int = 5) -> Optional[Dict]:
        """
        Detect stars from numpy array
        كشف النجوم من مصفوفة numpy
        
        Args:
            image_array: Numpy array with image data
            fov_estimate: Estimated field of view in degrees
            return_matches: Number of matches to return
            
        Returns:
            Dictionary with detection results
        """
        if not self.is_available():
            print("ERROR: Tetra3 not available")
            return None
        
        try:
            result = self.t3.solve_from_image(
                image_array,
                fov_estimate=fov_estimate,
                return_matches=return_matches
            )
            
            return self._process_tetra3_result(result)
            
        except Exception as e:
            print(f"ERROR detecting stars: {e}")
            return None
    
    def _process_tetra3_result(self, result: Dict) -> Optional[Dict]:
        """
        Process raw Tetra3 result into usable format
        معالجة نتيجة Tetra3 الخام إلى صيغة قابلة للاستخدام
        
        Args:
            result: Raw result from Tetra3
            
        Returns:
            Processed result dictionary
        """
        if result is None or not result.get('matched', False):
            return {
                'success': False,
                'message': 'No star pattern match found',
                'stars': []
            }
        
        processed = {
            'success': True,
            'message': 'Stars detected successfully',
            'stars': [],
            'metadata': {
                'ra_center': result.get('RA', None),
                'dec_center': result.get('Dec', None),
                'roll': result.get('Roll', None),
                'fov': result.get('FOV', None),
                'matched': result.get('matched', False),
                'pattern_confidence': result.get('pattern_confidence', 0.0)
            }
        }
        
        # Extract matched stars
        if 'matched_stars' in result and result['matched_stars'] is not None:
            for star in result['matched_stars']:
                star_info = {
                    'hip_id': star.get('HIP', None),
                    'ra': star.get('RA', None),
                    'dec': star.get('Dec', None),
                    'magnitude': star.get('Vmag', None),
                    'x': star.get('x', None),  # Position in image
                    'y': star.get('y', None),
                    'name': self._get_star_name_from_hip(star.get('HIP', None))
                }
                processed['stars'].append(star_info)
        
        return processed
    
    def _get_star_name_from_hip(self, hip_id: Optional[int]) -> Optional[str]:
        """
        Get common star name from Hipparcos catalog ID
        الحصول على اسم النجم الشائع من معرف كتالوج Hipparcos
        
        Args:
            hip_id: Hipparcos catalog ID
            
        Returns:
            Star name or None
        """
        # Common bright stars with HIP IDs
        hip_to_name = {
            32349: "Sirius",
            30438: "Canopus",
            69673: "Arcturus",
            91262: "Vega",
            24608: "Capella",
            24436: "Rigel",
            37279: "Procyon",
            27989: "Betelgeuse",
            97649: "Altair",
            21421: "Aldebaran",
            80763: "Antares",
            65474: "Spica",
            37826: "Pollux",
            113368: "Fomalhaut",
            102098: "Deneb",
            11767: "Polaris",
            49669: "Regulus"
        }
        
        if hip_id in hip_to_name:
            return hip_to_name[hip_id]
        
        return None
    
    def get_star_coordinates_for_sight(self, detected_stars: List[Dict],
                                      observation_time: str) -> List[Dict]:
        """
        Convert detected stars to format suitable for Sight creation
        تحويل النجوم المكتشفة إلى صيغة مناسبة لإنشاء Sight
        
        Args:
            detected_stars: List of detected star dictionaries
            observation_time: Observation time as ISO string
            
        Returns:
            List of dictionaries ready for Sight initialization
        """
        sight_data = []
        
        for star in detected_stars:
            if star.get('ra') is not None and star.get('dec') is not None:
                sight_info = {
                    'name': star.get('name', f"HIP{star.get('hip_id', 'Unknown')}"),
                    'ra': star['ra'],
                    'dec': star['dec'],
                    'magnitude': star.get('magnitude'),
                    'time': observation_time,
                    'image_position': (star.get('x'), star.get('y'))
                }
                sight_data.append(sight_info)
        
        return sight_data


# =============================================================================
# Mock Service for Testing Without Tetra3
# =============================================================================

class MockTetra3Service:
    """
    Mock service that simulates Tetra3 for testing when library not available
    خدمة وهمية لمحاكاة Tetra3 للاختبار عند عدم توفر المكتبة
    """
    
    def __init__(self):
        self.initialized = True
        print("Mock Tetra3 Service initialized (for testing only)")
        print("خدمة Tetra3 الوهمية تم تهيئتها (للاختبار فقط)")
    
    def is_available(self) -> bool:
        return True
    
    def detect_stars_from_file(self, image_path: str, **kwargs) -> Dict:
        """Return mock star detection result"""
        return {
            'success': True,
            'message': 'Mock detection (testing only)',
            'stars': [
                {
                    'name': 'Sirius',
                    'ra': 101.2875,
                    'dec': -16.7161,
                    'magnitude': -1.46,
                    'x': 512,
                    'y': 384
                },
                {
                    'name': 'Canopus',
                    'ra': 95.9879,
                    'dec': -52.6957,
                    'magnitude': -0.74,
                    'x': 256,
                    'y': 512
                }
            ],
            'metadata': {
                'ra_center': 100.0,
                'dec_center': -30.0,
                'fov': 45.0,
                'matched': True,
                'pattern_confidence': 0.95
            }
        }
    
    def detect_stars_from_array(self, image_array, **kwargs) -> Dict:
        """Return mock star detection result"""
        return self.detect_stars_from_file("mock_image.jpg")
    
    def get_star_coordinates_for_sight(self, detected_stars: List[Dict],
                                      observation_time: str) -> List[Dict]:
        """Convert detected stars for Sight creation"""
        sight_data = []
        
        for star in detected_stars:
            if star.get('ra') is not None and star.get('dec') is not None:
                sight_info = {
                    'name': star.get('name', 'Unknown'),
                    'ra': star['ra'],
                    'dec': star['dec'],
                    'magnitude': star.get('magnitude'),
                    'time': observation_time,
                    'image_position': (star.get('x'), star.get('y'))
                }
                sight_data.append(sight_info)
        
        return sight_data


# =============================================================================
# Factory Function
# =============================================================================

def create_tetra3_service(use_mock: bool = False, 
                         database_path: Optional[str] = None) -> 'Tetra3Service':
    """
    Create Tetra3 service instance (real or mock)
    إنشاء نسخة من خدمة Tetra3
    
    Args:
        use_mock: If True, use mock service for testing
        database_path: Path to Tetra3 database
        
    Returns:
        Tetra3Service or MockTetra3Service
    """
    if use_mock:
        return MockTetra3Service()
    
    service = Tetra3Service(database_path)
    
    # If real service failed to initialize, fall back to mock
    if not service.is_available():
        print("\nFalling back to mock service for testing...")
        print("استخدام الخدمة الوهمية للاختبار...")
        return MockTetra3Service()
    
    return service


# =============================================================================
# Usage Example
# =============================================================================

if __name__ == "__main__":
    print("Tetra3 Service Example / مثال على خدمة Tetra3")
    print("=" * 70)
    
    # Create service (will use mock if Tetra3 not available)
    service = create_tetra3_service()
    
    print(f"\nService available: {service.is_available()}")
    
    # Simulate star detection
    print("\nDetecting stars from image...")
    result = service.detect_stars_from_file("test_image.jpg")
    
    if result and result['success']:
        print(f"\n✓ Detection successful!")
        print(f"  Found {len(result['stars'])} stars")
        print(f"  Pattern confidence: {result['metadata'].get('pattern_confidence', 0):.2f}")
        
        print("\nDetected stars:")
        for i, star in enumerate(result['stars'], 1):
            name = star.get('name', 'Unknown')
            ra = star.get('ra', 0)
            dec = star.get('dec', 0)
            print(f"  {i}. {name}: RA={ra:.2f}°, Dec={dec:.2f}°")
        
        # Convert to sight format
        print("\n" + "=" * 70)
        print("Converting to Sight format:")
        observation_time = datetime.now().isoformat()
        sight_data = service.get_star_coordinates_for_sight(
            result['stars'], 
            observation_time
        )
        
        for sight in sight_data:
            print(f"  {sight['name']}: RA={sight['ra']:.2f}°, Dec={sight['dec']:.2f}°")
    
    print("\n" + "=" * 70)
