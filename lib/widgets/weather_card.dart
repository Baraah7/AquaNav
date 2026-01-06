import 'package:flutter/material.dart';

Widget weather_card(String title, String value){
  return Card(
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}