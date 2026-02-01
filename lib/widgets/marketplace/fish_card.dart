import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/marketplace/fish_listing_model.dart';

Widget buildFishCard({
  required FishListing listing,
  required VoidCallback onTap,
  required IconData Function(FishType) getFishIcon,
}) {
  return GestureDetector(
    onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: listing.primaryImageUrl != null
                    ? null
                    : LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 22, 62, 98),
                          const Color.fromARGB(255, 44, 100, 150),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: listing.primaryImageUrl != null
                    ? DecorationImage(
                        image: FileImage(File(listing.primaryImageUrl!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: listing.primaryImageUrl == null
                  ? Center(
                      child: Icon(
                        getFishIcon(listing.fishType),
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      listing.fishType.arabicName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        buildInfoBadge(
                          '${listing.weight.toStringAsFixed(1)} kg',
                          Icons.scale,
                        ),
                        const SizedBox(width: 4),
                        buildInfoBadge(
                          listing.condition.displayName,
                          Icons.check_circle_outline,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${listing.pricePerKg.toStringAsFixed(1)} BD/kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color.fromARGB(255, 22, 62, 98),
                          ),
                        ),
                        Text(
                          '${listing.totalPrice.toStringAsFixed(2)} BD',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

Widget buildInfoBadge(String text, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.grey.shade600),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
        ),
      ],
    ),
  );
}