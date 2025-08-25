import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';

class Bid {
  final String id;
  final String bidderId;
  final num amount;
  final DateTime createdAt;

  Bid({required this.id, required this.bidderId, required this.amount, required this.createdAt});

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id'].toString(),
      bidderId: json['bidder_id'],
      amount: json['amount'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

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
    final data = await _supabase.from('bids').select().eq('auction_id', widget.product.id).order('created_at', ascending: false);
    return (data as List).map((json) => Bid.fromJson(json)).toList();
  }

  void _subscribeToBids() {
    _bidsChannel = _supabase
      .channel('public:bids:auction_id=eq.${widget.product.id}')
      .on<Map<String, dynamic>>(
        'postgres_changes',
        (payload) {
          final newBid = Bid.fromJson(payload['new']);
          setState(() {
             _currentHighestBid = newBid.amount;
             _bidsFuture = _fetchBids(); // Refresh the whole list
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
        body: {'auction_id': widget.product.id, 'bid_amount': amount},
      );
      _bidAmountController.clear();
      // UI will update automatically via the realtime subscription
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(title: const Text('خطأ'), content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.product.name)),
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Product Image, Description, etc.
              const SizedBox(height: 80), // Space for the status bar at the top
            ],
          ),
          _buildTopStatusBar(),
          _buildBottomBidInput(),
        ],
      ),
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
