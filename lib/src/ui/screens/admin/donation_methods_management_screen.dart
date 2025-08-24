import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/donation_method_model.dart';
import 'package:smart_iraq/src/ui/screens/admin/add_edit_donation_method_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonationMethodsManagementScreen extends StatefulWidget {
  const DonationMethodsManagementScreen({super.key});

  @override
  State<DonationMethodsManagementScreen> createState() => _DonationMethodsManagementScreenState();
}

class _DonationMethodsManagementScreenState extends State<DonationMethodsManagementScreen> {
  late Future<List<DonationMethod>> _methodsFuture;
  late SupabaseClient _supabase;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supabase = Provider.of<SupabaseClient>(context, listen: false);
    _methodsFuture = _fetchMethods();
  }

  Future<List<DonationMethod>> _fetchMethods() async {
    try {
      final data = await _supabase.from('donation_methods').select().order('created_at', ascending: false);
      return (data as List).map((json) => DonationMethod.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching donation methods: $e');
      rethrow;
    }
  }

  void _refreshMethods() {
    setState(() {
      _methodsFuture = _fetchMethods();
    });
  }

  void _navigateToAddEditScreen({DonationMethod? method}) {
     Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => AddEditDonationMethodScreen(method: method)),
    ).then((_) => _refreshMethods());
  }

  Future<void> _deleteMethod(String methodId) async {
     final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف طريقة الدفع هذه؟'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(c).pop(false), child: const Text('إلغاء')),
          CupertinoDialogAction(onPressed: () => Navigator.of(c).pop(true), isDestructiveAction: true, child: const Text('حذف')),
        ],
      ),
    );
    if (shouldDelete == true) {
      try {
        await _supabase.from('donation_methods').delete().eq('id', methodId);
        _refreshMethods();
      } catch(e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الحذف: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('إدارة طرق الدفع'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: _navigateToAddEditScreen,
        ),
      ),
      child: FutureBuilder<List<DonationMethod>>(
        future: _methodsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل البيانات: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد طرق دفع مدارة حالياً.'));
          }

          final methods = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refreshMethods(),
            child: ListView.builder(
              itemCount: methods.length,
              itemBuilder: (context, index) {
                final method = methods[index];
                return Material(
                  child: ListTile(
                    leading: const Icon(CupertinoIcons.creditcard),
                    title: Text(method.methodName),
                    subtitle: Text(method.accountDetails),
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.ellipsis),
                      onPressed: () {
                         showCupertinoModalPopup(context: context, builder: (context) => CupertinoActionSheet(
                          actions: [
                            CupertinoActionSheetAction(
                              child: const Text('تعديل'),
                              onPressed: () {
                                Navigator.pop(context);
                                _navigateToAddEditScreen(method: method);
                              },
                            ),
                             CupertinoActionSheetAction(
                              isDestructiveAction: true,
                              child: const Text('حذف'),
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteMethod(method.id);
                              },
                            )
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            child: const Text('إلغاء'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ));
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
