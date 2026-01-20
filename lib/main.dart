import 'package:flutter/material.dart';
import '../screens/weather.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../screens/map.dart';
import '../screens/integrated_map.dart';
import 'widgets/map/geojson_overlay_test_page.dart';
import '../screens/fish_recognition_screen.dart';

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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //button to go to weather screen
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 18, color: Color.fromARGB(255, 10, 97, 43)),
              backgroundColor: const Color.fromARGB(255, 204, 231, 205),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Weather()),
              );
            },
            child: const Text('Go to Weather Screen'),
          ),
          const SizedBox(height: 20),
          //button to go to weather screen
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 18, color: Color.fromARGB(255, 10, 97, 43)),
              backgroundColor: const Color.fromARGB(255, 204, 231, 205),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Map()),
              );
            },
            child: const Text('Go to Map Screen'),
            
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 18),
              backgroundColor: const Color.fromARGB(255, 173, 216, 230),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IntegratedMap()),
              );
            },
            child: const Text('Integrated Map (All Layers)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 14),
              backgroundColor: const Color.fromARGB(255, 230, 230, 230),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GeoJsonOverlayTestPage(),
                ),
              );
            },
            child: const Text('GeoJSON Test (Dev)'),
          )
        ],
      ),
    );
  }

}








