import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/profile_model.dart';
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
      // NOTE: This assumes a boolean column named `is_banned` exists in the `profiles` table.
      await _supabase.from('profiles').update({'is_banned': isBanned}).eq('id', userId);
       _showSuccessSnackBar(isBanned ? 'تم حظر المستخدم بنجاح.' : 'تم رفع الحظر عن المستخدم بنجاح.');
      _refreshUsers();
    } catch (e) {
      _showErrorSnackBar('خطأ في تحديث حالة الحظر: $e. تأكد من وجود عمود is_banned في الجدول.');
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
              return CupertinoListTile(
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

class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CupertinoListTile({super.key, required this.title, this.subtitle, this.leading, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: onTap != null ? CupertinoTheme.of(context).barBackgroundColor : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: CupertinoTheme.of(context).textTheme.textStyle,
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle(
                      style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle,
                      child: subtitle!,
                    ),
                  ]
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ]
          ],
        ),
      ),
    );
  }
}
