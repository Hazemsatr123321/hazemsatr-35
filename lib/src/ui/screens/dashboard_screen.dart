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
    final response = await supabase
        .from('products')
        .select()
        .eq('user_id', userId);

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
              child: Text(
                'ليس لديك إعلانات لعرض الإحصائيات.\n ابدأ بنشر إعلانك الأول!',
                textAlign: TextAlign.center,
              ),
            );
          }

          final products = snapshot.data!;

          // Calculate stats
          final totalAds = products.length;
          final totalValue = products.fold<double>(0.0, (sum, item) => sum + item.price);

          final currencyFormat = NumberFormat.currency(locale: 'ar_IQ', symbol: 'د.ع');

          return GridView.count(
            padding: const EdgeInsets.all(16.0),
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            children: [
              _buildStatCard(
                icon: Icons.list_alt,
                label: 'إجمالي الإعلانات',
                value: totalAds.toString(),
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.attach_money,
                label: 'القيمة الإجمالية للإعلانات',
                value: currencyFormat.format(totalValue),
                color: Colors.green,
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
