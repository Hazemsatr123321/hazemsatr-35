import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/rfq_model.dart';
import 'package:smart_iraq/src/ui/widgets/cupertino_list_tile.dart' as custom;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:smart_iraq/src/ui/screens/rfq/rfq_detail_screen.dart';


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
              return custom.CupertinoListTile(
                title: Text(rfq.title, maxLines: 2, overflow: TextOverflow.ellipsis),
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
