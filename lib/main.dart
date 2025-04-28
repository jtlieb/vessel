import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vessel/screens/epub_test_screen.dart';
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

class _MainTabScreenState extends State<MainTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Book Reader'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: 'Reader'),
            Tab(icon: Icon(Icons.science), text: 'EPUB Test'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [BookReader(), EpubTestScreen()],
      ),
    );
  }
}
