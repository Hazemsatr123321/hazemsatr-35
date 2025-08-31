import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchUserProducts();
  }

  Future<List<Product>> _fetchUserProducts() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw 'User not logged in';
    }
    final response = await supabase.from('products').select().eq('user_id', userId);
    return (response as List).map((json) => Product.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة معلومات التاجر'),
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ليس لديك إعلانات لعرض الإحصائيات.\n ابدأ بنشر إعلانك الأول!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!;
          final totalAds = products.length;
          final totalValue = products.fold<double>(0.0, (sum, item) => sum + item.price);
          final totalViews = products.fold<int>(0, (sum, item) => sum + (item.viewCount ?? 0));
          final totalMessages = products.fold<int>(0, (sum, item) => sum + (item.messageCount ?? 0));
          final currencyFormat = NumberFormat.currency(locale: 'ar_IQ', symbol: ' د.ع', decimalDigits: 0);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _productsFuture = _fetchUserProducts();
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildStatCard(
                  icon: Icons.list_alt_outlined,
                  label: 'إجمالي الإعلانات',
                  value: totalAds.toString(),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  icon: Icons.monetization_on_outlined,
                  label: 'القيمة الإجمالية للإعلانات',
                  value: currencyFormat.format(totalValue),
                  color: Colors.green.shade700,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  icon: Icons.visibility_outlined,
                  label: 'مجموع المشاهدات',
                  value: totalViews.toString(),
                  color: Colors.orange.shade700,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  icon: Icons.chat_bubble_outline,
                  label: 'مجموع الرسائل',
                  value: totalMessages.toString(),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(
                    color: color.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
