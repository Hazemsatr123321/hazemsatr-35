import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/charity_campaign_model.dart';
import 'package:smart_iraq/src/models/donation_method_model.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';

class CharityScreen extends StatefulWidget {
  const CharityScreen({super.key});

  @override
  State<CharityScreen> createState() => _CharityScreenState();
}

class _CharityScreenState extends State<CharityScreen> {
  Future<Map<String, List<dynamic>>>? _charityDataFuture;
  late SupabaseClient _supabase;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supabase = Provider.of<SupabaseClient>(context, listen: false);
    _charityDataFuture = _fetchCharityData();
  }

  Future<Map<String, List<dynamic>>> _fetchCharityData() async {
    try {
      final campaignsFuture = _supabase.from('charity_campaigns').select().eq('is_active', true);
      final methodsFuture = _supabase.from('donation_methods').select().eq('is_active', true);
      final donationsFuture = _supabase.from('products').select().eq('is_available_for_donation', true);

      final results = await Future.wait([campaignsFuture, methodsFuture, donationsFuture]);

      final campaigns = (results[0] as List).map((json) => CharityCampaign.fromJson(json)).toList();
      final methods = (results[1] as List).map((json) => DonationMethod.fromJson(json)).toList();
      final donations = (results[2] as List).map((json) => Product.fromJson(json)).toList();

      return {'campaigns': campaigns, 'methods': methods, 'donations': donations};
    } catch (e) {
      debugPrint('Error fetching charity data: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('دعم القضايا الخيرية'),
      ),
      child: RefreshIndicator.adaptive(
        onRefresh: () async {
          setState(() {
              _charityDataFuture = _fetchCharityData();
          });
        },
        child: FutureBuilder<Map<String, List<dynamic>>>(
          future: _charityDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CustomLoadingIndicator();
            }
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ في تحميل البيانات: ${snapshot.error}'));
            }
            if (!snapshot.hasData || (snapshot.data!['campaigns']!.isEmpty && snapshot.data!['methods']!.isEmpty && snapshot.data!['donations']!.isEmpty)) {
              return const Center(child: Text('لا توجد حملات أو تبرعات متاحة حالياً.'));
            }

            final campaigns = snapshot.data!['campaigns'] as List<CharityCampaign>;
            final methods = snapshot.data!['methods'] as List<DonationMethod>;
            final donations = snapshot.data!['donations'] as List<Product>;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (methods.isNotEmpty) ...[
                  _buildSectionTitle(context, 'طرق التبرع المالي'),
                  ...methods.map((method) => _buildDonationMethodCard(context, method)),
                  const SizedBox(height: 24),
                  const CupertinoListTileDivider(),
                ],
                  if (donations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'تبرعات عينية من التجار'),
                  ...donations.map((product) => _buildDonatedProductCard(context, product)),
                    const SizedBox(height: 24),
                  const CupertinoListTileDivider(),
                ],
                if (campaigns.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'حملات التبرع المالي'),
                  ...campaigns.map((campaign) => _buildCampaignCard(context, campaign)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = CupertinoTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: theme.textTheme.navLargeTitleTextStyle.copyWith(fontSize: 22, color: AppTheme.goldAccent),
      ),
    );
  }

  Widget _buildDonationMethodCard(BuildContext context, DonationMethod method) {
    final theme = CupertinoTheme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(method.methodName, style: theme.textTheme.navTitleTextStyle),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(method.accountDetails, style: theme.textTheme.textStyle.copyWith(fontWeight: FontWeight.bold))),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.doc_on_clipboard),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: method.accountDetails));
                  // Using Cupertino-styled feedback
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('تم النسخ'),
                      content: const Text('تم نسخ الرقم إلى الحافظة.'),
                      actions: [
                        CupertinoDialogAction(isDefaultAction: true, child: const Text('موافق'), onPressed: () => Navigator.of(context).pop())
                      ],
                    )
                  );
                },
              ),
            ],
          ),
          if (method.instructions != null && method.instructions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(method.instructions!, style: theme.textTheme.tabLabelTextStyle),
          ],
        ],
      ),
    );
  }

  Widget _buildDonatedProductCard(BuildContext context, Product product) {
    final theme = CupertinoTheme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
       decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: product.imageUrl != null
              ? Image.network(product.imageUrl!, width: 80, height: 80, fit: BoxFit.cover)
              : Container(width: 80, height: 80, color: AppTheme.charcoalBackground, child: const Icon(CupertinoIcons.gift, color: AppTheme.secondaryTextColor)),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: theme.textTheme.textStyle.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4.0),
                Text(
                  'التبرع: ${product.donation_description ?? 'كمية للمحتاجين'}',
                  style: theme.textTheme.tabLabelTextStyle.copyWith(color: CupertinoColors.activeGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, CharityCampaign campaign) {
    final theme = CupertinoTheme.of(context);
    final goal = campaign.goalAmount ?? 0;
    final progress = goal > 0 ? (campaign.currentAmount / goal) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (campaign.imageUrl != null)
            Image.network(
              campaign.imageUrl!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(height: 180, color: AppTheme.charcoalBackground, child: const Icon(CupertinoIcons.photo, size: 50)),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(campaign.title, style: theme.textTheme.navTitleTextStyle),
                if (campaign.description != null) ...[
                  const SizedBox(height: 8),
                  Text(campaign.description!, style: theme.textTheme.textStyle),
                ],
                if (goal > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${campaign.currentAmount.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} د.ع', style: theme.textTheme.tabLabelTextStyle),
                      Text('${(progress * 100).toStringAsFixed(1)}%', style: theme.textTheme.tabLabelTextStyle.copyWith(color: AppTheme.goldAccent)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppTheme.charcoalBackground,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CupertinoListTileDivider extends StatelessWidget {
  const CupertinoListTileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Divider(color: AppTheme.darkSurface),
    );
  }
}
