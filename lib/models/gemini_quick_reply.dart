import 'package:flutter/material.dart';
import 'quick_reply.dart';

class GeminiQuickReply extends QuickReply {
  final bool isFromGemini;

  GeminiQuickReply({
    required String text,
    required String value,
    IconData? icon,
    this.isFromGemini = true,
  }) : super(
          text: text,
          value: value,
          icon: icon,
        );

  factory GeminiQuickReply.fromQuickReply(QuickReply quickReply, {bool isFromGemini = true}) {
    return GeminiQuickReply(
      text: quickReply.text,
      value: quickReply.value,
      icon: quickReply.icon,
      isFromGemini: isFromGemini,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeminiQuickReply &&
        other.text == text &&
        other.value == value;
  }

  @override
  int get hashCode => text.hashCode ^ value.hashCode;
}