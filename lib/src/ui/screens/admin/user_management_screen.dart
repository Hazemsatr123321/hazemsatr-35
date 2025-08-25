import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
import 'package:smart_iraq/src/ui/widgets/cupertino_list_tile.dart' as custom;
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<List<Profile>> _usersFuture;
  late SupabaseClient _supabase;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _supabase = Provider.of<SupabaseClient>(context, listen: false);
    _usersFuture = _fetchUsers();
  }

  Future<List<Profile>> _fetchUsers() async {
    try {
      final data = await _supabase.from('profiles').select().order('created_at', ascending: false);
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

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _supabase.from('profiles').update({'role': newRole}).eq('id', userId);
      _showSuccessSnackBar('تم تحديث دور المستخدم بنجاح.');
      _refreshUsers();
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث الدور: $e');
    }
  }

  Future<void> _updateBanStatus(String userId, bool isBanned) async {
    try {
      await _supabase.from('profiles').update({'is_banned': isBanned}).eq('id', userId);
       _showSuccessSnackBar(isBanned ? 'تم حظر المستخدم بنجاح.' : 'تم رفع الحظر عن المستخدم بنجاح.');
      _refreshUsers();
    } catch (e) {
      _showErrorSnackBar('Failed to update ban status.');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    final snackBar = SnackBar(content: Text(message), backgroundColor: CupertinoColors.activeGreen);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showErrorSnackBar(String message) {
     if (!mounted) return;
    final snackBar = SnackBar(content: Text(message), backgroundColor: CupertinoColors.destructiveRed);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showUserActions(Profile user) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('إدارة المستخدم: ${user.business_name ?? user.username}'),
        actions: <CupertinoActionSheetAction>[
          if (user.role != 'admin')
            CupertinoActionSheetAction(
              child: const Text('ترقية إلى مدير (Admin)'),
              onPressed: () {
                Navigator.pop(context);
                _updateUserRole(user.id, 'admin');
              },
            ),
          if (user.role == 'admin')
            CupertinoActionSheetAction(
              child: const Text('إزالة من الإدارة'),
              onPressed: () {
                Navigator.pop(context);
                _updateUserRole(user.id, 'user');
              },
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: !(user.is_banned ?? false),
            child: Text((user.is_banned ?? false) ? 'رفع الحظر عن المستخدم' : 'حظر المستخدم'),
            onPressed: () {
              Navigator.pop(context);
              _updateBanStatus(user.id, !(user.is_banned ?? false));
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('إلغاء'),
          onPressed: () => Navigator.pop(context),
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
              return custom.CupertinoListTile(
                title: Text(user.business_name ?? user.username ?? 'مستخدم غير معروف'),
                subtitle: Text(user.business_type == 'wholesaler' ? 'تاجر جملة' : 'صاحب محل'),
                leading: _buildUserStatusIcon(user),
                trailing: const Icon(CupertinoIcons.chevron_forward),
                onTap: () => _showUserActions(user),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserStatusIcon(Profile user) {
    if (user.is_banned == true) {
      return const Icon(CupertinoIcons.xmark_circle_fill, color: CupertinoColors.destructiveRed);
    }
    if (user.role == 'admin') {
      return const Icon(CupertinoIcons.shield_lefthalf_fill, color: CupertinoColors.activeOrange);
    }
    return const Icon(CupertinoIcons.person_alt);
  }
}
