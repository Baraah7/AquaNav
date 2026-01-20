import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FishClassification{
  final String className;
  final double confidence;
  final DateTime timestamp;
  final double threshold = 0.7;

  FishClassification({
    required this.className, 
    required this.confidence, 
    required this.timestamp
  });

  //check confidence
  bool isConfident(double threshold) {
    return confidence >= threshold;
  }

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

///TensorFlow Lite model service
class FishClassifierService {
  Interpreter? _interpreter; //check what is this
  List<String>? _labels;
  bool _isInitialized = false;

  static const String _modelPath = 'assets/models/fish_classification.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _inputSize = 224; 

  //Initialize the classifier
  Future<void> initialize() async {
    if(_isInitialized) return;

    try{
      //Load model
      _interpreter = await Interpreter.fromAsset(_modelPath);

      //Load labels
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData.split('\n')
                          .where((label) => label.trim().isNotEmpty)
                          .toList();
      _isInitialized = true;
    } catch(e){
      throw Exception('Error initializing FishClassifierService: $e');
    }
  }

  //Check if classifier is initialized
  bool get isInitialized => _isInitialized;

  //Classify image
  Future<FishClassification?> classifyImage(File imageFile) async {
    if(!_isInitialized){
      throw Exception('FishClassifierService is not initialized.');
    }

    try{
      //Read image file
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null){
        throw Exception('Could not decode image.');
      }

      //Preprocess image
      final input = _preprocessImage(image);

      //run inference
      final output = List.filled(_labels!.length, 0.0).reshape([1, _labels!.length]);
      _interpreter!.run(input, output);

      //Get results
      final results = output[0] as List<double>;
      final maxIndex = results.indexOf(results.reduce((a, b) => a > b ? a : b));

      return FishClassification(
        className: _labels![maxIndex],
        confidence: results[maxIndex],
        timestamp: DateTime.now(),
      );
    } catch(e){
      throw Exception('Error classifying image: $e');
    } finally{
      // Delete temporary image file as per policy
      try {
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      } catch (e) {
        print('Warning: Could not delete temporary image: $e');
      }
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

      return FishClassification(
        className: _labels![maxIndex],
        confidence: probabilities[maxIndex],
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('✗ Error during classification: $e');
      throw Exception('Classification failed: $e');
    }
  }

  /// Preprocess image to model input format
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // Resize to 224x224
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.cubic,
    );

    // Convert to normalized float array [1, 224, 224, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0, // Normalize to [0, 1]
              pixel.g / 255.0,
              pixel.b / 255.0,
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
