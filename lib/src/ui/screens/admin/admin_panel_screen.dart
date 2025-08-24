import 'package:smart_iraq/src/ui/widgets/cupertino_list_tile.dart';
import 'package:smart_iraq/src/ui/screens/admin/donation_methods_management_screen.dart';
import 'package:smart_iraq/src/ui/screens/admin/feature_management_screen.dart';
import 'package:smart_iraq/src/ui/screens/admin/managed_ads_management_screen.dart';
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
          Padding(
            padding: const EdgeInsets.only(left: 58.0),
            child: Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context)),
          ),
          CupertinoListTile(
            title: const Text('تمييز الإعلانات'),
            subtitle: const Text('اختيار إعلانات المستخدمين لعرضها بشكل مميز'),
            leading: const Icon(CupertinoIcons.star_fill),
            trailing: const Icon(CupertinoIcons.forward),
            onTap: () {
               Navigator.of(context).push(
                CupertinoPageRoute(builder: (context) => const FeatureManagementScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 58.0),
            child: Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context)),
          ),
          CupertinoListTile(
            title: const Text('إدارة طرق الدفع'),
            subtitle: const Text('التحكم بحسابات التبرع اليدوية'),
            leading: const Icon(CupertinoIcons.money_dollar_circle),
            trailing: const Icon(CupertinoIcons.forward),
            onTap: () {
               Navigator.of(context).push(
                CupertinoPageRoute(builder: (context) => const DonationMethodsManagementScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 58.0),
            child: Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context)),
          ),
          CupertinoListTile(
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
