import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fish_classifier_service.dart';

// State class for fish classification
class FishClassificationState {
  final FishClassification? result;
  final bool isLoading;
  final String? error;

  const FishClassificationState({
    this.result,
    this.isLoading = false,
    this.error,
  });

  FishClassificationState copyWith({
    FishClassification? result,
    bool? isLoading,
    String? error,
  }) {
    return FishClassificationState(
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier class for managing fish classification state
class FishClassificationNotifier extends Notifier<FishClassificationState> {
  final FishClassifierService _classifierService = FishClassifierService();

  @override
  FishClassificationState build() {
    return const FishClassificationState();
  }

  bool get isInitialized => _classifierService.isInitialized;

  Future<void> initialize() async {
    try {
      await _classifierService.initialize();
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize classifier: $e');
    }
  }

  Future<void> classifyImage(File imageFile) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _classifierService.classifyImage(imageFile);
      state = state.copyWith(
        result: result,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Classification failed: $e',
      );
    }
  }

  void clearResult() {
    state = const FishClassificationState();
  }

  void dispose() {
    _classifierService.dispose();
  }
}

// Provider for fish classification
final fishClassificationProvider = NotifierProvider<FishClassificationNotifier, FishClassificationState>(
  FishClassificationNotifier.new,
);