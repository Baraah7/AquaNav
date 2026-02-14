import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Bahaar/widgets/navigation/weather_alert_overlay.dart';
import 'package:Bahaar/models/weather/marine_weather_model.dart';

/// Helper to create a WeatherSafetyAssessment for testing
WeatherSafetyAssessment makeAssessment({
  SafetyLevel level = SafetyLevel.caution,
  List<String> warnings = const ['Test warning'],
  double costMultiplier = 2.0,
}) {
  return WeatherSafetyAssessment(
    level: level,
    costMultiplier: costMultiplier,
    warnings: warnings,
    data: MarineWeatherData(
      latitude: 26.1,
      longitude: 50.5,
      timestamp: DateTime.now(),
      waveHeight: 1.5,
      wavePeriod: 5.0,
      windWaveHeight: 0.0,
      swellWaveHeight: 0.0,
      windSpeed: 35.0,
      windGusts: 45.0,
      visibility: 8000.0,
    ),
  );
}

void main() {
  group('WeatherAlertOverlay', () {
    testWidgets('renders nothing when warnings list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              WeatherAlertOverlay(warnings: const []),
            ],
          ),
        ),
      );

      // Should render a SizedBox.shrink (essentially nothing visible)
      expect(find.byType(WeatherAlertOverlay), findsOneWidget);
      expect(find.byType(Material).hitTestable(), findsNothing);
    });

    testWidgets('displays warning text for caution level', (tester) async {
      final warnings = [
        makeAssessment(
          level: SafetyLevel.caution,
          warnings: ['Moderate waves: 1.5m'],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              WeatherAlertOverlay(warnings: warnings),
            ],
          ),
        ),
      );

      expect(find.text('Weather Caution'), findsOneWidget);
      expect(find.text('Moderate waves: 1.5m'), findsOneWidget);
    });

    testWidgets('displays dangerous conditions title', (tester) async {
      final warnings = [
        makeAssessment(
          level: SafetyLevel.dangerous,
          warnings: ['High waves: 2.5m'],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              WeatherAlertOverlay(warnings: warnings),
            ],
          ),
        ),
      );

      expect(find.text('Dangerous Conditions'), findsOneWidget);
    });

    testWidgets('displays blocked navigation title', (tester) async {
      final warnings = [
        makeAssessment(
          level: SafetyLevel.blocked,
          warnings: ['Wave height 3.5m exceeds safe limit'],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              WeatherAlertOverlay(warnings: warnings),
            ],
          ),
        ),
      );

      expect(find.text('Navigation Blocked'), findsOneWidget);
    });

    testWidgets('shows worst level when multiple warnings exist', (tester) async {
      final warnings = [
        makeAssessment(level: SafetyLevel.caution, warnings: ['Moderate waves']),
        makeAssessment(level: SafetyLevel.dangerous, warnings: ['Strong wind']),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              WeatherAlertOverlay(warnings: warnings),
            ],
          ),
        ),
      );

      // Should show "Dangerous Conditions" as worst level
      expect(find.text('Dangerous Conditions'), findsOneWidget);
    });

    testWidgets('combines unique warnings from all assessments', (tester) async {
      final warnings = [
        makeAssessment(level: SafetyLevel.caution, warnings: ['Moderate waves: 1.5m']),
        makeAssessment(level: SafetyLevel.caution, warnings: ['Moderate wind: 35 km/h']),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              WeatherAlertOverlay(warnings: warnings),
            ],
          ),
        ),
      );

      // Both warnings should appear joined with ' | '
      expect(find.textContaining('Moderate waves'), findsOneWidget);
      expect(find.textContaining('Moderate wind'), findsOneWidget);
    });

    testWidgets('shows dismiss button when onDismiss is provided', (tester) async {
      bool dismissed = false;
      final warnings = [
        makeAssessment(level: SafetyLevel.caution, warnings: ['Test']),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              WeatherAlertOverlay(
                warnings: warnings,
                onDismiss: () => dismissed = true,
              ),
            ],
          ),
        ),
      );

      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      expect(dismissed, isTrue);
    });

    testWidgets('hides dismiss button when onDismiss is null', (tester) async {
      final warnings = [
        makeAssessment(level: SafetyLevel.caution, warnings: ['Test']),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              WeatherAlertOverlay(warnings: warnings),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('displays correct icon for each safety level', (tester) async {
      // Test caution icon
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              WeatherAlertOverlay(warnings: [
                makeAssessment(level: SafetyLevel.caution, warnings: ['Test']),
              ]),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Test dangerous icon
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              WeatherAlertOverlay(warnings: [
                makeAssessment(level: SafetyLevel.dangerous, warnings: ['Test']),
              ]),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.dangerous), findsOneWidget);

      // Test blocked icon
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              WeatherAlertOverlay(warnings: [
                makeAssessment(level: SafetyLevel.blocked, warnings: ['Test']),
              ]),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.block), findsOneWidget);
    });
  });
}
