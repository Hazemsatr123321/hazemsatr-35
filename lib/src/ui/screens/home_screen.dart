import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/models/managed_ad_model.dart';
import 'package:smart_iraq/src/models/charity_campaign_model.dart';
import 'package:smart_iraq/src/repositories/product_repository.dart';
import 'package:smart_iraq/src/ui/widgets/product_card.dart';
import 'package:smart_iraq/src/ui/widgets/managed_ad_card.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';

class HomeFeed {
  final List<Product> featuredProducts;
  final List<ManagedAd> managedAds;
  final List<Product> charityProducts;
  final List<CharityCampaign> humanitarianCampaigns;

  HomeFeed({
    required this.featuredProducts,
    required this.managedAds,
    required this.charityProducts,
    required this.humanitarianCampaigns,
  });
}

class HomeScreen extends StatefulWidget {
  final ProductRepository productRepository;
  final bool isGuest;

  const HomeScreen({
    super.key,
    required this.productRepository,
    this.isGuest = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeFeed> _feedFuture;
  late SupabaseClient _supabase;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supabase = Provider.of<SupabaseClient>(context, listen: false);
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _feedFuture = _getCombinedFeed();
    });
  }

  Future<HomeFeed> _getCombinedFeed() async {
    final productsFuture = widget.productRepository.getProducts();
    final managedAdsFuture = _supabase.from('managed_ads').select().eq('is_active', true);
    final campaignsFuture = _supabase.from('charity_campaigns').select().eq('is_active', true);

    final results = await Future.wait([productsFuture, managedAdsFuture, campaignsFuture]);

    final allProducts = results[0] as List<Product>;
    final managedAdsData = results[1] as List;
    final campaignsData = results[2] as List;

    final managedAds = managedAdsData.map((ad) => ManagedAd.fromJson(ad)).toList();
    final campaigns = campaignsData.map((c) => CharityCampaign.fromJson(c)).toList();

    final featuredProducts = allProducts.where((p) => p.is_featured).toList();
    final charityProducts = allProducts.where((p) => p.is_available_for_donation).toList();

    return HomeFeed(
      featuredProducts: featuredProducts,
      managedAds: managedAds,
      charityProducts: charityProducts,
      humanitarianCampaigns: campaigns,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: RefreshIndicator.adaptive(
        onRefresh: () async => _fetchData(),
        child: FutureBuilder<HomeFeed>(
          future: _feedFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CustomLoadingIndicator();
            }
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ في تحميل البيانات: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('لا توجد بيانات لعرضها.'));
            }

            final feed = snapshot.data!;
            return CustomScrollView(
              slivers: [
                const CupertinoSliverNavigationBar(
                  largeTitle: Text('سوق العراق الذكي'),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    if (feed.managedAds.isNotEmpty)
                      _buildSection(context, 'إعلانات خارجية', feed.managedAds, (ad) => ManagedAdCard(ad: ad)),
                    if (feed.featuredProducts.isNotEmpty)
                      _buildSection(context, 'الإعلانات المميزة', feed.featuredProducts, (p) => ProductCard(product: p)),
                    if (feed.charityProducts.isNotEmpty)
                      _buildSection(context, 'دعم الفقراء (تبرعات عينية)', feed.charityProducts, (p) => ProductCard(product: p)),
                    if (feed.humanitarianCampaigns.isNotEmpty)
                       _buildSection(context, 'حملات إنسانية', feed.humanitarianCampaigns, (c) => Text("Campaign Card")), // Placeholder
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection<T>(BuildContext context, String title, List<T> items, Widget Function(T item) cardBuilder) {
    final theme = CupertinoTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(title, style: theme.textTheme.navTitleTextStyle.copyWith(color: AppTheme.goldAccent)),
        ),
        SizedBox(
          height: 250, // Standard height for horizontal lists
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: SizedBox(
                  width: 180, // Standard width for cards
                  child: cardBuilder(items[index]),
                ),
              ).animate().fadeIn(delay: (100 * index).ms);
            },
          ),
        ),
      ],
    );
  }
}
