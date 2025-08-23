import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/charity_campaign_model.dart';
import 'package:smart_iraq/src/models/donation_method_model.dart';
import 'package:smart_iraq/src/models/product_model.dart'; // Import Product model

class CharityScreen extends StatefulWidget {
  const CharityScreen({super.key});

  @override
  State<CharityScreen> createState() => _CharityScreenState();
}

class _CharityScreenState extends State<CharityScreen> {
  Future<Map<String, List<dynamic>>>? _charityDataFuture;

  @override
  void initState() {
    super.initState();
    _charityDataFuture = _fetchCharityData();
  }

  Future<Map<String, List<dynamic>>> _fetchCharityData() async {
    try {
      final campaignsFuture = supabase.from('charity_campaigns').select().eq('is_active', true);
      final methodsFuture = supabase.from('donation_methods').select().eq('is_active', true);
      final donationsFuture = supabase.from('products').select().eq('is_available_for_donation', true);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('دعم القضايا الخيرية'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
             _charityDataFuture = _fetchCharityData();
          });
        },
        child: FutureBuilder<Map<String, List<dynamic>>>(
          future: _charityDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
                  const Divider(),
                ],
                 if (donations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'تبرعات عينية من التجار'),
                  ...donations.map((product) => _buildDonatedProductCard(context, product)),
                   const SizedBox(height: 24),
                  const Divider(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildDonationMethodCard(BuildContext context, DonationMethod method) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(method.methodName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(method.accountDetails, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: method.accountDetails));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الرقم إلى الحافظة')),
                    );
                  },
                ),
              ],
            ),
            if (method.instructions != null && method.instructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(method.instructions!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDonatedProductCard(BuildContext context, Product product) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            if (product.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(product.imageUrl!, width: 80, height: 80, fit: BoxFit.cover),
              )
            else
              Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.inventory_2_outlined)),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4.0),
                  Text(
                    'التبرع: ${product.donation_description ?? 'كمية للمحتاجين'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, CharityCampaign campaign) {
    final goal = campaign.goalAmount ?? 0;
    final progress = goal > 0 ? (campaign.currentAmount / goal) : 0.0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (campaign.imageUrl != null)
            Image.network(
              campaign.imageUrl!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 180),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(campaign.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                if (campaign.description != null) ...[
                  const SizedBox(height: 8),
                  Text(campaign.description!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                if (goal > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${campaign.currentAmount.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} دينار', style: Theme.of(context).textTheme.bodySmall),
                      Text('${(progress * 100).toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
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
