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
import 'features/auth/welcome_screen.dart';
import 'features/pet_management/pet_dashboard_screen.dart';
import 'features/timeline/timeline_screen.dart';

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: authState.when(
        data: (state) {
          if (user != null) {
            return const HomeScreen();
          }

          final onboardingState = ref.watch(onboardingStateProvider);
          return onboardingState.when(
            data: (hasSeenOnboarding) {
              if (hasSeenOnboarding) {
                return const AuthScreen();
              }
              return const WelcomeScreen();
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => const AuthScreen(), // Fallback
          );
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
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_filled, 'Home'),
            _buildNavItem(1, Icons.history, 'Timeline'),
            _buildNavItem(2, Icons.calendar_month, 'Calendar'),
            _buildNavItem(3, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        if (index < _screens.length) {
          setState(() => _currentIndex = index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? theme.colorScheme.primary : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
