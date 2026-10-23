import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../l10n/strings.dart';
import '../data/cloud_sync.dart';

class OwnerAds extends ConsumerWidget {
  const OwnerAds({
    super.key,
    required this.parentConsent,
    required this.onVideo,
  });
  final bool parentConsent;
  final ValueChanged<String> onVideo;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context), config = ref.watch(cloudProvider).ads;
    if (!parentConsent || config['enabled'] != true) {
      return const SizedBox.shrink();
    }
    final provider = config['provider'];
    final url = Uri.tryParse(config['url'] as String? ?? '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            s['advertisement'],
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 16),
          if (provider == 'image' && url?.scheme == 'https')
            Image.network(
              url.toString(),
              height: 160,
              fit: BoxFit.contain,
              semanticLabel: config['title'] as String? ?? s['advertisement'],
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            )
          else if (provider == 'video' && url?.scheme == 'https')
            OutlinedButton.icon(
              onPressed: () => onVideo(url.toString()),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(config['title'] as String? ?? s['advertisement']),
            )
          else if (provider == 'admob' &&
              const String.fromEnvironment('ADMOB_APP_ID').isNotEmpty)
            AdMobBanner(
              key: ValueKey(config['bannerId']),
              unit: config['bannerId'] as String? ?? '',
            ),
        ],
      ),
    );
  }
}

class AdMobBanner extends StatefulWidget {
  const AdMobBanner({super.key, required this.unit});
  final String unit;
  @override
  State<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<AdMobBanner> {
  BannerAd? _ad;
  bool _loaded = false, _started = false;
  Future<void> _load(int width) async {
    if (_started ||
        width < 320 ||
        !RegExp(r'^ca-app-pub-\d+/\d+$').hasMatch(widget.unit)) {
      return;
    }
    _started = true;
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );
      await MobileAds.instance.initialize();
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (!mounted || size == null) return;
      _ad = BannerAd(
        adUnitId: widget.unit,
        size: size,
        request: const AdRequest(nonPersonalizedAds: true),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, _) {
            ad.dispose();
          },
        ),
      );
      await _ad!.load();
    } catch (_) {
      _ad?.dispose();
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (!_started) Future.microtask(() => _load(box.maxWidth.floor()));
      return _loaded && _ad != null
          ? SizedBox(
              width: _ad!.size.width.toDouble(),
              height: _ad!.size.height.toDouble(),
              child: AdWidget(ad: _ad!),
            )
          : const SizedBox.shrink();
    },
  );
}
