import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/fish_classification_provider.dart';

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
      _showError('فشل فتح الكاميرا: $e');
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
      _showError('فشل اختيار الصورة: $e');
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
    final isInitialized =
        ref.read(fishClassificationProvider.notifier).isInitialized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعرف على الأسماك'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0077BE),
      ),
      body: !isInitialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل نموذج التعرف...'),
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
                            const Text(
                              'التقط صورة للسمكة أو الروبيان',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'سيتعرف النظام على النوع تلقائياً',
                              style: TextStyle(
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
                            label: const Text(
                              'كاميرا',
                              style: TextStyle(fontSize: 16),
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
                            label: const Text(
                              'معرض',
                              style: TextStyle(fontSize: 16),
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
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'جاري التحليل...',
                                        style: TextStyle(
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
                      _buildResultCard(classificationState.result!),

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
                          label: const Text('صورة جديدة'),
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
                                const Text(
                                  'الأنواع المدعومة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildSpeciesItem('دنيس (Gilt-Head Bream)'),
                            _buildSpeciesItem('سكمبري (Hourse Mackerel)'),
                            _buildSpeciesItem('قاروص (Sea Bass)'),
                            _buildSpeciesItem('روبيان (Shrimp)'),
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

  Widget _buildResultCard(result) {
    final isConfident = result.isConfident;

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
              result.arabicName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              result.className,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'دقة التعرف: ',
                  style: TextStyle(fontSize: 16),
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
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'جرب التقاط صورة أوضح للحصول على نتيجة أدق',
                        style: TextStyle(fontSize: 13),
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
}