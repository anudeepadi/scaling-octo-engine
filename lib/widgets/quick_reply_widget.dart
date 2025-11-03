import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import '../models/quick_reply.dart';
import '../services/quick_reply_state_service.dart';
import '../theme/app_theme.dart';

class QuickReplyWidget extends StatefulWidget {
  final List<QuickReply> quickReplies;
  final Function(QuickReply) onReplySelected;
  final String? messageId;

  const QuickReplyWidget({
    super.key,
    required this.quickReplies,
    required this.onReplySelected,
    this.messageId,
  });

  @override
  State<QuickReplyWidget> createState() => _QuickReplyWidgetState();
}

class _QuickReplyWidgetState extends State<QuickReplyWidget> {
  final QuickReplyStateService _quickReplyService = QuickReplyStateService();

  void _showAlreadySelectedDialog() {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('Option Already Selected'),
            content: const Text('You have already selected an option for this question and cannot select another one.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Option Already Selected'),
            content: const Text('You have already selected an option for this question and cannot select another one.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _handleQuickReplyTap(QuickReply reply) {
    if (widget.messageId == null) {
      widget.onReplySelected(reply);
      return;
    }

    if (_quickReplyService.isMessageSetDisabled(widget.messageId!)) {
      _showAlreadySelectedDialog();
      return;
    }

    _quickReplyService.selectQuickReply(widget.messageId!, reply.value);

    setState(() {});

    widget.onReplySelected(reply);
  }

  String _formatTimeDisplay(String text) {
    RegExp timeRegex = RegExp(r'^\d{3,4}$');
    if (timeRegex.hasMatch(text)) {
      if (text.length == 3) {
        return '${text[0]}:${text.substring(1)}';
      } else if (text.length == 4) {
        return '${text.substring(0, 2)}:${text.substring(2)}';
      }
    }
    return text;
  }

  List<QuickReply> _getSortedQuickReplies() {
    List<QuickReply> sortedReplies = List.from(widget.quickReplies);

    sortedReplies.sort((a, b) {
      int getNumericValue(String text) {
        if (text.contains('-')) {
          String firstNumber = text.split('-')[0].trim();
          return int.tryParse(firstNumber) ?? 0;
        }

        if (text.toLowerCase().contains('or more')) {
          String numberPart = text.replaceAll(RegExp(r'[^0-9]'), '');
          return int.tryParse(numberPart) ?? 999;
        }

        RegExp numRegex = RegExp(r'\d+');
        Match? match = numRegex.firstMatch(text);
        return match != null ? int.parse(match.group(0)!) : 0;
      }

      return getNumericValue(a.text).compareTo(getNumericValue(b.text));
    });

    return sortedReplies;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quickReplies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: _getSortedQuickReplies().map((reply) {
              final bool isSelected = widget.messageId != null &&
                  _quickReplyService.isQuickReplySelected(widget.messageId!, reply.value);
              final bool isDisabled = widget.messageId != null &&
                  _quickReplyService.isOptionDisabled(widget.messageId!, reply.value);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildModernQuickReply(reply, isSelected, isDisabled),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernQuickReply(QuickReply reply, bool isSelected, bool isDisabled) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: (isDisabled || isSelected) ? null : () {
            HapticFeedback.lightImpact();
            _handleQuickReplyTap(reply);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: AppTheme.wellnessGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppTheme.borderLight,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.wellnessGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppTheme.shadowSubtle,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatTimeDisplay(reply.text),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      letterSpacing: -0.25,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: Colors.white,
                  )
                else
                  Icon(
                    Icons.circle_outlined,
                    size: 20,
                    color: AppTheme.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
