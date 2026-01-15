import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Bottom sheet panel for selecting land-to-sea navigation
///
/// Enforces strict routing pattern:
/// 1. Origin: Land point (GPS or map tap)
/// 2. Destination: Sea point (within navigation mask)
/// 3. Shore point auto-selected by system
///
/// Features:
/// - Two-stage selection (land origin → sea destination)
/// - Automatic shore/port selection
/// - Display selected points with coordinates
/// - Calculate route button
/// - Use current location as origin option
class DestinationPickerPanel extends StatefulWidget {
  final LatLng? currentLocation;
  final LatLng? selectedOrigin;        // Land only
  final LatLng? selectedDestination;   // Water only
  final Function(LatLng)? onOriginSelected;
  final Function(LatLng)? onDestinationSelected;
  final VoidCallback? onCalculateRoute;
  final VoidCallback? onCancel;
  final VoidCallback? onUseCurrentLocation;
  final bool isCalculating;

  const DestinationPickerPanel({
    super.key,
    this.currentLocation,
    this.selectedOrigin,
    this.selectedDestination,
    this.onOriginSelected,
    this.onDestinationSelected,
    this.onCalculateRoute,
    this.onCancel,
    this.onUseCurrentLocation,
    this.isCalculating = false,
  });

  @override
  State<DestinationPickerPanel> createState() => _DestinationPickerPanelState();
}

class _DestinationPickerPanelState extends State<DestinationPickerPanel> {
  bool _selectingOrigin = true;

  @override
  Widget build(BuildContext context) {
    final canCalculate = widget.selectedOrigin != null && widget.selectedDestination != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.navigation, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Plan Your Route',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.onCancel != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Selection mode toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildModeButton(
                    label: 'Select Origin',
                    icon: Icons.radio_button_checked,
                    isSelected: _selectingOrigin,
                    onTap: () => setState(() => _selectingOrigin = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeButton(
                    label: 'Select Destination',
                    icon: Icons.place,
                    isSelected: !_selectingOrigin,
                    onTap: () => setState(() => _selectingOrigin = false),
                  ),
                ),
              ],
            ),
          ),

          // Instruction text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectingOrigin
                          ? 'Tap on the map to set starting point (land only)'
                          : 'Tap on the map to set sea destination (water only)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Origin selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLocationCard(
              label: 'Starting Point',
              icon: Icons.radio_button_checked,
              color: Colors.green,
              location: widget.selectedOrigin,
              onClear: () => widget.onOriginSelected?.call(widget.currentLocation!),
              showUseCurrentButton: widget.currentLocation != null,
              onUseCurrentLocation: widget.onUseCurrentLocation,
            ),
          ),

          const SizedBox(height: 12),

          // Sea destination selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLocationCard(
              label: 'Sea Destination',
              icon: Icons.waves,
              color: Colors.cyan,
              location: widget.selectedDestination,
              onClear: widget.selectedDestination != null
                  ? () => widget.onDestinationSelected?.call(widget.selectedDestination!)
                  : null,
            ),
          ),

          const SizedBox(height: 20),

          // Calculate route button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: canCalculate && !widget.isCalculating
                    ? widget.onCalculateRoute
                    : null,
                icon: widget.isCalculating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.directions),
                label: Text(
                  widget.isCalculating ? 'Calculating...' : 'Calculate Route',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard({
    required String label,
    required IconData icon,
    required Color color,
    required LatLng? location,
    VoidCallback? onClear,
    bool showUseCurrentButton = false,
    VoidCallback? onUseCurrentLocation,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: location != null ? color.withValues(alpha: 0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: location != null ? color.withValues(alpha: 0.3) : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (location != null && onClear != null)
                IconButton(
                  icon: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (location != null) ...[
            const SizedBox(height: 4),
            Text(
              '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
                fontFamily: 'monospace',
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'Not set',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
            if (showUseCurrentButton && onUseCurrentLocation != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onUseCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text(
                    'Use Current Location',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
