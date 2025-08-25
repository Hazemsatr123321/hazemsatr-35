import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/models/bid_model.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';

class AuctionDetailScreen extends StatefulWidget {
  final Product product;
  const AuctionDetailScreen({super.key, required this.product});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  late Future<List<Bid>> _bidsFuture;
  late SupabaseClient _supabase;
  late RealtimeChannel _bidsChannel;
  Timer? _timer;
  Duration? _timeRemaining;
  num? _currentHighestBid;

  final _bidAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentHighestBid = widget.product.highest_bid ?? widget.product.start_price;
    _calculateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTimeRemaining());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supabase = Provider.of<SupabaseClient>(context, listen: false);
    _bidsFuture = _fetchBids();
    _subscribeToBids();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_bidsChannel);
    _timer?.cancel();
    _bidAmountController.dispose();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    if (widget.product.end_time == null) return;
    final now = DateTime.now();
    final endDate = DateTime.parse(widget.product.end_time!);
    if (now.isAfter(endDate)) {
      setState(() => _timeRemaining = Duration.zero);
      _timer?.cancel();
    } else {
      setState(() => _timeRemaining = endDate.difference(now));
    }
  }

  Future<List<Bid>> _fetchBids() async {
    final data = await _supabase
        .from('bids')
        .select('*, profile:user_id(*)') // Join with profiles
        .eq('product_id', widget.product.id)
        .order('created_at', ascending: false);
    return (data as List).map((json) => Bid.fromJson(json)).toList();
  }

  void _subscribeToBids() {
    _bidsChannel = _supabase
        .channel('public:bids:product_id=eq.${widget.product.id}')
        .on<Map<String, dynamic>>(
          'postgres_changes',
          (payload) {
            final newBidJson = payload['new'];
            // The profile data won't be in the realtime payload, so we refetch.
            setState(() {
              _currentHighestBid = newBidJson['amount'];
              _bidsFuture = _fetchBids();
            });
          },
          event: 'INSERT',
          schema: 'public',
          table: 'bids',
        )
        .subscribe();
  }

  Future<void> _placeBid() async {
    final amountText = _bidAmountController.text.trim();
    if (amountText.isEmpty) return;
    final amount = num.tryParse(amountText);
    if (amount == null) return;

    try {
      await _supabase.functions.invoke(
        'place_bid',
        body: {'product_id': widget.product.id, 'bid_amount': amount},
      );
      _bidAmountController.clear();
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error Placing Bid'),
            content: Text(e.toString()),
            actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.of(context).pop())],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.product.name)),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product.imageUrl != null) Image.network(widget.product.imageUrl!),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(widget.product.description ?? 'No description.'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Bidding History', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              _buildBidsList(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for bottom bar
            ],
          ),
          _buildTopStatusBar(),
          _buildBottomBidInput(),
        ],
      ),
    );
  }

  Widget _buildBidsList() {
    return FutureBuilder<List<Bid>>(
      future: _bidsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: CustomLoadingIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(child: Center(child: Text('No bids yet. Be the first!')));
        }
        final bids = snapshot.data!;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final bid = bids[index];
              return Text('Bid of ${bid.amount} at ${bid.createdAt}'); // Placeholder UI
            },
            childCount: bids.length,
          ),
        );
      },
    );
  }

  Widget _buildTopStatusBar() {
    final isClosed = _timeRemaining == Duration.zero;
    final statusText = isClosed ? 'المزاد مغلق' : 'الوقت المتبقي: ${_formatDuration(_timeRemaining!)}';
    final statusColor = isClosed ? CupertinoColors.destructiveRed : CupertinoColors.activeGreen;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16).copyWith(top: 50), // Adjust for notch
        color: AppTheme.darkSurface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(statusText, style: TextStyle(color: statusColor)),
            Text('أعلى سعر: ${_currentHighestBid} د.ع', style: TextStyle(color: AppTheme.goldAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBidInput() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.darkSurface,
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _bidAmountController,
                  placeholder: 'أدخل مبلغ المزايدة',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton.filled(
                onPressed: _timeRemaining == Duration.zero ? null : _placeBid,
                child: const Text('زايد'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    return d.toString().split('.').first.padLeft(8, "0");
  }
}
