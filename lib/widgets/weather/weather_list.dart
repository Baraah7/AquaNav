import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/weather/weather_response_model.dart';
import '../../models/weather/hour_model.dart';
import '../../models/weather/forecast_day_model.dart';

// Reusable styles and colors
class _WeatherStyles {
  static const Color accent = Color(0xFF4FC3F7);
  static const Color orange = Color(0xFFFFB74D);
  static const Color coral = Color(0xFFFF8A65);

  static Color white(double alpha) => Colors.white.withValues(alpha: alpha);

  static BoxDecoration cardDecoration({double radius = 24}) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [white(0.15), white(0.05)],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: white(0.2)),
  );

  static TextStyle labelStyle = TextStyle(color: white(0.7), fontSize: 13, fontWeight: FontWeight.w500);
  static const TextStyle valueStyle = TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w400);
}

class WeatherList extends StatelessWidget {
  final weather_response_model weatherData;

  const WeatherList({super.key, required this.weatherData});

  // Reusable weather icon widget
  Widget _weatherIcon(String iconUrl, {double size = 32}) {
    return Image.network(
      'https:$iconUrl',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Icon(
        Icons.cloud,
        color: _WeatherStyles.white(0.7),
        size: size,
      ),
    );
  }

  // Reusable section header with accent bar
  Widget _sectionHeader(String title, Color accentColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Reusable gradient divider
  Widget _gradientDivider({bool vertical = false}) {
    return Container(
      width: vertical ? 1 : null,
      height: vertical ? 50 : 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _WeatherStyles.white(0.2),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildUniqueHeader(),
          _buildHourlyForecast(),
          const SizedBox(height: 20),
          _buildDailyForecast(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildWindDetailCard(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildCompactCard(
                      icon: Icons.wb_sunny_outlined,
                      title: 'UV Index',
                      value: '${weatherData.currentWeather.uv.round()}',
                      subtitle: _getUVLevel(weatherData.currentWeather.uv),
                      accentColor: _getUVColor(weatherData.currentWeather.uv),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCompactCard(
                      icon: Icons.thermostat_outlined,
                      title: 'Feels Like',
                      value: '${weatherData.currentWeather.feelslike_c.round()}°',
                      subtitle: _getFeelsLikeDescription(),
                      accentColor: const Color(0xFF64B5F6),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCompactCard(
                      icon: Icons.water_drop,
                      title: 'Humidity',
                      value: '${weatherData.currentWeather.humidity}%',
                      subtitle: 'Dew ${weatherData.currentWeather.dewpoint_c.round()}°',
                      accentColor: _WeatherStyles.accent,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCompactCard(
                      icon: Icons.visibility_outlined,
                      title: 'Visibility',
                      value: '${weatherData.currentWeather.vis_km.round()} km',
                      subtitle: _getVisibilityDescription(),
                      accentColor: const Color(0xFF81C784),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSunMoonCard(),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUniqueHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        children: [
          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _WeatherStyles.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _WeatherStyles.accent.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                weatherData.location.name.toUpperCase(),
                style: TextStyle(
                  color: _WeatherStyles.white(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Temperature circle
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _WeatherStyles.white(0.1), width: 2),
                ),
              ),
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_WeatherStyles.white(0.1), Colors.transparent],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weatherData.currentWeather.temp_c.round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '°C',
                      style: TextStyle(
                        color: _WeatherStyles.white(0.7),
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Condition pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _WeatherStyles.white(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _WeatherStyles.white(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _weatherIcon(weatherData.currentWeather.condition.icon, size: 28),
                const SizedBox(width: 8),
                Text(
                  weatherData.currentWeather.condition.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // High/Low
          if (weatherData.forecast != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tempIndicator(weatherData.forecast!.forecastDay.day.maxtemp_c.round(), Icons.arrow_upward, _WeatherStyles.orange),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(width: 40, height: 2, child: _gradientDivider()),
                ),
                _tempIndicator(weatherData.forecast!.forecastDay.day.mintemp_c.round(), Icons.arrow_downward, const Color(0xFF64B5F6)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tempIndicator(int temp, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text('$temp°', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    if (weatherData.forecast == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final hours = weatherData.forecast!.forecastday
        .expand((day) => day.hour)
        .where((h) => DateTime.parse(h.time).isAfter(now.subtract(const Duration(hours: 1))))
        .take(24)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _WeatherStyles.cardDecoration(),
      child: Column(
        children: [
          _sectionHeader('Next 24 Hours', _WeatherStyles.accent),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: hours.length,
              itemBuilder: (context, index) => _hourItem(hours[index], index == 0),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _hourItem(hour_model hour, bool isNow) {
    final hourTime = DateTime.parse(hour.time);
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isNow ? BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_WeatherStyles.accent.withValues(alpha: 0.3), _WeatherStyles.accent.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _WeatherStyles.accent.withValues(alpha: 0.5)),
      ) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isNow ? 'Now' : '${hourTime.hour}:00',
            style: TextStyle(
              color: isNow ? _WeatherStyles.accent : _WeatherStyles.white(0.8),
              fontSize: 14,
              fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          _weatherIcon(hour.condition_icon, size: 36),
          Text(
            '${hour.temp_c.round()}°',
            style: TextStyle(
              color: isNow ? Colors.white : _WeatherStyles.white(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecast() {
    if (weatherData.forecast == null) return const SizedBox.shrink();

    final days = weatherData.forecast!.forecastday;
    final weekMin = days.map((d) => d.day.mintemp_c).reduce(math.min);
    final weekMax = days.map((d) => d.day.maxtemp_c).reduce(math.max);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _WeatherStyles.cardDecoration(),
      child: Column(
        children: [
          _sectionHeader('${days.length}-Day Forecast', _WeatherStyles.orange),
          ...days.asMap().entries.map((e) => _dayRow(e.value, e.key == 0, weekMin, weekMax)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _dayRow(forecast_day day, bool isToday, double weekMin, double weekMax) {
    final date = DateTime.parse(day.date);
    final dayName = isToday ? 'Today' : _getDayName(date.weekday);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: isToday ? BoxDecoration(color: _WeatherStyles.white(0.08)) : null,
      child: Row(
        children: [
          SizedBox(
            width: 55,
            child: Text(
              dayName,
              style: TextStyle(
                color: isToday ? Colors.white : _WeatherStyles.white(0.8),
                fontSize: 15,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          _weatherIcon(day.day.condition_icon),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            child: day.day.daily_chance_of_rain > 0
                ? Row(
                    children: [
                      const Icon(Icons.water_drop, color: _WeatherStyles.accent, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${day.day.daily_chance_of_rain}%',
                        style: const TextStyle(color: _WeatherStyles.accent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : null,
          ),
          const Spacer(),
          Text('${day.day.mintemp_c.round()}°', style: TextStyle(color: _WeatherStyles.white(0.5), fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: _temperatureBar(day.day.mintemp_c, day.day.maxtemp_c, weekMin, weekMax, isToday)),
          const SizedBox(width: 8),
          Text('${day.day.maxtemp_c.round()}°', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _temperatureBar(double min, double max, double weekMin, double weekMax, bool isToday) {
    final range = weekMax - weekMin;
    final startPercent = (min - weekMin) / range;
    final endPercent = (max - weekMin) / range;
    final currentPercent = isToday ? (weatherData.currentWeather.temp_c - weekMin) / range : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: _WeatherStyles.white(0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              Positioned(
                left: constraints.maxWidth * startPercent,
                right: constraints.maxWidth * (1 - endPercent),
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF64B5F6), _WeatherStyles.orange, _WeatherStyles.coral]),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (currentPercent != null)
                Positioned(
                  left: (constraints.maxWidth * currentPercent - 5).clamp(0, constraints.maxWidth - 10),
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWindDetailCard() {
    final wind = weatherData.currentWeather;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _WeatherStyles.cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(painter: _ModernCompassPainter(wind.wind_degree.toDouble())),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.air, color: _WeatherStyles.white(0.7), size: 20),
                    const SizedBox(width: 8),
                    const Text('Wind', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${wind.wind_kph.round()}', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w300, height: 1)),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('km/h', style: TextStyle(color: _WeatherStyles.white(0.7), fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _WeatherStyles.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(wind.wind_dir, style: const TextStyle(color: _WeatherStyles.accent, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.waves, color: _WeatherStyles.white(0.5), size: 14),
                    const SizedBox(width: 6),
                    Text('Gusts up to ${wind.gust_kph.round()} km/h', style: TextStyle(color: _WeatherStyles.white(0.6), fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 130,
      decoration: _WeatherStyles.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 6),
              Text(title, style: _WeatherStyles.labelStyle),
            ],
          ),
          const Spacer(),
          Text(value, style: _WeatherStyles.valueStyle),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: _WeatherStyles.white(0.6), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSunMoonCard() {
    if (weatherData.forecast == null) return const SizedBox.shrink();

    final astro = weatherData.forecast!.forecastDay.astro;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _WeatherStyles.cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _celestialInfo(Icons.wb_sunny, _WeatherStyles.orange, 'Sunrise', astro.sunrise)),
              _gradientDivider(vertical: true),
              Expanded(child: _celestialInfo(Icons.wb_twilight, _WeatherStyles.coral, 'Sunset', astro.sunset)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _gradientDivider(),
          ),
          Row(
            children: [
              Icon(_getMoonIcon(astro.moon_phase), color: _WeatherStyles.white(0.9), size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(astro.moon_phase, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                    Text('${astro.moon_illumination}% illuminated', style: TextStyle(color: _WeatherStyles.white(0.6), fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _moonTime(Icons.arrow_upward, astro.moonrise),
                  const SizedBox(height: 4),
                  _moonTime(Icons.arrow_downward, astro.moonset),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _celestialInfo(IconData icon, Color color, String title, String time) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: _WeatherStyles.white(0.6), fontSize: 13)),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _moonTime(IconData icon, String time) {
    return Row(
      children: [
        Icon(icon, color: _WeatherStyles.white(0.5), size: 12),
        const SizedBox(width: 4),
        Text(time, style: TextStyle(color: _WeatherStyles.white(0.7), fontSize: 13)),
      ],
    );
  }

  IconData _getMoonIcon(String phase) {
    return switch (phase.toLowerCase()) {
      'new moon' => Icons.brightness_1_outlined,
      'full moon' => Icons.brightness_1,
      'first quarter' => Icons.brightness_2,
      'last quarter' => Icons.brightness_3,
      _ => Icons.nightlight_round,
    };
  }

  String _getDayName(int weekday) {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday];
  }

  String _getUVLevel(double uv) {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  }

  Color _getUVColor(double uv) {
    if (uv <= 2) return const Color(0xFF81C784);
    if (uv <= 5) return _WeatherStyles.orange;
    if (uv <= 7) return _WeatherStyles.coral;
    if (uv <= 10) return const Color(0xFFE57373);
    return const Color(0xFFBA68C8);
  }

  String _getFeelsLikeDescription() {
    final diff = weatherData.currentWeather.feelslike_c - weatherData.currentWeather.temp_c;
    if (diff.abs() < 2) return 'Similar to actual';
    return diff > 0 ? 'Feels warmer' : 'Feels cooler';
  }

  String _getVisibilityDescription() {
    final vis = weatherData.currentWeather.vis_km;
    if (vis >= 10) return 'Clear';
    if (vis >= 5) return 'Good';
    if (vis >= 2) return 'Moderate';
    return 'Low';
  }
}

class _ModernCompassPainter extends CustomPainter {
  final double windDegree;
  _ModernCompassPainter(this.windDegree);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _WeatherStyles.white(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Decorative dots
    final dotPaint = Paint()..color = _WeatherStyles.white(0.4)..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45 - 90) * math.pi / 180;
      canvas.drawCircle(
        Offset(center.dx + (radius - 8) * math.cos(angle), center.dy + (radius - 8) * math.sin(angle)),
        i % 2 == 0 ? 3.0 : 2.0,
        dotPaint,
      );
    }

    // Direction arrow
    final angle = (windDegree - 90) * math.pi / 180;
    final arrowLength = radius - 16;
    final path = Path()
      ..moveTo(center.dx + arrowLength * math.cos(angle), center.dy + arrowLength * math.sin(angle))
      ..lineTo(center.dx + 10 * math.cos(angle + math.pi - 0.5), center.dy + 10 * math.sin(angle + math.pi - 0.5))
      ..lineTo(center.dx + 10 * math.cos(angle + math.pi + 0.5), center.dy + 10 * math.sin(angle + math.pi + 0.5))
      ..close();
    canvas.drawPath(path, Paint()..color = _WeatherStyles.accent);

    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);

    // N indicator
    final textPainter = TextPainter(
      text: const TextSpan(text: 'N', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, 6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
