import 'package:flutter/cupertino.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/managed_ad_model.dart';
import 'package:smart_iraq/src/ui/screens/admin/add_edit_managed_ad_screen.dart';

class ManagedAdsManagementScreen extends StatefulWidget {
  const ManagedAdsManagementScreen({super.key});

  @override
  State<ManagedAdsManagementScreen> createState() => _ManagedAdsManagementScreenState();
}

class _ManagedAdsManagementScreenState extends State<ManagedAdsManagementScreen> {
  late Future<List<ManagedAd>> _adsFuture;

  @override
  void initState() {
    super.initState();
    _adsFuture = _fetchAds();
  }

  Future<List<ManagedAd>> _fetchAds() async {
    try {
      final data = await supabase.from('managed_ads').select().order('created_at', ascending: false);
      return (data as List).map((json) => ManagedAd.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching managed ads: $e');
      rethrow;
    }
  }

  Future<void> _refreshAds() async {
    setState(() {
      _adsFuture = _fetchAds();
    });
  }

  void _navigateToAddEditScreen({ManagedAd? ad}) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => AddEditManagedAdScreen(ad: ad)),
    ).then((_) => _refreshAds());
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('موافق'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  Future<void> _deleteAd(String adId) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا الإعلان؟'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(c).pop(false), child: const Text('إلغاء')),
          CupertinoDialogAction(onPressed: () => Navigator.of(c).pop(true), isDestructiveAction: true, child: const Text('حذف')),
        ],
      ),
    );
    if (shouldDelete == true) {
      try {
        await supabase.from('managed_ads').delete().eq('id', adId);
        _refreshAds();
      } catch(e) {
        if (mounted) {
           _showErrorDialog('خطأ في الحذف: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('إدارة الإعلانات المدارة'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () => _navigateToAddEditScreen(),
        ),
      ),
      child: FutureBuilder<List<ManagedAd>>(
        future: _adsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل الإعلانات: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد إعلانات مدارة حالياً.'));
          }

          final ads = snapshot.data!;
          return CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                 onRefresh: _refreshAds,
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                     final ad = ads[index];
                      return _buildAdListItem(ad);
                  },
                  childCount: ads.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdListItem(ManagedAd ad) {
    return GestureDetector(
      onTap: () {
        showCupertinoModalPopup(context: context, builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              child: const Text('تعديل'),
              onPressed: () {
                Navigator.pop(context);
                _navigateToAddEditScreen(ad: ad);
              },
            ),
              CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: const Text('حذف'),
              onPressed: () {
                Navigator.pop(context);
                _deleteAd(ad.id);
              },
            )
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.pop(context),
          ),
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CupertinoColors.separator, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ad.imageUrl.isNotEmpty
                  ? Image.network(
                      ad.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress == null ? child : const CupertinoActivityIndicator(),
                      errorBuilder: (context, error, stackTrace) => const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
                    )
                  : Container(color: CupertinoColors.systemGrey5, child: const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ad.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(ad.isActive ? 'فعال' : 'غير فعال', style: TextStyle(color: ad.isActive ? CupertinoColors.activeGreen : CupertinoColors.systemGrey)),
                ],
              ),
            ),
            const Icon(CupertinoIcons.ellipsis, color: CupertinoColors.systemGrey2),
          ],
        ),
      ),
    );
  }
}
