import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_iraq/src/core/theme/app_theme.dart';

class CreateRfqScreen extends StatefulWidget {
  const CreateRfqScreen({super.key});

  @override
  State<CreateRfqScreen> createState() => _CreateRfqScreenState();
}

class _CreateRfqScreenState extends State<CreateRfqScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitRfq() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final supabase = Provider.of<SupabaseClient>(context, listen: false);
      await supabase.from('rfqs').insert({
        'product_description': _descriptionController.text.trim(),
        'quantity': _quantityController.text.trim(),
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (error) {
      if (mounted) {
        _showErrorDialog('حدث خطأ أثناء إرسال طلبك: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('تم بنجاح'),
        content: const Text('تم إرسال طلب عرض السعر الخاص بك. سيتمكن التجار الآن من رؤيته وتقديم عروضهم.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('موافق'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pop(); // Go back from RFQ screen
            },
          )
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [CupertinoDialogAction(isDefaultAction: true, child: const Text('موافق'), onPressed: () => Navigator.of(context).pop())],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('إنشاء طلب عرض سعر'),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('وصف المنتج المطلوب', style: theme.textTheme.navTitleTextStyle),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _descriptionController,
                placeholder: 'مثال: هاتف آيفون 15 برو، 256 جيجا، لون أزرق',
                maxLines: 5,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 24),
              Text('الكمية المطلوبة', style: theme.textTheme.navTitleTextStyle),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _quantityController,
                placeholder: 'مثال: 100 قطعة أو 10 كراتين',
                 padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : CupertinoButton.filled(
                      onPressed: _submitRfq,
                      child: Text('إرسال الطلب', style: theme.textTheme.textStyle.copyWith(fontWeight: FontWeight.bold, color: AppTheme.charcoalBackground)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
