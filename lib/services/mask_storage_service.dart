import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Data class for user mask with metadata
class UserMaskData {
  final Uint8List maskData;
  final int width;
  final int height;
  final double minLon;
  final double maxLon;
  final double minLat;
  final double maxLat;
  final double resolution;

  UserMaskData({
    required this.maskData,
    required this.width,
    required this.height,
    required this.minLon,
    required this.maxLon,
    required this.minLat,
    required this.maxLat,
    required this.resolution,
  });
}

/// Service for persisting user modifications to the navigation mask
class MaskStorageService {
  static const String _maskFileName = 'user_navigation_mask.bin';
  static const String _metadataFileName = 'user_navigation_mask_metadata.json';
  static const String _backupFileName = 'user_navigation_mask_backup.bin';

  /// Get the path to the user's modified mask file
  Future<String> _getMaskFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_maskFileName';
  }

  /// Get the path to the metadata file
  Future<String> _getMetadataFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_metadataFileName';
  }

  /// Get the path to the backup file
  Future<String> _getBackupFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_backupFileName';
  }

  /// Check if a user-modified mask exists
  Future<bool> hasUserMask() async {
    try {
      final maskPath = await _getMaskFilePath();
      final metadataPath = await _getMetadataFilePath();
      return await File(maskPath).exists() && await File(metadataPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Load the user's modified mask with metadata, or null if none exists
  Future<UserMaskData?> loadUserMask() async {
    try {
      final maskPath = await _getMaskFilePath();
      final metadataPath = await _getMetadataFilePath();

      final maskFile = File(maskPath);
      final metadataFile = File(metadataPath);

      if (await maskFile.exists() && await metadataFile.exists()) {
        final maskData = await maskFile.readAsBytes();
        final metadataJson = await metadataFile.readAsString();
        final metadata = json.decode(metadataJson);

        return UserMaskData(
          maskData: maskData,
          width: metadata['width'],
          height: metadata['height'],
          minLon: metadata['minLon'].toDouble(),
          maxLon: metadata['maxLon'].toDouble(),
          minLat: metadata['minLat'].toDouble(),
          maxLat: metadata['maxLat'].toDouble(),
          resolution: metadata['resolution'].toDouble(),
        );
      }
    } catch (e) {
      // Fall back to asset mask
    }
    return null;
  }

  /// Save the modified mask with metadata to local storage
  Future<bool> saveUserMask(
    Uint8List maskData, {
    required int width,
    required int height,
    required double minLon,
    required double maxLon,
    required double minLat,
    required double maxLat,
    required double resolution,
  }) async {
    try {
      final maskPath = await _getMaskFilePath();
      final metadataPath = await _getMetadataFilePath();
      final maskFile = File(maskPath);

      // Create backup of existing file
      if (await maskFile.exists()) {
        final backupPath = await _getBackupFilePath();
        await maskFile.copy(backupPath);
      }

      // Save mask data
      await maskFile.writeAsBytes(maskData);

      // Save metadata
      final metadata = {
        'width': width,
        'height': height,
        'minLon': minLon,
        'maxLon': maxLon,
        'minLat': minLat,
        'maxLat': maxLat,
        'resolution': resolution,
      };
      await File(metadataPath).writeAsString(json.encode(metadata));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reset to original asset mask by deleting user modifications
  Future<bool> resetToAssetMask() async {
    try {
      final maskPath = await _getMaskFilePath();
      final metadataPath = await _getMetadataFilePath();

      final maskFile = File(maskPath);
      if (await maskFile.exists()) {
        await maskFile.delete();
      }

      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
