import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:Bahaar/models/navigation/marina_model.dart';

/// Widget for displaying marina markers on the map
class MarinaMarkerLayer extends StatelessWidget {
  final List<Marina> marinas;
  final Function(Marina)? onMarinaTapped;
  final String? highlightedMarinaId;
  final bool showLabels;

  const MarinaMarkerLayer({
    super.key,
    required this.marinas,
    this.onMarinaTapped,
    this.highlightedMarinaId,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: marinas.map((marina) {
        final isHighlighted = marina.id == highlightedMarinaId;

        return Marker(
          point: marina.location,
          width: isHighlighted ? 60 : 40,
          height: isHighlighted ? 60 : 40,
          child: GestureDetector(
            onTap: () => onMarinaTapped?.call(marina),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Marina icon
                Container(
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? Colors.orange.withValues(alpha: 0.9)
                        : Colors.blue.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: isHighlighted ? 6 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getMarinaIcon(marina.type),
                    color: Colors.white,
                    size: isHighlighted ? 32 : 24,
                  ),
                ),

                // Label (if enabled)
                if (showLabels || isHighlighted)
                  Positioned(
                    bottom: -24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Text(
                        marina.name,
                        style: TextStyle(
                          fontSize: isHighlighted ? 11 : 9,
                          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                // Access type badge
                if (marina.accessType != MarinaAccessType.public)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getAccessColor(marina.accessType),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Icon(
                        _getAccessIcon(marina.accessType),
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Get icon for marina type
  IconData _getMarinaIcon(MarinaType type) {
    switch (type) {
      case MarinaType.marina:
        return Icons.anchor;
      case MarinaType.harbor:
        return Icons.sailing;
      case MarinaType.slipway:
        return Icons.kayaking;
      case MarinaType.boatRamp:
        return Icons.directions_boat;
      case MarinaType.port:
        return Icons.local_shipping;
    }
  }

  /// Get icon for access type
  IconData _getAccessIcon(MarinaAccessType type) {
    switch (type) {
      case MarinaAccessType.private:
        return Icons.lock;
      case MarinaAccessType.customers:
        return Icons.badge;
      case MarinaAccessType.permissive:
        return Icons.verified_user;
      default:
        return Icons.public;
    }
  }

  /// Get color for access type badge
  Color _getAccessColor(MarinaAccessType type) {
    switch (type) {
      case MarinaAccessType.private:
        return Colors.red;
      case MarinaAccessType.customers:
        return Colors.orange;
      case MarinaAccessType.permissive:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}

/// Info card widget for displaying marina details
class MarinaInfoCard extends StatelessWidget {
  final Marina marina;
  final VoidCallback? onClose;
  final VoidCallback? onNavigate;

  const MarinaInfoCard({
    super.key,
    required this.marina,
    this.onClose,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and close button
          Row(
            children: [
              Icon(
                _getMarinaIcon(marina.type),
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  marina.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Type and access info
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(marina.type.displayName),
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                labelStyle: const TextStyle(fontSize: 11),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text(marina.accessType.displayName),
                backgroundColor: _getAccessColor(marina.accessType).withValues(alpha: 0.1),
                avatar: Icon(
                  _getAccessIcon(marina.accessType),
                  size: 14,
                  color: _getAccessColor(marina.accessType),
                ),
                labelStyle: const TextStyle(fontSize: 11),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          // Depth info
          if (marina.depth != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.water, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Depth: ${marina.depth}m',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],

          // Facilities
          if (marina.facilities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: marina.facilities.map((facility) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getFacilityIcon(facility),
                        size: 12,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        facility,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // Navigate button
          if (onNavigate != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('Navigate Here'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],

          // Coordinates (small text)
          const SizedBox(height: 8),
          Text(
            '${marina.location.latitude.toStringAsFixed(4)}, ${marina.location.longitude.toStringAsFixed(4)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMarinaIcon(MarinaType type) {
    switch (type) {
      case MarinaType.marina:
        return Icons.anchor;
      case MarinaType.harbor:
        return Icons.sailing;
      case MarinaType.slipway:
        return Icons.kayaking;
      case MarinaType.boatRamp:
        return Icons.directions_boat;
      case MarinaType.port:
        return Icons.local_shipping;
    }
  }

  IconData _getAccessIcon(MarinaAccessType type) {
    switch (type) {
      case MarinaAccessType.private:
        return Icons.lock;
      case MarinaAccessType.customers:
        return Icons.badge;
      case MarinaAccessType.permissive:
        return Icons.verified_user;
      default:
        return Icons.public;
    }
  }

  Color _getAccessColor(MarinaAccessType type) {
    switch (type) {
      case MarinaAccessType.private:
        return Colors.red;
      case MarinaAccessType.customers:
        return Colors.orange;
      case MarinaAccessType.permissive:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getFacilityIcon(String facility) {
    switch (facility.toLowerCase()) {
      case 'parking':
        return Icons.local_parking;
      case 'fuel':
        return Icons.local_gas_station;
      case 'restroom':
        return Icons.wc;
      case 'restaurant':
        return Icons.restaurant;
      case 'shower':
        return Icons.shower;
      default:
        return Icons.check_circle;
    }
  }
}
