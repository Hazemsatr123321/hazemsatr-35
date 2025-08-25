import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:smart_iraq/src/ui/screens/rfq/rfq_detail_screen.dart';

// A simple model for this screen, can be moved later
class Rfq {
  final String id;
  final String description;
  final String? quantity;
  final DateTime createdAt;

  Rfq({required this.id, required this.description, this.quantity, required this.createdAt});

  factory Rfq.fromJson(Map<String, dynamic> json) {
    return Rfq(
      id: json['id'],
      description: json['product_description'],
      quantity: json['quantity'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}


class BrowseRfqsScreen extends StatefulWidget {
  const BrowseRfqsScreen({super.key});

  @override
  State<BrowseRfqsScreen> createState() => _BrowseRfqsScreenState();
}

class _BrowseRfqsScreenState extends State<BrowseRfqsScreen> {
  late Future<List<Rfq>> _rfqsFuture;
  late SupabaseClient _supabase;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supabase = Provider.of<SupabaseClient>(context, listen: false);
    _rfqsFuture = _fetchRfqs();
  }

  Future<List<Rfq>> _fetchRfqs() async {
    try {
      final data = await _supabase
          .from('rfqs')
          .select()
          .eq('status', 'open')
          .order('created_at', ascending: false);
      return (data as List).map((json) => Rfq.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching RFQs: $e');
      rethrow;
    }
  }

  void _refreshRfqs() {
    setState(() {
      _rfqsFuture = _fetchRfqs();
    });
  }

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('ar', timeago.ArMessages());

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('طلبات عروض الأسعار'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _refreshRfqs,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: FutureBuilder<List<Rfq>>(
        future: _rfqsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد طلبات عروض أسعار حالياً.'));
          }

          final rfqs = snapshot.data!;
          return ListView.builder(
            itemCount: rfqs.length,
            itemBuilder: (context, index) {
              final rfq = rfqs[index];
              return CupertinoListTile(
                title: Text(rfq.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('الكمية: ${rfq.quantity ?? 'غير محدد'}'),
                trailing: Text(timeago.format(rfq.createdAt, locale: 'ar')),
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(builder: (context) => RfqDetailScreen(rfqId: rfq.id)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// A basic CupertinoListTile for this screen.
class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CupertinoListTile({super.key, required this.title, this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: CupertinoTheme.of(context).textTheme.textStyle,
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle(
                      style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle,
                      child: subtitle!,
                    ),
                  ]
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              DefaultTextStyle(
                style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle,
                child: trailing!,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
