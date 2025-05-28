import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.title,
    this.longitude,
    this.latitude,
    this.onTap,
    this.actions,
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

  final GestureTapCallback? onTap;
  final String title;
  final String? longitude;
  final String? latitude;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: InkWell(
        onTap: onTap,
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
                Text(title),
                const Spacer(),
                if (actions == null || (latitude != null && longitude != null))
                  IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      send();
                    },
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.location_on_outlined, size: 30),
                  )
                else if (actions != null)
                  ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
