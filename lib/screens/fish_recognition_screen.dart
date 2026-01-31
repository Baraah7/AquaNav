import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/fish_classification_provider.dart';
import '../l10n/app_localizations.dart';

class FishRecognitionScreen extends ConsumerStatefulWidget {
  const FishRecognitionScreen({super.key});

  @override
  ConsumerState<FishRecognitionScreen> createState() =>
      _FishRecognitionScreenState();
}

class _FishRecognitionScreenState extends ConsumerState<FishRecognitionScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    // Initialize classifier on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fishClassificationProvider.notifier).initialize();
    });
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
        await _classifyImage(File(photo.path));
      }
    } catch (e) {
      _showError('Failed to open camera: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _classifyImage(File(image.path));
      }
    } catch (e) {
      _showError('Failed to select image: $e');
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    ref.read(fishClassificationProvider.notifier).classifyImage(imageFile);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetClassification() {
    setState(() {
      _selectedImage = null;
    });
    ref.read(fishClassificationProvider.notifier).clearResult();
  }

  @override
  Widget build(BuildContext context) {
    final classificationState = ref.watch(fishClassificationProvider);
    final isInitialized = classificationState.isInitialized;
    final hasError = classificationState.error != null && !isInitialized;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fishRecognition),
        centerTitle: true,
        backgroundColor: const Color(0xFF0077BE),
        foregroundColor: Colors.white,
      ),
      body: hasError
          ? _buildErrorView(context, classificationState.error!)
          : !isInitialized
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(l10n.loadingRecognitionModel),
                    ],
                  ),
                )
              : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Instructions card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.takePhotoOfFish,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.systemWillIdentify,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Camera and gallery buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: classificationState.isLoading
                                ? null
                                : _pickImageFromCamera,
                            icon: const Icon(Icons.camera_alt, size: 28),
                            label: Text(
                              l10n.camera,
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0077BE),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: classificationState.isLoading
                                ? null
                                : _pickImageFromGallery,
                            icon: const Icon(Icons.photo_library, size: 28),
                            label: Text(
                              l10n.gallery,
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Image preview
                    if (_selectedImage != null)
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Image.file(
                              _selectedImage!,
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            if (classificationState.isLoading)
                              Container(
                                height: 300,
                                color: Colors.black54,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        l10n.analyzing,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Results
                    if (classificationState.result != null)
                      _buildResultCard(context, classificationState.result!),

                    // Error message
                    if (classificationState.error != null)
                      Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  classificationState.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Reset button
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: OutlinedButton.icon(
                          onPressed: _resetClassification,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.newImage),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF0077BE)),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Supported species info
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.supportedSpecies,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildSpeciesItem('Gilt-Head Bream'),
                            _buildSpeciesItem('Horse Mackerel'),
                            _buildSpeciesItem('Sea Bass'),
                            _buildSpeciesItem('Shrimp'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildResultCard(BuildContext context, result) {
    final isConfident = result.isConfident;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      color: isConfident ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              isConfident ? Icons.check_circle : Icons.warning,
              size: 56,
              color: isConfident ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              result.className,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${l10n.confidence}: ',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${(result.confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isConfident ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            if (!isConfident) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.tryTakingClearerPhoto,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesItem(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadModel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(fishClassificationProvider.notifier).initialize();
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077BE),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}