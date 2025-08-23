import 'package:flutter/material.dart';
import 'package:smart_iraq/src/models/managed_ad_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ManagedAdCard extends StatefulWidget {
  final ManagedAd ad;
  const ManagedAdCard({super.key, required this.ad});

  @override
  State<ManagedAdCard> createState() => _ManagedAdCardState();
}

class _ManagedAdCardState extends State<ManagedAdCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchUrl() async {
    final uri = Uri.parse(widget.ad.targetUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Could show a snackbar here
      debugPrint('Could not launch ${widget.ad.targetUrl}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
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
                title: Text(widget.ad.title, textAlign: TextAlign.center),
                subtitle: const Text('إعلان ممول', textAlign: TextAlign.center),
              ),
              child: Image.network(
                widget.ad.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.campaign, color: Colors.white, size: 50)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
