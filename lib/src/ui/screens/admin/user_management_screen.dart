import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_iraq/main.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<Profile>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<Profile>> _fetchUsers() async {
    try {
      final data = await supabase.from('profiles').select().order('created_at', ascending: false);
      return (data as List).map((json) => Profile.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      rethrow;
    }
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = _fetchUsers();
    });
  }

  Future<void> _updateUserStatus(String userId, String newStatus) async {
    try {
      await supabase.from('profiles').update({'verification_status': newStatus}).eq('id', userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة المستخدم بنجاح.'), backgroundColor: Colors.green),
      );
      _refreshUsers();
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحديث الحالة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showStatusActionSheet(Profile user) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('تغيير حالة "${user.business_name ?? user.username}"'),
        message: Text('الحالة الحالية: ${user.verification_status}'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('الموافقة على الحساب (approved)'),
            onPressed: () {
              Navigator.pop(context);
              _updateUserStatus(user.id, 'approved');
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: const Text('رفض الحساب (rejected)'),
            onPressed: () {
              Navigator.pop(context);
              _updateUserStatus(user.id, 'rejected');
            },
          ),
           CupertinoActionSheetAction(
            child: const Text('جعله قيد المراجعة (pending)'),
            onPressed: () {
              Navigator.pop(context);
              _updateUserStatus(user.id, 'pending');
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('إلغاء'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('إدارة المستخدمين'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _refreshUsers,
        ),
      ),
      child: FutureBuilder<List<Profile>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل المستخدمين: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد مستخدمون لعرضهم.'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Material( // Material is needed for InkWell ripple effect on tap
                child: CupertinoListTile(
                  title: Text(user.business_name ?? user.username ?? 'مستخدم غير معروف'),
                  subtitle: Text(user.business_type == 'wholesaler' ? 'تاجر جملة' : 'صاحب محل'),
                  leading: _buildStatusIndicator(user.verification_status),
                  trailing: const Icon(CupertinoIcons.forward),
                  onTap: () => _showStatusActionSheet(user),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(String? status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'approved':
        color = CupertinoColors.activeGreen;
        icon = CupertinoIcons.check_mark_circled_solid;
        break;
      case 'rejected':
        color = CupertinoColors.destructiveRed;
        icon = CupertinoIcons.xmark_octagon_fill;
        break;
      default: // pending
        color = CupertinoColors.activeOrange;
        icon = CupertinoIcons.hourglass;
    }
    return Icon(icon, color: color);
  }
}
