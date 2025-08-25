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
                leading: Icon(
                  user.role == 'admin' ? CupertinoIcons.shield_lefthalf_fill : CupertinoIcons.person_alt,
                  color: user.role == 'admin' ? CupertinoColors.activeOrange : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// A basic CupertinoListTile for this screen since the custom one was causing issues.
class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;

  const CupertinoListTile({super.key, required this.title, this.subtitle, this.leading});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        ],
      ),
    );
  }
}
