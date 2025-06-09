import 'package:flutter/material.dart';

/// Gemini-specific quick reply model that extends the basic QuickReply functionality
/// with additional properties for AI-generated responses
class GeminiQuickReply {
  final String text;
  final String value;
  final IconData? icon;
  final String? description;
  final double? confidence;
  final String? category;

  GeminiQuickReply({
    required this.text,
    required this.value,
    this.icon,
    this.description,
    this.confidence,
    this.category,
  });

  factory GeminiQuickReply.fromJson(Map<String, dynamic> json) {
    return GeminiQuickReply(
      text: json['text'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      confidence: json['confidence'] as double?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'value': value,
      if (description != null) 'description': description,
      if (confidence != null) 'confidence': confidence,
      if (category != null) 'category': category,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeminiQuickReply &&
        other.text == text &&
        other.value == value &&
        other.description == description &&
        other.confidence == confidence &&
        other.category == category;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        value.hashCode ^
        description.hashCode ^
        confidence.hashCode ^
        category.hashCode;
  }

  @override
  String toString() {
    return 'GeminiQuickReply(text: $text, value: $value, description: $description, confidence: $confidence, category: $category)';
  }
}