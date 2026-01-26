import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FishClassification {
  final String className;
  final double confidence;
  final DateTime timestamp;
  final double threshold = 0.7;

  // Mapping of English class names to Arabic names
  static const Map<String, String> _arabicNames = {
    'Gilt-Head Bream': 'دنيس',
    'Hourse Mackerel': 'سكمبري',
    'Sea Bass': 'قاروص',
    'Shrimp': 'روبيان',
  };

  FishClassification({
    required this.className,
    required this.confidence,
    required this.timestamp,
  });

  // Get Arabic name for the fish class
  String get arabicName => _arabicNames[className] ?? className;

  // Check if classification is confident (using default threshold)
  bool get isConfident => confidence >= threshold;

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// TensorFlow Lite model service for fish classification
class FishClassifierService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isInitialized = false;

  static const String _modelPath = 'assets/models/fish_classifier.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _inputSize = 224;

  /// Initialize the classifier
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load model
      _interpreter = await Interpreter.fromAsset(_modelPath);

      // Verify input tensor shape and type (debug mode only)
      if (kDebugMode) {
        final inputTensor = _interpreter!.getInputTensor(0);
        final outputTensor = _interpreter!.getOutputTensor(0);

        debugPrint('Fish Classifier Model Info:');
        debugPrint('  Input shape: ${inputTensor.shape}');  // Expected: [1, 224, 224, 3]
        debugPrint('  Input type: ${inputTensor.type}');    // Expected: float32
        debugPrint('  Output shape: ${outputTensor.shape}'); // Expected: [1, 4]
        debugPrint('  Output type: ${outputTensor.type}');
      }

      // Load labels
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .toList();

      if (kDebugMode) {
        debugPrint('  Labels loaded: ${_labels!.length}'); // Expected: 4
        debugPrint('  Label names: $_labels');
      }

      _isInitialized = true;
    } catch (e) {
      throw Exception('Error initializing FishClassifierService: $e');
    }
  }

  /// Check if classifier is initialized
  bool get isInitialized => _isInitialized;

  /// Classify image from file
  Future<FishClassification?> classifyImage(File imageFile) async {
    if (!_isInitialized) {
      throw Exception('FishClassifierService is not initialized.');
    }

    try {
      // Read image file
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Could not decode image.');
      }

      // Preprocess image
      final input = _preprocessImage(image);

      // Run inference
      final output = List.filled(_labels!.length, 0.0).reshape([1, _labels!.length]);
      _interpreter!.run(input, output);

      // Get results
      final results = output[0] as List<double>;
      final maxIndex = results.indexOf(results.reduce((a, b) => a > b ? a : b));

      // Debug: Log all predictions (debug mode only)
      if (kDebugMode) {
        debugPrint('Classification results (raw): $results');
        debugPrint('Classifications:');
        for (int i = 0; i < _labels!.length; i++) {
          debugPrint('  [$i] ${_labels![i]}: ${(results[i] * 100).toStringAsFixed(2)}%');
        }
        debugPrint('SELECTED: ${_labels![maxIndex]} at index $maxIndex with ${(results[maxIndex] * 100).toStringAsFixed(1)}% confidence');
      }

      return FishClassification(
        className: _labels![maxIndex],
        confidence: results[maxIndex],
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error classifying image: $e');
    }
  }

  /// Classify from image bytes (e.g., from camera)
  Future<FishClassification> classifyImageBytes(Uint8List imageBytes) async {
    if (!_isInitialized) {
      throw Exception('Classifier not initialized. Call initialize() first.');
    }

    try {
      // Decode image
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Preprocess image
      final input = _preprocessImage(image);

      // Run inference
      final output = List.filled(_labels!.length, 0.0).reshape([1, _labels!.length]);
      _interpreter!.run(input, output);

      // Get results
      final probabilities = output[0] as List<double>;
      final maxIndex = probabilities.indexOf(
        probabilities.reduce((a, b) => a > b ? a : b),
      );

      // Debug: Log all predictions (debug mode only)
      if (kDebugMode) {
        debugPrint('Classification results (raw): $probabilities');
        debugPrint('Classifications:');
        for (int i = 0; i < _labels!.length; i++) {
          debugPrint('  [$i] ${_labels![i]}: ${(probabilities[i] * 100).toStringAsFixed(2)}%');
        }
        debugPrint('SELECTED: ${_labels![maxIndex]} at index $maxIndex with ${(probabilities[maxIndex] * 100).toStringAsFixed(1)}% confidence');
      }

      return FishClassification(
        className: _labels![maxIndex],
        confidence: probabilities[maxIndex],
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Classification failed: $e');
    }
  }

  /// Center crop image to square (critical for camera images)
  /// This ensures the fish fills the frame similar to training data
  img.Image _centerCrop(img.Image image) {
    final size = image.width < image.height ? image.width : image.height;
    final x = (image.width - size) ~/ 2;
    final y = (image.height - size) ~/ 2;
    return img.copyCrop(image, x: x, y: y, width: size, height: size);
  }

  /// Preprocess image to model input format
  /// Pipeline: center crop → resize → normalize
  /// Uses MobileNet/EfficientNet preprocessing: (pixel / 127.5) - 1.0
  /// This matches the preprocess_input function used during training
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // Step 1: Center crop to square (critical for camera images)
    final cropped = _centerCrop(image);

    // Step 2: Resize to 224x224
    final resized = img.copyResize(
      cropped,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Step 3: Convert to normalized float array [1, 224, 224, 3]
    // Shape: [1, 224, 224, 3] (NHWC format)
    // Type: float32
    // Color: RGB
    // Range: [-1.0, 1.0] using (pixel / 127.5) - 1.0
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              (pixel.r / 127.5) - 1.0, // MobileNet/EfficientNet normalization
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  /// Get all class labels
  List<String> get labels => List.unmodifiable(_labels ?? []);

  /// Get model input size
  int get inputSize => _inputSize;

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
