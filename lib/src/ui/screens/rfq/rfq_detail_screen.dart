import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

// Models for this screen
class RfqOffer {
  final String id;
  final String sellerId;
  final num price;
  final String? notes;
  final DateTime createdAt;

  RfqOffer({required this.id, required this.sellerId, required this.price, this.notes, required this.createdAt});

  factory RfqOffer.fromJson(Map<String, dynamic> json) {
    return RfqOffer(
      id: json['id'],
      sellerId: json['seller_id'],
      price: json['price'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class RfqDetail {
  final String id;
  final String description;
  final String? quantity;
  final DateTime createdAt;
  final List<RfqOffer> offers;

  RfqDetail({required this.id, required this.description, this.quantity, required this.createdAt, required this.offers});
}

class RfqDetailScreen extends StatefulWidget {
  final String rfqId;
  const RfqDetailScreen({super.key, required this.rfqId});

  @override
  State<RfqDetailScreen> createState() => _RfqDetailScreenState();
}

class _RfqDetailScreenState extends State<RfqDetailScreen> {
  late Future<RfqDetail> _rfqDetailFuture;
  late SupabaseClient _supabase;
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supabase = Provider.of<SupabaseClient>(context, listen: false);
    _rfqDetailFuture = _fetchRfqDetails();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<RfqDetail> _fetchRfqDetails() async {
    try {
      final rfqFuture = _supabase.from('rfqs').select().eq('id', widget.rfqId).single();
      final offersFuture = _supabase.from('rfq_offers').select().eq('rfq_id', widget.rfqId).order('created_at', ascending: true);

      final results = await Future.wait([rfqFuture, offersFuture]);

      final rfqData = results[0] as Map<String, dynamic>;
      final offersData = results[1] as List;

      final offers = offersData.map((json) => RfqOffer.fromJson(json)).toList();

      return RfqDetail(
        id: rfqData['id'],
        description: rfqData['product_description'],
        quantity: rfqData['quantity'],
        createdAt: DateTime.parse(rfqData['created_at']),
        offers: offers,
      );

    } catch (e) {
      debugPrint('Error fetching RFQ details: $e');
      rethrow;
    }
  }

  Future<void> _submitOffer() async {
    if (_priceController.text.isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      await _supabase.from('rfq_offers').insert({
        'rfq_id': widget.rfqId,
        'price': num.parse(_priceController.text),
        'notes': _notesController.text.trim(),
      });
      _priceController.clear();
      _notesController.clear();
      // Refresh the details
      setState(() {
        _rfqDetailFuture = _fetchRfqDetails();
      });
    } catch (e) {
       if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('خطأ'),
            content: Text('فشل إرسال العرض: $e'),
            actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('موافق'), onPressed: () => Navigator.of(context).pop())],
          ),
        );
      }
    } finally {
       if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('تفاصيل الطلب')),
      child: FutureBuilder<RfqDetail>(
        future: _rfqDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('لم يتم العثور على الطلب.'));
          }

          final rfq = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildRfqInfo(rfq),
                    const SizedBox(height: 24),
                    Text('العروض المستلمة (${rfq.offers.length})', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
                    Divider(color: AppTheme.darkSurface),
                    if (rfq.offers.isEmpty)
                      const Padding(padding: EdgeInsets.all(32.0), child: Center(child: Text('لم يتم تقديم أي عروض بعد.')))
                    else
                      ...rfq.offers.map((offer) => _buildOfferTile(offer)),
                  ],
                ),
              ),
              _buildOfferInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRfqInfo(RfqDetail rfq) {
    final theme = CupertinoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rfq.description, style: theme.textTheme.navTitleTextStyle),
          const SizedBox(height: 8),
          Text('الكمية: ${rfq.quantity ?? 'غير محدد'}', style: theme.textTheme.textStyle.copyWith(color: AppTheme.secondaryTextColor)),
          const SizedBox(height: 8),
          Text('قبل ${timeago.format(rfq.createdAt, locale: 'ar')}', style: theme.textTheme.tabLabelTextStyle.copyWith(color: AppTheme.secondaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildOfferTile(RfqOffer offer) {
    final theme = CupertinoTheme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${offer.price} د.ع', style: theme.textTheme.textStyle.copyWith(fontWeight: FontWeight.bold, color: AppTheme.goldAccent)),
              Text('بائع: ...${offer.sellerId.substring(offer.sellerId.length - 6)}', style: theme.textTheme.tabLabelTextStyle),
            ],
          ),
          if(offer.notes != null && offer.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(offer.notes!, style: theme.textTheme.textStyle),
          ]
        ],
      ),
    );
  }

  Widget _buildOfferInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.darkSurface,
          border: Border(top: BorderSide(color: AppTheme.charcoalBackground)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoTextField(
              controller: _priceController,
              placeholder: 'اكتب سعرك هنا...',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefix: const Padding(padding: EdgeInsets.only(left: 8.0), child: Text('د.ع')),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _notesController,
              placeholder: 'ملاحظات إضافية (اختياري)',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _isSubmitting
                ? const CupertinoActivityIndicator()
                : CupertinoButton.filled(
                    onPressed: _submitOffer,
                    child: const Text('إرسال العرض'),
                  )
          ],
        ),
      ),
    );
  }
}
