import 'package:flutter/material.dart';

class AppBanner {
  final String id;
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final bool isActive;

  AppBanner({
    required this.id,
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.isActive,
  });

  factory AppBanner.fromJson(Map<String, dynamic> json) {
    return AppBanner(
      id: json['id'],
      message: json['message'],
      backgroundColor: _colorFromHex(json['background_color']),
      textColor: _colorFromHex(json['text_color']),
      isActive: json['is_active'],
    );
  }

  static Color _colorFromHex(String hexColor) {
    try {
      final hexCode = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return Colors.blue; // Default color on error
    }
  }
}
