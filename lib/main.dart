import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:Bahaar/screens/weather.dart';
import 'package:Bahaar/screens/integrated_map.dart';
import 'package:Bahaar/screens/mariner_harvest.dart';
import 'package:Bahaar/screens/settings_screen.dart';
import 'package:Bahaar/widgets/main_page_cards.dart';
import 'package:Bahaar/widgets/language_switcher.dart';
import 'package:Bahaar/screens/fish_recognition_screen.dart';
import 'package:Bahaar/providers/language_provider.dart';
import 'l10n/app_localizations.dart';
import 'app_start.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: "secrets.env");
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);

    return MaterialApp(
      title: 'Bahaar',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const AppStart(),
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          l10n.appName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: const Color.fromARGB(255, 22, 62, 98),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          const LanguageSwitcher(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.welcomeToBahaar,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 52, 59, 138),
              ),
            ),

            const SizedBox(height: 30),

            MainPageCard(
              icon: Icons.map,
              title: l10n.fishingMap,
              subtitle: l10n.fishingMapSubtitle,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IntegratedMap()),
                );
              },
            ),

            const SizedBox(height: 16),

            MainPageCard(
              icon: Icons.cloud,
              title: l10n.weather,
              subtitle: l10n.weatherSubtitle,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Weather()),
                );
              },
            ),

            const SizedBox(height: 16),

            MainPageCard(
              icon: Icons.camera_alt,
              title: l10n.fishRecognition,
              subtitle: l10n.fishRecognitionSubtitle,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FishRecognitionScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            MainPageCard(
              icon: Icons.sailing,
              title: l10n.marinerHarvest,
              subtitle: l10n.marinerHarvestSubtitle,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MarinerHarvestPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}