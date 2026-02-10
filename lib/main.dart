import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/server_provider.dart';
import 'screens/server_list_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Prefer dark status bar icons on iOS
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const OutlineManagerApp());
}

class OutlineManagerApp extends StatelessWidget {
  const OutlineManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ServerProvider()),
      ],
      child: MaterialApp(
        title: 'Outline Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ServerListScreen(),
      ),
    );
  }
}
