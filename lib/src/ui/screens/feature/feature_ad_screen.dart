import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:smart_iraq/src/models/payment_method_model.dart';
import 'package:smart_iraq/src/models/product_model.dart';
import 'package:smart_iraq/src/ui/widgets/custom_loading_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureAdScreen extends StatefulWidget {
  final Product product;
  const FeatureAdScreen({Key? key, required this.product}) : super(key: key);

  @override
  _FeatureAdScreenState createState() => _FeatureAdScreenState();
}

class _FeatureAdScreenState extends State<FeatureAdScreen> {
  late Future<List<PaymentMethod>> _methodsFuture;
  final _transactionRefController = TextEditingController();
  PaymentMethod? _selectedMethod;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _methodsFuture = _fetchPaymentMethods();
  }

  Future<List<PaymentMethod>> _fetchPaymentMethods() async {
    final response = await Supabase.instance.client.from('payment_methods').select().eq('is_active', true);
    return (response as List).map((json) => PaymentMethod.fromJson(json)).toList();
  }

  Future<void> _submitRequest() async {
    if (_selectedMethod == null) {
      // Show error: please select a method
      return;
    }
    if (_transactionRefController.text.isEmpty) {
      // Show error: please enter a transaction reference
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('feature_requests').insert({
        'user_id': widget.product.userId,
        'product_id': widget.product.id,
        'payment_method_id': _selectedMethod!.id,
        'transaction_ref': _transactionRefController.text,
      });
      Navigator.of(context).pop();
      // Optionally show a success message
    } catch (e) {
      // Handle error, e.g., show a dialog
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Feature Your Ad'),
      ),
      child: SafeArea(
        child: FutureBuilder<List<PaymentMethod>>(
          future: _methodsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CustomLoadingIndicator();
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No payment methods are available right now.'));
            }
            final methods = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text('Feature: ${widget.product.name}', style: CupertinoTheme.of(context).textTheme.navTitleTextStyle),
                const SizedBox(height: 20),
                const Text('1. Choose a payment method and send the feature fee.'),
                const SizedBox(height: 10),
                ...methods.map((method) => RadioListTile<PaymentMethod>(
                      title: Text(method.methodName),
                      subtitle: Text('${method.accountDetails}\n${method.instructions ?? ''}'),
                      value: method,
                      groupValue: _selectedMethod,
                      onChanged: (value) => setState(() => _selectedMethod = value),
                    )),
                const SizedBox(height: 20),
                const Text('2. Enter the transaction reference ID below.'),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: _transactionRefController,
                  placeholder: 'e.g., Transaction ID, Reference Number',
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : CupertinoButton.filled(
                        onPressed: _submitRequest,
                        child: const Text('Submit for Review'),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
