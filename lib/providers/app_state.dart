// lib/providers/app_state.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../services/supabase_service.dart';

class AppState extends ChangeNotifier {
  final Set<int> _wishlist = {};
  bool isDarkMode = false;

  // ── Settings preferences ───────────────────────────────────────────────────
  bool notifListingUpdates   = true;  // notify on listing approval/rejection
  bool notifNewMessages      = true;  // notify on new chat messages
  bool notifEmailUpdates     = false; // email newsletter / promotions
  bool privacyShowProfile    = true;  // show profile publicly on listings

  void setSetting(String key, bool value) {
    switch (key) {
      case 'notifListingUpdates':   notifListingUpdates   = value;
      case 'notifNewMessages':      notifNewMessages      = value;
      case 'notifEmailUpdates':     notifEmailUpdates     = value;
      case 'privacyShowProfile':    privacyShowProfile    = value;
    }
    notifyListeners();
  }

  // ── Notifications ──────────────────────────────────────────────────────────
  List<AppNotification> _notifications = [];
  bool isLoadingNotifications = false;

  List<AppNotification> get allNotifications => _notifications;

  List<AppNotification> get notifications {
    return _notifications.where((n) {
      if (n.type == NotificationType.listingApproved ||
          n.type == NotificationType.listingRejected ||
          n.type == NotificationType.listingPending) {
        return notifListingUpdates;
      }
      if (n.type == NotificationType.newMessage) {
        return notifNewMessages;
      }
      return true;
    }).toList();
  }

  int get unreadNotificationCount => notifications.length;

  Future<void> _loadNotifications() async {
    if (!SupabaseService.isAuthenticated) return;
    isLoadingNotifications = true;
    notifyListeners();
    try {
      final fetched = await SupabaseService.fetchNotifications();
      _notifications = fetched;
    } catch (_) {
      _notifications = [];
    } finally {
      isLoadingNotifications = false;
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() => _loadNotifications();

  // ── Properties ────────────────────────────────────────────────────────────
  List<Property> _properties = [];
  bool isLoadingProperties = false;
  List<Property> get allProperties => _properties;

  // ── Agents ────────────────────────────────────────────────────────────────
  List<Agent> _agents = [];
  bool isLoadingAgents = false;
  List<Agent> get agents => _agents;

  // ── User Profile ──────────────────────────────────────────────────────────
  String fullName = 'Unknown User';
  String? avatarUrl;
  String email = '';
  String? phone; // Contact number — only relevant for verified agents

  // ── Verification ──────────────────────────────────────────────────────────
  bool isVerified = false;
  String? applicationStatus;
  String? applicationAdminNote;

  // ── Chat (Supabase-backed) ─────────────────────────────────────────────────
  List<ChatConversation> chatConversations = [];
  int get unreadCount => chatConversations.fold(0, (s, c) => s + c.unreadCount);

  AppState() {
    _loadProperties();
    _loadAgents();
    _loadProfile();
    _loadConversations();
    _loadNotifications();
  }

  // ── Profile loading ───────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      final data = await SupabaseService.fetchMyProfile();
      isVerified         = (data['is_verified'] as bool?) ?? false;
      applicationStatus  = data['application_status'] as String?;
      applicationAdminNote = data['admin_note'] as String?;
      fullName           = data['full_name'] as String? ?? 'Unknown User';
      avatarUrl          = data['avatar_url'] as String?;
      email              = data['email'] as String? ?? '';
      phone              = data['phone'] as String?;
      notifyListeners();
    } catch (_) {
      // Silently ignore — user may not be authenticated yet
    }
  }

  /// Call after submitting an application or when the app resumes.
  Future<void> refreshProfile() => _loadProfile();

  /// Edit / update user profile.
  Future<void> updateUserProfile({required String name, File? imageFile, String? phone}) async {
    String? newAvatarUrl;
    if (imageFile != null) {
      newAvatarUrl = await SupabaseService.uploadAvatar(imageFile);
    }
    await SupabaseService.updateProfile(fullName: name, avatarUrl: newAvatarUrl, phone: phone);
    await _loadProfile();
  }


  // ── Properties ────────────────────────────────────────────────────────────

  Future<void> _loadProperties() async {
    isLoadingProperties = true;
    notifyListeners();
    try {
      final fetched = await SupabaseService.fetchProperties();
      _properties = fetched;
    } catch (e) {
      _properties = [];
    } finally {
      isLoadingProperties = false;
      notifyListeners();
    }
  }

  Future<void> refreshProperties() => _loadProperties();

  // ── Agents ────────────────────────────────────────────────────────────────

  Future<void> _loadAgents() async {
    isLoadingAgents = true;
    notifyListeners();
    try {
      final fetched = await SupabaseService.fetchVerifiedAgents();
      _agents = fetched;
    } catch (_) {
      _agents = [];
    } finally {
      isLoadingAgents = false;
      notifyListeners();
    }
  }

  Future<void> refreshAgents() => _loadAgents();

  // ── Dark mode ─────────────────────────────────────────────────────────────

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  // ── Wishlist ──────────────────────────────────────────────────────────────

  bool isWishlisted(int id) => _wishlist.contains(id);

  void toggleWishlist(int id) {
    if (_wishlist.contains(id)) {
      _wishlist.remove(id);
    } else {
      _wishlist.add(id);
    }
    notifyListeners();
  }

  List<Property> get wishlisted =>
      _properties.where((p) => _wishlist.contains(p.id)).toList();

  int get wishlistCount => _wishlist.length;

  // ── Conversations ─────────────────────────────────────────────────────────

  Future<void> _loadConversations() async {
    try {
      final convs = await SupabaseService.fetchConversations();
      chatConversations = convs;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refreshConversations() => _loadConversations();

  void markRead(int convId) {
    final c = chatConversations.firstWhere((c) => c.id == convId);
    c.unreadCount = 0;
    notifyListeners();
  }
}

