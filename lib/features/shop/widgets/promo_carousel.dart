import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  int _currentIndex = 0;
  late final PageController _pageController;
  Timer? _timer;

  // Mêmes slides promotionnels que le frontend React (promo-carousel.tsx)
  static const _promos = [
    _PromoItem(
      title: 'Nouvelle Collection Mode',
      subtitle: 'Jusqu\'à -40% sur toute la collection automne-hiver',
      image: 'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=1200&h=400&fit=crop',
    ),
    _PromoItem(
      title: 'High-Tech en Promo',
      subtitle: 'Les meilleurs smartphones et laptops aux meilleurs prix',
      image: 'https://images.unsplash.com/photo-1607082349566-187342175e2f?w=1200&h=400&fit=crop',
    ),
    _PromoItem(
      title: 'Mode Africaine Authentique',
      subtitle: 'Découvrez nos créations en wax et bazin',
      image: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200&h=400&fit=crop',
    ),
    _PromoItem(
      title: 'Audio Premium',
      subtitle: 'Casques et écouteurs des plus grandes marques',
      image: 'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=1200&h=400&fit=crop',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextIndex = (_currentIndex + 1) % _promos.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _promos.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (ctx, i) => _PromoCard(
                key: ValueKey('promo_$i'),
                promo: _promos[i],
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSmoothIndicator(
            activeIndex: _currentIndex,
            count: _promos.length,
            effect: const ExpandingDotsEffect(
              dotHeight: 6,
              dotWidth: 6,
              activeDotColor: AppColors.primary,
              dotColor: AppColors.divider,
              expansionFactor: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoItem {
  final String title;
  final String subtitle;
  final String image;

  const _PromoItem({
    required this.title,
    required this.subtitle,
    required this.image,
  });
}

class _PromoCard extends StatelessWidget {
  final _PromoItem promo;

  const _PromoCard({super.key, required this.promo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond Unsplash
          CachedNetworkImage(
            imageUrl: promo.image,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.surfaceVariant,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.primary,
            ),
          ),

          // Dégradé sombre identique au site web pour la lisibilité
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black87,
                  Colors.black54,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Contenu du slide
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  promo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 240,
                  child: Text(
                    promo.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
