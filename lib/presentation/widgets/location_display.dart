import 'package:flutter/material.dart';
import '../../../domain/entities/location.dart';

class LocationDisplay extends StatelessWidget {
  final Location location;

  const LocationDisplay({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.location_on, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Latitud: ${location.latitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Longitud: ${location.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 16),
            ),
            if (location.timestamp != null) ...[
              const SizedBox(height: 8),
              Text(
                'Hora: ${_formatDateTime(location.timestamp!)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}:${dateTime.second}';
  }
}