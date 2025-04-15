import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.location,
    this.longitude,
    this.latitude,
  });

  Future<bool> send() {
    Uri url = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/search/',
      queryParameters: {'api': "1", "query": "$latitude,$longitude"},
    );
    return launchUrl(url);
  }

  final String location;
  final String? longitude;
  final String? latitude;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        margin: const EdgeInsets.all(7),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Flex(
            direction: Axis.horizontal,
            children: [
              Text(location),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (longitude != null && latitude != null) {
                    send();
                  }
                },
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.location_on_outlined, size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
