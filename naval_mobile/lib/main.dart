import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naval_mobile/counter.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return MaterialApp(
      theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
      home: Builder(
        builder: (context) => MyHomePage(
          onOpenThemePage: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyHome()),
            );
          },
        ),
      ),
    );
  }
}

class ThemeModel with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

class MyHome extends StatelessWidget {
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App State Example'),
        actions: [
          Switch(
            value: themeModel.isDark,
            onChanged: (_) => themeModel.toggleTheme(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Toggle the theme using the switch in the app bar.'),
      ),
    );
  }
}
