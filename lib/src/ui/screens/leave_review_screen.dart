import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaveReviewScreen extends StatefulWidget {
  final String revieweeId;
  const LeaveReviewScreen({super.key, required this.revieweeId});

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار تقييم (نجمة واحدة على الأقل)'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final supabase = Provider.of<SupabaseClient>(context, listen: false);
      final reviewerId = supabase.auth.currentUser!.id;
      await supabase.from('reviews').insert({
        'reviewer_id': reviewerId,
        'reviewee_id': widget.revieweeId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('شكراً لك، تم إرسال تقييمك بنجاح!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('إضافة تقييم'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 20),
            Text('تقييمك لهذا التاجر', style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      index < _rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                  );
                }),
              ),
            ),
            const SizedBox(height: 32),
            CupertinoTextField(
              controller: _commentController,
              placeholder: 'أضف تعليقًا (اختياري)',
              maxLines: 5,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: CupertinoColors.extraLightBackgroundGray,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 32),
             _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : CupertinoButton.filled(
                    onPressed: _submitReview,
                    child: const Text('إرسال التقييم'),
                  ),
          ],
        ),
      ),
    );
  }
}
