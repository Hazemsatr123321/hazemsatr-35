import 'package:flutter/material.dart';

class CharityScreen extends StatelessWidget {
  const CharityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('دعم القضايا الخيرية'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.volunteer_activism,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24.0),
              Text(
                'التزامنا بالمجتمع',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              Text(
                'في "العراق الذكي"، نؤمن بأهمية رد الجميل لمجتمعنا. نحن ملتزمون بتخصيص جزء من مواردنا لدعم القضايا الإنسانية والخيرية في العراق.',
                style: textTheme.bodyLarge?.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              const Divider(),
              const SizedBox(height: 24.0),
              Text(
                'دعم المشاريع الصغيرة',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                'نقدم ميزة تمييز الإعلانات بشكل مجاني لمدة أسبوع لدعم المشاريع الصغيرة والأسر المنتجة، لمساعدتهم على النمو والوصول إلى المزيد من الزبائن.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              Text(
                'دعم مرضى السرطان والفقراء',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                'نعمل على بناء شراكات مع مؤسسات خيرية موثوقة لتوجيه الدعم المادي والمعنوي للمحتاجين من الفقراء ومرضى السرطان. سيتم الإعلان عن تفاصيل هذه المبادرات قريبًا.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
