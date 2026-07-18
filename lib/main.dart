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
/// - If signed out → LoginScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.authStateChanges,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Still waiting — return blank (splash is on top anyway)
          return const Scaffold(body: SizedBox.shrink());
        }
        final session = snapshot.data!.session;
        if (session != null) return const MainShell();
        return const LoginScreen();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: AppDrawer(
        currentIndex: _index,
        onNavigate: (i) => setState(() => _index = i),
      ),
      body: IndexedStack(index: _index, children: _pages),
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
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _index = i),
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
                                  child: Icon(
                                    active ? item.activeIcon : item.icon,
                                    size: 22,
                                    color: active ? AppColors.primary : AppColors.textLight,
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
                              color: active ? AppColors.primary : AppColors.textLight)),
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
}

class _NavDef {
  final IconData icon, activeIcon;
  final String label;
  const _NavDef({required this.icon, required this.activeIcon, required this.label});
}
