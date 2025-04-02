import 'package:flutter/material.dart';

class QuickReply {
  final String text;
  final String value;
  final IconData? icon;

  QuickReply({
    required this.text,
    required this.value,
    this.icon,
  });

  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      text: json['text'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'value': value,
    };
  }
}