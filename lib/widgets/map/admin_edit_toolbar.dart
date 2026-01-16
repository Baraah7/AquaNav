import 'package:flutter/material.dart';
import 'package:Bahaar/services/map_layer_manager.dart';
import 'package:Bahaar/services/navigation_mask.dart';

/// Floating toolbar for admin mask editing controls
class AdminEditToolbar extends StatelessWidget {
  final MapLayerManager layerManager;
  final NavigationMask navigationMask;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onClose;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;

  const AdminEditToolbar({
    super.key,
    required this.layerManager,
    required this.navigationMask,
    required this.onSave,
    required this.onReset,
    required this.onClose,
    this.onZoomIn,
    this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(),
          _buildBrushTypeSection(),
          const SizedBox(height: 12),
          _buildBrushSizeSection(),
          if (onZoomIn != null || onZoomOut != null) ...[
            const SizedBox(height: 8),
            _buildZoomControls(),
          ],
          const Divider(),
          _buildUnsavedIndicator(),
          _buildActionButtons(),
          const SizedBox(height: 8),
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.edit, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Admin Edit Mode',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: onClose,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildBrushTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Brush Type:', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _BrushTypeButton(
                label: 'Water',
                icon: Icons.water,
                color: Colors.blue,
                isSelected: layerManager.brushType == AdminBrushType.water,
                onTap: () => layerManager.brushType = AdminBrushType.water,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _BrushTypeButton(
                label: 'Land',
                icon: Icons.terrain,
                color: Colors.brown,
                isSelected: layerManager.brushType == AdminBrushType.land,
                onTap: () => layerManager.brushType = AdminBrushType.land,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _BrushTypeButton(
                label: 'Erase',
                icon: Icons.auto_fix_off,
                color: Colors.grey,
                isSelected: layerManager.brushType == AdminBrushType.eraser,
                onTap: () => layerManager.brushType = AdminBrushType.eraser,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrushSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Brush Size:', style: TextStyle(fontSize: 12)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: layerManager.brushRadius.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '${layerManager.brushRadius}',
                onChanged: (val) => layerManager.brushRadius = val.round(),
              ),
            ),
            Container(
              width: 24,
              alignment: Alignment.center,
              child: Text(
                '${layerManager.brushRadius}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZoomControls() {
    return Row(
      children: [
        const Text('Zoom:', style: TextStyle(fontSize: 12)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove, size: 18),
          onPressed: onZoomOut,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add, size: 18),
          onPressed: onZoomIn,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }

  Widget _buildUnsavedIndicator() {
    if (!navigationMask.hasUnsavedChanges) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning, size: 16, color: Colors.orange),
          SizedBox(width: 4),
          Text(
            'Unsaved changes',
            style: TextStyle(fontSize: 11, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restore, size: 16),
            label: const Text('Reset'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap or drag on map to paint cells',
            style: TextStyle(fontSize: 10, color: Colors.blue),
          ),
          SizedBox(height: 2),
          Text(
            'Blue = Water (navigable)',
            style: TextStyle(fontSize: 9, color: Colors.grey),
          ),
          Text(
            'Brown = Land (blocked)',
            style: TextStyle(fontSize: 9, color: Colors.grey),
          ),
          Text(
            'Grey = Eraser (remove cells)',
            style: TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _BrushTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _BrushTypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
