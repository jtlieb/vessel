import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/book_reader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Make navigation bar transparent with light icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  runApp(const VesselApp());
}

class VesselApp extends StatelessWidget {
  const VesselApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vessel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        // Add transparent navigation bar to the theme
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.transparent.withAlpha(25),
          indicatorColor: Colors.deepPurple.withAlpha(50),
        ),
      ),
      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[const BookReader()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _widgetOptions.elementAt(_selectedIndex));
  }
}
