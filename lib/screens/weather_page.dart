import 'package:flutter/cupertino.dart';
import 'dart:convert'; //for decoding and encoding JSON 
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
//Load configuration at runtime from a .env file which can be
// used throughout the application.


class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}