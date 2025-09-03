import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quick_reply.dart';
import '../theme/app_theme.dart';

class ModernQuickReplyWidget extends StatefulWidget {
  final List<QuickReply> quickReplies;
  final Function(QuickReply) onReplySelected;
  final bool enabled;

  const ModernQuickReplyWidget({
    super.key,
    required this.quickReplies,
    required this.onReplySelected,
    this.enabled = true,
  });

  @override
  State<ModernQuickReplyWidget> createState() => _ModernQuickReplyWidgetState();
}

class _ModernQuickReplyWidgetState extends State<ModernQuickReplyWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      widget.quickReplies.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    _slideAnimations = _animationControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();
  }

  void _startStaggeredAnimations() {
    for (int i = 0; i < _animationControllers.length; i++) {
      Future.delayed(
        Duration(milliseconds: i * 100),
        () {
          if (mounted) {
            _animationControllers[i].forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
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
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.quitxtTeal, AppTheme.quitxtPurple],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Replies',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Quick reply buttons
          _buildQuickReplyGrid(),
        ],
      ),
    );
  }

  Widget _buildQuickReplyGrid() {
    // For better layout, we'll use a wrap widget
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.quickReplies.asMap().entries.map((entry) {
        final index = entry.key;
        final reply = entry.value;
        
        return AnimatedBuilder(
          animation: _animationControllers[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[index].value,
              child: SlideTransition(
                position: _slideAnimations[index],
                child: _buildQuickReplyButton(reply, index),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildQuickReplyButton(QuickReply reply, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.enabled ? () => _handleReplyTap(reply) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.quitxtTeal.withValues(alpha: 0.1),
                AppTheme.quitxtPurple.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.quitxtTeal.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.quitxtTeal.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reply.icon != null) ...[
                Icon(
                  reply.icon,
                  size: 16,
                  color: AppTheme.quitxtTeal,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  reply.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.quitxtTeal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleReplyTap(QuickReply reply) {
    if (!widget.enabled) return;
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Scale animation on tap
    final index = widget.quickReplies.indexOf(reply);
    if (index >= 0) {
      _animationControllers[index].reverse().then((_) {
        if (mounted) {
          _animationControllers[index].forward();
        }
      });
    }
    
    // Call the callback
    widget.onReplySelected(reply);
  }
}

// Enhanced Quick Reply Widget for specific use cases
class ModernPollQuickReply extends StatefulWidget {
  final List<QuickReply> options;
  final Function(QuickReply) onOptionSelected;
  final String? selectedValue;
  final String title;
  final bool allowMultipleSelection;

  const ModernPollQuickReply({
    super.key,
    required this.options,
    required this.onOptionSelected,
    this.selectedValue,
    this.title = 'Choose an option:',
    this.allowMultipleSelection = false,
  });

  @override
  State<ModernPollQuickReply> createState() => _ModernPollQuickReplyState();
}

class _ModernPollQuickReplyState extends State<ModernPollQuickReply> {
  Set<String> selectedValues = {};

  @override
  void initState() {
    super.initState();
    if (widget.selectedValue != null) {
      selectedValues.add(widget.selectedValue!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.poll,
                size: 20,
                color: AppTheme.quitxtTeal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Options
          ...widget.options.map((option) => _buildPollOption(option)),
        ],
      ),
    );
  }

  Widget _buildPollOption(QuickReply option) {
    final isSelected = selectedValues.contains(option.value);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleOptionTap(option),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.quitxtTeal.withValues(alpha: 0.1)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? AppTheme.quitxtTeal 
                    : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.quitxtTeal : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppTheme.quitxtTeal : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppTheme.quitxtTeal : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleOptionTap(QuickReply option) {
    HapticFeedback.selectionClick();
    
    setState(() {
      if (widget.allowMultipleSelection) {
        if (selectedValues.contains(option.value)) {
          selectedValues.remove(option.value);
        } else {
          selectedValues.add(option.value);
        }
      } else {
        selectedValues.clear();
        selectedValues.add(option.value);
      }
    });
    
    widget.onOptionSelected(option);
  }
}