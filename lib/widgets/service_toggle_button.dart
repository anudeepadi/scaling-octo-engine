import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../providers/service_provider.dart';
import '../services/service_manager.dart';

class ServiceToggleButton extends StatelessWidget {
  const ServiceToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serviceProvider = Provider.of<ServiceProvider>(context);
    final isGemini = serviceProvider.currentService == MessagingService.gemini;
    final isCupertino = Platform.isIOS;

    // Simple icon button that shows a service indicator
    final icon = SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            isGemini 
              ? (isCupertino ? CupertinoIcons.sparkles : Icons.auto_awesome)
              : (isCupertino ? CupertinoIcons.chat_bubble : Icons.message_rounded),
            color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white,
            size: 22,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isGemini ? Colors.blue : Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).appBarTheme.backgroundColor ?? Colors.black,
                  width: 1,
                ),
              ),
              width: 8,
              height: 8,
            ),
          ),
        ],
      ),
    );
    
    // Use a simple tap handler to toggle for both platforms
    return GestureDetector(
      onTap: () {
        serviceProvider.toggleService();
      },
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }
}