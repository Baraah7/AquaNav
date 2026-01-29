import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fish_classifier_service.dart';

// State class for fish classification
class FishClassificationState {
  final FishClassification? result;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const FishClassificationState({
    this.result,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  FishClassificationState copyWith({
    FishClassification? result,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    bool clearError = false,
  }) {
    return FishClassificationState(
      result: result ?? this.result,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: clearError ? null : (error ?? this.error),
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

  Future<void> initialize() async {
    if (state.isInitialized) return;

    try {
      await _classifierService.initialize();
      state = state.copyWith(isInitialized: true, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isInitialized: false,
        error: 'فشل تحميل النموذج: $e',
      );
    }
  }

  Future<void> classifyImage(File imageFile) async {
    if (!state.isInitialized) {
      state = state.copyWith(error: 'النموذج غير جاهز');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _classifierService.classifyImage(imageFile);
      state = state.copyWith(
        result: result,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل التصنيف: $e',
      );
    }
  }

  void clearResult() {
    state = FishClassificationState(isInitialized: state.isInitialized);
  }

  void dispose() {
    _classifierService.dispose();
  }
}

// Provider for fish classification
final fishClassificationProvider =
    NotifierProvider<FishClassificationNotifier, FishClassificationState>(
  FishClassificationNotifier.new,
);
