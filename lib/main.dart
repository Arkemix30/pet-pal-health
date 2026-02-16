import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:isar/isar.dart';
import 'data/local/isar_service.dart';

import 'package:google_fonts/google_fonts.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/auth_service.dart';
import 'features/pet_management/pet_dashboard_screen.dart';
import 'features/timeline/timeline_screen.dart';

import 'core/services/notification_service.dart';

final logger = Logger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final Isar isar;
  final notificationService = NotificationService();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    // Initialize Isar local database
    isar = await IsarService.init();

    // Initialize Notifications
    await notificationService.init();
  } catch (e) {
    logger.e('Error during initialization: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const PetCareApp(),
    ),
  );
}

class PetCareApp extends ConsumerWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = ref.watch(userProvider);

    return MaterialApp(
      title: 'Pet Pal Health',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D6A4F),
          primary: const Color(0xFF2D6A4F),
          secondary: const Color(0xFF74C69D),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      home: authState.when(
        data: (state) {
          if (user != null) {
            return const HomeScreen();
          }
          return const AuthScreen();
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PetDashboardScreen(),
    const TimelineScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'My Pet Family' : 'Health Timeline',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authServiceProvider).signOut(),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Timeline',
            ),
          ],
        ),
      ),
    );
  }
}
