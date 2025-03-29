import 'package:flutter/material.dart';
import 'dart:async';

class TypingIndicator extends StatefulWidget {
  final Color color;
  final double size;
  
  const TypingIndicator({
    Key? key, 
    this.color = Colors.grey,
    this.size = 8.0,
  }) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late List<Timer> _timers;
  List<double> _opacities = [];
  final int _dotsCount = 3;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize opacities for each dot
    _opacities = List.generate(_dotsCount, (_) => 0.4);
    
    // Create a timer for each dot to animate it
    _timers = List.generate(_dotsCount, (index) {
      return Timer.periodic(
        Duration(milliseconds: 150 * (index + 1)),
        (_) {
          if (mounted) {
            setState(() {
              _opacities[index] = _opacities[index] == 1.0 ? 0.4 : 1.0;
            });
          }
        },
      );
    });
  }
  
  @override
  void dispose() {
    // Dispose all timers
    for (var timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display each dot with its own opacity
          ...List.generate(_dotsCount, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: widget.size,
              width: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(_opacities[index]),
                shape: BoxShape.circle,
              ),
            );
          }),
        ],
      ),
    );
  }
}
