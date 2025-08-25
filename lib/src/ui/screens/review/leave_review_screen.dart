import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/profile_provider.dart';
import '../../../models/product_model.dart';

class LeaveReviewScreen extends StatefulWidget {
  final Product product;

  const LeaveReviewScreen({Key? key, required this.product}) : super(key: key);

  @override
  _LeaveReviewScreenState createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final buyerId = profileProvider.profile?.id;

    if (buyerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to leave a review.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await Supabase.instance.client.from('reviews').insert({
        'product_id': widget.product.id,
        'buyer_id': buyerId,
        'seller_id': widget.product.sellerId,
        'rating': _rating.toInt(),
        'comment': _commentController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Leave a Review'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review for: ${widget.product.name}', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
              const SizedBox(height: 20),
              const Text('Your Rating:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                    child: Icon(
                      index < _rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                      color: Colors.amber,
                      size: 40,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              const Text('Your Comment (Optional):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _commentController,
                maxLines: 5,
                placeholder: 'Share your experience...',
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : CupertinoButton.filled(
                      onPressed: _submitReview,
                      child: const Text('Submit Review'),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
