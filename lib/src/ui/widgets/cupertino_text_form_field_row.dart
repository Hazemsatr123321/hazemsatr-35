import 'package:flutter/cupertino.dart';

class CupertinoTextFormFieldRow extends StatelessWidget {
  final TextEditingController controller;
  final String? placeholder;
  final Widget? prefix;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final EdgeInsets? padding;
  final BoxDecoration? decoration;
  final void Function(String)? onChanged;

  const CupertinoTextFormFieldRow({
    Key? key,
    required this.controller,
    this.placeholder,
    this.prefix,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.padding,
    this.decoration,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoFormRow(
              prefix: prefix ?? const SizedBox.shrink(),
              child: CupertinoTextField(
                controller: controller,
                placeholder: placeholder,
                keyboardType: keyboardType,
                obscureText: obscureText,
                padding: padding ?? const EdgeInsets.all(16.0),
                decoration: decoration,
                onChanged: (text) {
                  field.didChange(text);
                  if (onChanged != null) {
                    onChanged!(text);
                  }
                },
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
