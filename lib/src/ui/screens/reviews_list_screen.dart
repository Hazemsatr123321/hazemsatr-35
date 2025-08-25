import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/review_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewsListScreen extends StatefulWidget {
  final String revieweeId;
  const ReviewsListScreen({super.key, required this.revieweeId});

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
  late Future<List<Review>> _reviewsFuture;
  late SupabaseClient _supabase;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supabase = Provider.of<SupabaseClient>(context, listen: false);
    _reviewsFuture = _fetchReviews();
  }

  Future<List<Review>> _fetchReviews() async {
    try {
      final data = await _supabase
          .from('reviews')
          .select('*, buyer:buyer_id(*)')
          .eq('seller_id', widget.revieweeId)
          .order('created_at', ascending: false);
      return (data as List).map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('التقييمات والمراجعات'),
      ),
      child: FutureBuilder<List<Review>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل التقييمات: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد تقييمات لعرضها.'));
          }
          final reviews = snapshot.data!;
          return ListView.separated(
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          review.buyer?.business_name ?? 'Anonymous',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        _buildStarRating(review.rating.toDouble()),
                      ],
                    ),
                    if (review.comment != null && review.comment!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(review.comment!),
                    ]
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }
}
