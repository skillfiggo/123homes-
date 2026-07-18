// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/maps_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/app_drawer.dart';

// Tab index constants – import this from any screen
class TabIndex {
  static const home     = 0;
  static const maps     = 1;
  static const wishlist = 2;
  static const messages = 3;
  static const profile  = 4;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const Homes123App()),
  );
}

class Homes123App extends StatelessWidget {
  const Homes123App({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (_, state, __) => MaterialApp(
        title: '123Homes',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SplashGate(),
      ),
    );
  }
}

/// Shows the animated splash first, then hands off to [AuthGate].
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (_splashDone) return const AuthGate();

    return Stack(children: [
      const AuthGate(),            // loads in background
      if (!_splashDone)
        SplashScreen(key: const ValueKey('splash')),
    ]);
  }

  @override
  void initState() {
    super.initState();
    // Total splash duration: ~3 s (sequence ends + exit = ~2.9 s total)
    Future.delayed(const Duration(milliseconds: 3100), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }
}

/// Listens to the Supabase auth stream and routes accordingly:
/// - If signed in  → MainShell
/// - If guest mode → MainShell (limited access)
/// - If signed out → LoginScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        // Guest mode bypasses auth check
        if (appState.isGuest) return const MainShell();

        return StreamBuilder<AuthState>(
          stream: SupabaseService.authStateChanges,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(body: SizedBox.shrink());
            }
            final session = snapshot.data!.session;
            if (session != null) return const MainShell();
            return const LoginScreen();
          },
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Call this from any descendant to open the nav drawer.
  static void openDrawer(BuildContext context) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    state?._scaffoldKey.currentState?.openDrawer();
  }

  /// Switch to any tab by index.
  static void goToTab(BuildContext context, int tabIndex) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    if (state == null) return;
    // ignore: invalid_use_of_protected_member
    state.setState(() => state._index = tabIndex);
  }

  /// Switch to the Messages tab. If [convId] is provided, immediately opens
  /// that chat conversation on top of the messages list.
  static void goToMessages(BuildContext context, {int? convId}) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    if (state == null) return;
    // ignore: invalid_use_of_protected_member
    state.setState(() => state._index = TabIndex.messages);
    if (convId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          state.context,
          MaterialPageRoute(builder: (_) => ChatScreen(convId: convId, agentIndex: 0)),
        );
      });
    }
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _pages = [
    HomeScreen(),
    MapsScreen(),
    WishlistScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  static const _navItems = [
    _NavDef(icon: Icons.home_outlined,              activeIcon: Icons.home_rounded,              label: 'Home'),
    _NavDef(icon: Icons.map_outlined,               activeIcon: Icons.map_rounded,               label: 'Maps'),
    _NavDef(icon: Icons.favorite_border_rounded,    activeIcon: Icons.favorite_rounded,          label: 'Wishlist'),
    _NavDef(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded,      label: 'Messages'),
    _NavDef(icon: Icons.person_outline_rounded,     activeIcon: Icons.person_rounded,            label: 'Profile'),
  ];

  // Tabs accessible to guests
  static const _guestAllowedTabs = {0, 1}; // Home, Maps

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: AppDrawer(
        currentIndex: _index,
        onNavigate: (i) => setState(() => _index = i),
      ),
      body: Column(
        children: [
          if (appState.isGuest) const _GuestBanner(),
          Expanded(child: IndexedStack(index: _index, children: _pages)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  children: List.generate(_navItems.length, (i) {
                    final item = _navItems[i];
                    final active = _index == i;
                    final badge = (i == 3) ? state.unreadCount : (i == 2) ? state.wishlistCount : 0;
                    final isLocked = state.isGuest && !_guestAllowedTabs.contains(i);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (isLocked) {
                            _showGuestPrompt(context, i);
                          } else {
                            setState(() => _index = i);
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 42, height: 38,
                                  decoration: BoxDecoration(
                                    color: active ? const Color(0xFFEFF6FF) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        active ? item.activeIcon : item.icon,
                                        size: 22,
                                        color: isLocked
                                            ? AppColors.textLight.withValues(alpha: 0.45)
                                            : active ? AppColors.primary : AppColors.textLight,
                                      ),
                                    ],
                                  ),
                                ),
                                if (badge > 0)
                                  Positioned(
                                    top: -4, right: -4,
                                    child: Container(
                                      width: 16, height: 16,
                                      decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2)),
                                      child: Center(child: Text('$badge', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(item.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              color: isLocked
                                  ? AppColors.textLight.withValues(alpha: 0.45)
                                  : active ? AppColors.primary : AppColors.textLight)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGuestPrompt(BuildContext context, int tabIndex) {
    final labels = ['Home', 'Maps', 'Wishlist', 'Messages', 'Profile'];
    final icons  = [Icons.home_rounded, Icons.map_rounded, Icons.favorite_rounded,
                    Icons.chat_bubble_rounded, Icons.person_rounded];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GuestPromptSheet(
        featureLabel: labels[tabIndex],
        featureIcon: icons[tabIndex],
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text("Guest Mode: Sign in to unlock all features", 
            style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _GuestPromptSheet extends StatelessWidget {
  final String featureLabel;
  final IconData featureIcon;
  const _GuestPromptSheet({required this.featureLabel, required this.featureIcon});

  static const _benefits = [
    '🏠  Save properties to your Wishlist',
    '💬  Chat directly with verified agents',
    '📋  Track your listing applications',
    '🔔  Get real-time listing notifications',
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 16, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(featureIcon, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Unlock $featureLabel',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in or create a free account to access $featureLabel and much more.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 20),

          // Benefits list
          ...(_benefits.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(b, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
              ],
            ),
          ))),
          const SizedBox(height: 24),

          // Sign In button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                appState.exitGuestMode();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),

          // Create Account button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                appState.exitGuestMode();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1D4ED8),
                side: const BorderSide(color: Color(0xFF1D4ED8), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavDef {
  final IconData icon, activeIcon;
  final String label;
  const _NavDef({required this.icon, required this.activeIcon, required this.label});
}
