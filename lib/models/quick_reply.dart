import 'package:flutter/material.dart';
import '../services/emoji_converter_service.dart';

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
      text: EmojiConverterService.convertTextToEmoji(json['text'] as String),
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