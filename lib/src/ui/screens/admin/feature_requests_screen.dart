import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/feature_request_model.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureRequestsScreen extends StatefulWidget {
  const FeatureRequestsScreen({Key? key}) : super(key: key);

  @override
  _FeatureRequestsScreenState createState() => _FeatureRequestsScreenState();
}

class _FeatureRequestsScreenState extends State<FeatureRequestsScreen> {
  late Future<List<FeatureRequest>> _requestsFuture;
  late final SupabaseClient _supabase;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _requestsFuture = _fetchRequests();
  }

  Future<List<FeatureRequest>> _fetchRequests() async {
    final response = await _supabase
        .from('feature_requests')
        .select('*, user:user_id(*), product:product_id(*)')
        .eq('status', 'pending')
        .order('created_at');
    return (response as List).map((json) => FeatureRequest.fromJson(json)).toList();
  }

  void _refresh() {
    setState(() {
      _requestsFuture = _fetchRequests();
    });
  }

  Future<void> _approveRequest(FeatureRequest request) async {
    try {
      // Use an RPC to perform both updates in a single transaction
      await _supabase.rpc('approve_feature_request', params: {
        'request_id': request.id,
        'prod_id': request.productId,
      });
      _refresh();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    try {
      await _supabase
          .from('feature_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId);
      _refresh();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Pending Feature Requests'),
      ),
      child: FutureBuilder<List<FeatureRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoadingIndicator();
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending requests.'));
          }
          final requests = snapshot.data!;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Product: ${request.product?.name ?? 'N/A'}'),
                      Text('User: ${request.user?.business_name ?? 'N/A'}'),
                      Text('Transaction Ref: ${request.transactionRef}'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CupertinoButton(
                            child: const Text('Reject'),
                            onPressed: () => _rejectRequest(request.id),
                          ),
                          CupertinoButton.filled(
                            child: const Text('Approve'),
                            onPressed: () => _approveRequest(request),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
