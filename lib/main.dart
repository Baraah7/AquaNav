import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Bahaar/screens/weather.dart';
import 'package:Bahaar/screens/integrated_map.dart';
import 'package:Bahaar/screens/mariner_harvest.dart';
import 'package:Bahaar/widgets/main_page_cards.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "secrets.env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bahaar',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Bahaar Home Page'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Bahaar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: const Color.fromARGB(255, 22, 62, 98),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Bahaar',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 52, 59, 138),
              ),
            ),
            const SizedBox(height: 30),

            MainPageCard(
              icon: Icons.map,
              title: 'Fishing Map',
              subtitle: 'Interactive map with depth colors',
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
              title: 'Weather',
              subtitle: 'Check marine weather',
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
              title: 'Fish Recognition',
              subtitle: 'Identify fish species',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fish Recognition - Coming Soon')),
                );
              },
            ),

            const SizedBox(height: 16),

            MainPageCard(
              icon: Icons.sailing,
              title: 'Mariner Harvest',
              subtitle: 'Buy & sell fresh fish',
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