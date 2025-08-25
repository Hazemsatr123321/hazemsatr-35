import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/payment_method_model.dart';
import 'package:smart_iraq/src/ui/screens/admin/add_edit_payment_method_screen.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentMethodsManagementScreen extends StatefulWidget {
  const PaymentMethodsManagementScreen({Key? key}) : super(key: key);

  @override
  _PaymentMethodsManagementScreenState createState() => _PaymentMethodsManagementScreenState();
}

class _PaymentMethodsManagementScreenState extends State<PaymentMethodsManagementScreen> {
  late Future<List<PaymentMethod>> _methodsFuture;
  late final SupabaseClient _supabase;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _methodsFuture = _fetchPaymentMethods();
  }

  Future<List<PaymentMethod>> _fetchPaymentMethods() async {
    final response = await _supabase.from('payment_methods').select().order('created_at');
    return (response as List).map((json) => PaymentMethod.fromJson(json)).toList();
  }

  void _refresh() {
    setState(() {
      _methodsFuture = _fetchPaymentMethods();
    });
  }

  Future<void> _deleteMethod(int id) async {
    try {
      await _supabase.from('payment_methods').delete().eq('id', id);
      _refresh();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Manage Payment Methods'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () async {
            await Navigator.of(context).push(
              CupertinoPageRoute(builder: (context) => const AddEditPaymentMethodScreen()),
            );
            _refresh();
          },
        ),
      ),
      child: FutureBuilder<List<PaymentMethod>>(
        future: _methodsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoadingIndicator();
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No payment methods found.'));
          }
          final methods = snapshot.data!;
          return ListView.builder(
            itemCount: methods.length,
            itemBuilder: (context, index) {
              final method = methods[index];
              return CupertinoListTile(
                title: Text(method.methodName),
                subtitle: Text(method.accountDetails),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.delete, color: CupertinoColors.systemRed),
                  onPressed: () => _deleteMethod(method.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// A simple CupertinoListTile to make the code cleaner.
class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const CupertinoListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: CupertinoColors.separator.resolveFrom(context))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4.0),
                    subtitle!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16.0),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
