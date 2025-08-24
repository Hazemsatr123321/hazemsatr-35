import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_iraq/src/ui/screens/admin/user_management_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('لوحة تحكم المدير'),
      ),
      child: ListView(
        children: [
          const SizedBox(height: 20),
          CupertinoListTile(
            title: const Text('إدارة المستخدمين'),
            subtitle: const Text('الموافقة على حسابات التجار والتحكم بها'),
            leading: const Icon(CupertinoIcons.group_solid),
            trailing: const Icon(CupertinoIcons.forward),
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (context) => const UserManagementScreen()),
              );
            },
          ),
          // Add more admin options here in the future
        ],
      ),
    );
  }
}
