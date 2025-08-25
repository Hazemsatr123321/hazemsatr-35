import 'package:flutter/cupertino.dart';
import 'package:smart_iraq/src/ui/screens/admin/payment_methods_management_screen.dart';
import 'package:smart_iraq/src/ui/widgets/cupertino_list_tile.dart' as custom;
import 'package:smart_iraq/src/ui/screens/admin/feature_requests_screen.dart';
import 'package:smart_iraq/src/ui/screens/admin/managed_ads_management_screen.dart';
import 'package:smart_iraq/src/ui/screens/admin/user_management_screen.dart';
import 'package:smart_iraq/src/ui/screens/admin/product_management_screen.dart';

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
          custom.CupertinoListTile(
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
          const _Divider(),
          custom.CupertinoListTile(
            title: const Text('إدارة كل الإعلانات'),
            subtitle: const Text('عرض وحذف إعلانات المستخدمين'),
            leading: const Icon(CupertinoIcons.cube_box_fill),
            trailing: const Icon(CupertinoIcons.forward),
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (context) => const ProductManagementScreen()),
              );
            },
          ),
          const _Divider(),
          custom.CupertinoListTile(
            title: const Text('طلبات تمييز الإعلانات'),
            subtitle: const Text('مراجعة طلبات المستخدمين والموافقة عليها'),
            leading: const Icon(CupertinoIcons.star_circle),
            trailing: const Icon(CupertinoIcons.forward),
            onTap: () {
               Navigator.of(context).push(
                CupertinoPageRoute(builder: (context) => const FeatureRequestsScreen()),
              );
            },
          ),
          const _Divider(),
          custom.CupertinoListTile(
            title: const Text('إدارة طرق الدفع'),
            subtitle: const Text('التحكم بحسابات تمييز الإعلانات والتبرعات'),
            leading: const Icon(CupertinoIcons.money_dollar_circle),
            trailing: const Icon(CupertinoIcons.forward),
            onTap: () {
               Navigator.of(context).push(
                CupertinoPageRoute(builder: (context) => const PaymentMethodsManagementScreen()),
              );
            },
          ),
          const _Divider(),
          custom.CupertinoListTile(
            title: const Text('إدارة الإعلانات المدارة'),
            subtitle: const Text('التحكم بالإعلانات التي تظهر في الصفحة الرئيسية'),
            leading: const Icon(CupertinoIcons.rectangle_on_rectangle_angled),
            trailing: const Icon(CupertinoIcons.forward),
            onTap: () {
               Navigator.of(context).push(
                CupertinoPageRoute(builder: (context) => const ManagedAdsManagementScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 58.0),
      child: Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context)),
    );
  }
}
