import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmRouteResult {
  final List<LatLng> points;
  final int durationSeconds; // ETA
  final double distanceMeters;

  OsrmRouteResult({
    required this.points,
    required this.durationSeconds,
    required this.distanceMeters,
  });
}

class OsrmService {
  static Future<OsrmRouteResult> fetchRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';

    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch route');
    }

    final data = json.decode(res.body);

    final route = data['routes'][0];

    final coords =
        route['geometry']['coordinates'] as List;

    final duration =
        (route['duration'] as num).round(); // seconds

    final distance =
        (route['distance'] as num).toDouble(); // meters

    return OsrmRouteResult(
      points: coords
          .map(
            (c) => LatLng(c[1], c[0]), // lat, lng
          )
          .toList(),
      durationSeconds: duration,
      distanceMeters: distance,
    );
  }
}
