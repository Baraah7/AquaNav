"""
Android/Flutter Integration Service
خدمة التكامل مع Android/Flutter

Bridge service for integrating with Flutter via MethodChannel.
Handles communication between Flutter app and Python celestial navigation.

© 2025, MIT License
"""

import json
import traceback
from typing import Dict, Any

from celestial_service import CelestialNavigationService


class AndroidBridgeService:
    """
    Service that handles Flutter MethodChannel requests
    خدمة معالجة طلبات Flutter MethodChannel
    """
    
    def __init__(self):
        """Initialize the Android bridge service"""
        self.celestial_service = CelestialNavigationService(use_mock_tetra3=False)
        print("Android Bridge Service initialized")
        print("تم تهيئة خدمة جسر Android")
    
    def handle_request(self, method: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Main request handler for Flutter MethodChannel
        معالج الطلبات الرئيسي لـ Flutter MethodChannel
        
        Args:
            method: Method name from Flutter
            data: Request data as dictionary
            
        Returns:
            Response dictionary
        """
        try:
            if method == "detect_stars":
                return self._handle_detect_stars(data)
            
            elif method == "calculate_position":
                return self._handle_calculate_position(data)
            
            elif method == "calculate_from_names":
                return self._handle_calculate_from_names(data)
            
            elif method == "get_star_info":
                return self._handle_get_star_info(data)
            
            elif method == "list_stars":
                return self._handle_list_stars(data)
            
            elif method == "process_image":
                return self._handle_process_image(data)
            
            else:
                return {
                    'success': False,
                    'error': f'Unknown method: {method}'
                }
        
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'traceback': traceback.format_exc()
            }
    
    def _handle_detect_stars(self, data: Dict) -> Dict:
        """
        Handle star detection from image
        معالجة كشف النجوم من الصورة
        """
        image_path = data.get('image_path')
        
        if not image_path:
            return {'success': False, 'error': 'image_path required'}
        
        fov_estimate = data.get('fov_estimate')
        
        detection = self.celestial_service.tetra3_service.detect_stars_from_file(
            image_path,
            fov_estimate=fov_estimate
        )
        
        return detection or {'success': False, 'error': 'Detection failed'}
    
    def _handle_calculate_position(self, data: Dict) -> Dict:
        """
        Handle position calculation from star data
        معالجة حساب الموقع من بيانات النجوم
        """
        stars_data = data.get('stars')
        
        if not stars_data:
            return {'success': False, 'error': 'stars data required'}
        
        return self.celestial_service.calculate_position_from_data(stars_data)
    
    def _handle_calculate_from_names(self, data: Dict) -> Dict:
        """
        Handle position calculation from star names
        معالجة حساب الموقع من أسماء النجوم
        """
        observations = data.get('observations')
        
        if not observations:
            return {'success': False, 'error': 'observations required'}
        
        observation_time = data.get('time')
        estimated_position = data.get('estimated_position')
        
        return self.celestial_service.calculate_position_from_star_names(
            observations=observations,
            observation_time=observation_time,
            estimated_position=estimated_position
        )
    
    def _handle_get_star_info(self, data: Dict) -> Dict:
        """
        Handle star information lookup
        معالجة البحث عن معلومات النجم
        """
        from stars_database import get_star_by_name, get_star_by_arabic_name
        
        name = data.get('name')
        arabic_name = data.get('arabic_name')
        
        if name:
            star = get_star_by_name(name)
        elif arabic_name:
            star = get_star_by_arabic_name(arabic_name)
        else:
            return {'success': False, 'error': 'name or arabic_name required'}
        
        if star:
            return {'success': True, 'star': star}
        else:
            return {'success': False, 'error': 'Star not found'}
    
    def _handle_list_stars(self, data: Dict) -> Dict:
        """
        Handle listing available stars
        معالجة عرض قائمة النجوم المتاحة
        """
        min_magnitude = data.get('min_magnitude', 2.0)
        
        stars = self.celestial_service.get_available_stars(min_magnitude)
        
        return {
            'success': True,
            'stars': stars,
            'count': len(stars)
        }
    
    def _handle_process_image(self, data: Dict) -> Dict:
        """
        Handle complete image processing workflow
        معالجة سير عمل معالجة الصورة الكامل
        """
        image_path = data.get('image_path')
        
        if not image_path:
            return {'success': False, 'error': 'image_path required'}
        
        user_altitudes = data.get('altitudes')
        observation_time = data.get('time')
        estimated_position = data.get('estimated_position')
        observer_height = data.get('observer_height', 0.0)
        temperature = data.get('temperature', 10.0)
        pressure = data.get('pressure', 101.0)
        
        return self.celestial_service.process_image(
            image_path=image_path,
            user_altitudes=user_altitudes,
            observation_time=observation_time,
            estimated_position=estimated_position,
            observer_height=observer_height,
            temperature=temperature,
            pressure=pressure
        )


# =============================================================================
# JSON-RPC Style Interface (Alternative to MethodChannel)
# =============================================================================

class JSONRPCService:
    """
    JSON-RPC style interface for web/REST API integration
    واجهة JSON-RPC للتكامل مع Web/REST API
    """
    
    def __init__(self):
        self.bridge = AndroidBridgeService()
    
    def handle_json_request(self, json_str: str) -> str:
        """
        Handle JSON-RPC style request
        
        Args:
            json_str: JSON string with 'method' and 'params' keys
            
        Returns:
            JSON response string
        """
        try:
            request = json.loads(json_str)
            method = request.get('method')
            params = request.get('params', {})
            
            result = self.bridge.handle_request(method, params)
            
            response = {
                'jsonrpc': '2.0',
                'result': result,
                'id': request.get('id', None)
            }
            
        except Exception as e:
            response = {
                'jsonrpc': '2.0',
                'error': {
                    'code': -32603,
                    'message': str(e)
                },
                'id': None
            }
        
        return json.dumps(response, ensure_ascii=False, indent=2)


# =============================================================================
# Global Service Instance
# =============================================================================

# Create singleton instance for easy access
_service_instance = None


def get_service_instance() -> AndroidBridgeService:
    """
    Get or create global service instance
    الحصول على أو إنشاء نسخة الخدمة العامة
    """
    global _service_instance
    if _service_instance is None:
        _service_instance = AndroidBridgeService()
    return _service_instance


# =============================================================================
# Simple Function Interface for Flutter
# =============================================================================

def process_star_image(image_path: str, altitudes_json: str, 
                      time: str = None, estimated_lat: float = None, 
                      estimated_lon: float = None) -> str:
    """
    Simplified interface for Flutter integration
    واجهة مبسطة للتكامل مع Flutter
    
    Args:
        image_path: Path to star field image
        altitudes_json: JSON string mapping star names to altitudes
        time: ISO format observation time
        estimated_lat: Estimated latitude
        estimated_lon: Estimated longitude
        
    Returns:
        JSON string with results
    """
    service = get_service_instance()
    
    altitudes = json.loads(altitudes_json) if altitudes_json else None
    
    estimated_position = None
    if estimated_lat is not None and estimated_lon is not None:
        estimated_position = {'lat': estimated_lat, 'lon': estimated_lon}
    
    data = {
        'image_path': image_path,
        'altitudes': altitudes,
        'time': time,
        'estimated_position': estimated_position
    }
    
    result = service.handle_request('process_image', data)
    return json.dumps(result, ensure_ascii=False)


def calculate_position_simple(observations_json: str, 
                              time: str = None,
                              estimated_lat: float = None,
                              estimated_lon: float = None) -> str:
    """
    Calculate position from star observations (simplified)
    حساب الموقع من أرصاد النجوم (مبسط)
    
    Args:
        observations_json: JSON array of observations with name and altitude
        time: ISO format observation time
        estimated_lat: Estimated latitude
        estimated_lon: Estimated longitude
        
    Returns:
        JSON string with calculated position
    """
    service = get_service_instance()
    
    observations = json.loads(observations_json)
    
    estimated_position = None
    if estimated_lat is not None and estimated_lon is not None:
        estimated_position = {'lat': estimated_lat, 'lon': estimated_lon}
    
    data = {
        'observations': observations,
        'time': time,
        'estimated_position': estimated_position
    }
    
    result = service.handle_request('calculate_from_names', data)
    return json.dumps(result, ensure_ascii=False)


# =============================================================================
# Usage Example
# =============================================================================

if __name__ == "__main__":
    print("Android Bridge Service Example")
    print("مثال على خدمة جسر Android")
    print("=" * 70)
    
    # Initialize service
    service = get_service_instance()
    
    # Example 1: Calculate position from star names
    print("\nExample 1: Calculate position via bridge")
    print("مثال 1: حساب الموقع عبر الجسر")
    print("=" * 70)
    
    request_data = {
        'observations': [
            {'name': 'Sirius', 'altitude': 55.5},
            {'name': 'Canopus', 'altitude': 40.2}
        ],
        'estimated_position': {'lat': 26.0, 'lon': 50.0}
    }
    
    result = service.handle_request('calculate_from_names', request_data)
    
    if result['success']:
        pos = result['calculated_position']
        print(f"\n✓ Position calculated:")
        print(f"  Latitude:  {pos['latitude']:.4f}°")
        print(f"  Longitude: {pos['longitude']:.4f}°")
    else:
        print(f"\n✗ Failed: {result.get('error')}")
    
    # Example 2: List available stars
    print("\n" + "=" * 70)
    print("Example 2: List stars via bridge")
    print("مثال 2: عرض قائمة النجوم عبر الجسر")
    print("=" * 70)
    
    result = service.handle_request('list_stars', {'min_magnitude': 1.5})
    
    if result['success']:
        print(f"\n✓ Found {result['count']} stars")
        for star in result['stars'][:3]:
            print(f"  - {star['name']} ({star['arabic']})")
    
    # Example 3: Simplified function interface
    print("\n" + "=" * 70)
    print("Example 3: Simplified function interface")
    print("مثال 3: واجهة وظيفية مبسطة")
    print("=" * 70)
    
    observations_json = json.dumps([
        {'name': 'Vega', 'altitude': 60.0},
        {'name': 'Altair', 'altitude': 45.0}
    ])
    
    result_json = calculate_position_simple(
        observations_json,
        estimated_lat=26.0,
        estimated_lon=50.0
    )
    
    result = json.loads(result_json)
    if result['success']:
        pos = result['calculated_position']
        print(f"\n✓ Position: {pos['position_string']}")
    
    # Example 4: JSON-RPC interface
    print("\n" + "=" * 70)
    print("Example 4: JSON-RPC interface")
    print("مثال 4: واجهة JSON-RPC")
    print("=" * 70)
    
    rpc_service = JSONRPCService()
    
    rpc_request = json.dumps({
        'jsonrpc': '2.0',
        'method': 'list_stars',
        'params': {'min_magnitude': 1.0},
        'id': 1
    })
    
    rpc_response = rpc_service.handle_json_request(rpc_request)
    print("\nJSON-RPC Response (first 400 chars):")
    print(rpc_response[:400] + "...")
    
    print("\n" + "=" * 70)
