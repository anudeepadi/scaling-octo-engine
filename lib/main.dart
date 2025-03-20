import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'providers/chat_provider.dart';
import 'providers/bot_chat_provider.dart';
import 'providers/channel_provider.dart';
import 'providers/system_chat_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/ios_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => BotChatProvider()),
        ChangeNotifierProvider(create: (_) => ChannelProvider()),
        ChangeNotifierProvider(create: (_) => SystemChatProvider()),
      ],
      child: Platform.isIOS
          ? MaterialApp(
              title: 'RCS Demo App',
              debugShowCheckedModeBanner: false,
              theme: IosTheme.lightTheme,
              darkTheme: IosTheme.darkTheme,
              themeMode: ThemeMode.system,
              home: const HomeScreen(),
            )
          : MaterialApp(
              title: 'RCS Demo App',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.system,
              home: const HomeScreen(),
            ),
    );
  }
}