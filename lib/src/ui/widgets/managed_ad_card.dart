import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_iraq/src/models/managed_ad_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ManagedAdCard extends StatelessWidget {
  final ManagedAd ad;
  const ManagedAdCard({super.key, required this.ad});

  Future<void> _launchUrl() async {
    final uri = Uri.parse(ad.targetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch ${ad.targetUrl}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launchUrl,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: GridTile(
            footer: GridTileBar(
              backgroundColor: Colors.black45,
              title: Text(ad.title, textAlign: TextAlign.center),
              subtitle: const Text('إعلان ممول', textAlign: TextAlign.center),
            ),
            child: Image.network(
              ad.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.campaign, color: Colors.white, size: 50)),
            ),
          ),
        ),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .scale(
      begin: const Offset(1, 1),
      end: const Offset(1.02, 1.02),
      duration: 2000.ms,
      curve: Curves.easeInOut
    )
    .then()
    .shimmer(
      delay: 500.ms,
      duration: 1500.ms,
      blendMode: BlendMode.srcATop,
      color: Colors.white.withOpacity(0.2)
    );
  }
}
