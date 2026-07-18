// lib/services/supabase_service.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property.dart';
import '../utils/image_helper.dart';

class SupabaseService {
  static final _sb = Supabase.instance.client;

  // Local helper to geocode property location strings to Nigerian coordinates with title-based jitter
  static MapEntry<double, double> _geocode(String location, {String seed = ''}) {
    final loc = location.toLowerCase().trim();
    double baseLat = 6.4550;
    double baseLng = 3.4350;
    
    if (loc.contains('abuja') || loc.contains('garki') || loc.contains('wuse') || loc.contains('maitama') || loc.contains('gwarinpa')) {
      baseLat = 9.05785; baseLng = 7.49508;
    } else if (loc.contains('ibadan')) {
      baseLat = 7.3775; baseLng = 3.9470;
    } else if (loc.contains('port harcourt') || loc.contains('ph')) {
      baseLat = 4.8156; baseLng = 7.0498;
    } else if (loc.contains('kano')) {
      baseLat = 12.0022; baseLng = 8.5919;
    } else if (loc.contains('enugu')) {
      baseLat = 6.4483; baseLng = 7.5139;
    } else if (loc.contains('ikeja') || loc.contains('maryland') || loc.contains('ogba') || loc.contains('magodo') || loc.contains('gbagada')) {
      baseLat = 6.6018; baseLng = 3.3515;
    } else if (loc.contains('vi') || loc.contains('victoria island') || loc.contains('oniru')) {
      baseLat = 6.4280; baseLng = 3.4219;
    } else if (loc.contains('ikoyi') || loc.contains('banana island')) {
      baseLat = 6.4549; baseLng = 3.4246;
    } else if (loc.contains('lekki') || loc.contains('ajah') || loc.contains('chevron') || loc.contains('sangotedo')) {
      baseLat = 6.4281; baseLng = 3.4219;
    } else if (loc.contains('surulere') || loc.contains('yaba') || loc.contains('ebute metta')) {
      baseLat = 6.5000; baseLng = 3.3667;
    }

    if (seed.isNotEmpty) {
      final int hash = seed.hashCode;
      final double latJitter = ((hash % 100) - 50) * 0.0001;
      final double lngJitter = (((hash ~/ 100) % 100) - 50) * 0.0001;
      baseLat += latJitter;
      baseLng += lngJitter;
    }

    return MapEntry(baseLat, baseLng);
  }

  // ── Auth helpers ──────────────────────────────────────────────────────────

  /// Current signed-in user, or null.
  static User? get currentUser => _sb.auth.currentUser;

  /// True if there is an active session.
  static bool get isAuthenticated => _sb.auth.currentSession != null;

  /// Sign in with email + password.
  /// Throws [AuthException] on failure.
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _sb.auth.signInWithPassword(email: email, password: password);
  }

  /// Create a new account with email + password and save display name to
  /// user_metadata so it appears on the profile without a separate DB call.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _sb.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  /// Send a password-reset email.
  static Future<void> resetPassword(String email) async {
    await _sb.auth.resetPasswordForEmail(email);
  }

  /// Sign out the current user.
  static Future<void> signOut() async {
    await _sb.auth.signOut();
  }

  /// Send a password-reset email to [email] via Supabase Auth.
  static Future<void> sendPasswordReset(String email) async {
    await _sb.auth.resetPasswordForEmail(email);
  }

  /// Stream that emits an [AuthState] whenever the session changes
  /// (sign in, sign out, token refresh, etc.)
  static Stream<AuthState> get authStateChanges =>
      _sb.auth.onAuthStateChange;

  // ── Property listing ──────────────────────────────────────────────────────

  /// Upload [imageFiles] to the `property-images` bucket and insert a new
  /// row into the `user_listings` table.
  static Future<void> insertProperty({
    required String title,
    required String price,
    required String location,
    required String type,
    required int beds,
    required int baths,
    required String sqft,
    required String floors,
    required String description,
    required String badge,
    required List<File> imageFiles,
    bool posterVerified = false,
  }) async {
    final uid = currentUser?.id ?? 'anon';

    // Compress + rename each image, then upload
    final imageUrls = <String>[];
    final compressed = await ImageHelper.prepareBatch(
      imageFiles,
      prefix: 'listing',
      uid: uid,
    );
    for (int i = 0; i < compressed.length; i++) {
      final file = compressed[i];
      final storagePath = 'listings/$uid/${p.basename(file.path)}';
      await _sb.storage.from('property-images').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      final url = _sb.storage.from('property-images').getPublicUrl(storagePath);
      imageUrls.add(url);
    }

    final coords = _geocode(location, seed: title + description);

    // Insert the listing row
    await _sb.from('user_listings').insert({
      'user_id':     uid,
      'title':       title,
      'price':       price,
      'location':    location,
      'type':        type,
      'beds':        beds,
      'baths':       baths,
      'sqft':        sqft,
      'floors':      floors,
      'description': description,
      'badge':       badge,
      'image_urls':  imageUrls,
      'poster_verified': posterVerified,
      'status':      'pending',
      'lat':         coords.key,
      'lng':         coords.value,
      'created_at':  DateTime.now().toIso8601String(),
    });
  }

  /// Fetch all verified agents (profiles where is_verified = true).
  /// Computes real average rating from the reviews table.
  static Future<List<Agent>> fetchVerifiedAgents() async {
    final rows = await _sb
        .from('profiles')
        .select('id, full_name, avatar_url, phone')
        .eq('is_verified', true)
        .order('created_at', ascending: true);

    if ((rows as List).isEmpty) return [];

    // Fetch all review ratings for these agents in one query
    final agentIds = rows.map((r) => r['id'] as String).toList();
    final reviewRows = await _sb
        .from('reviews')
        .select('agent_id, rating')
        .inFilter('agent_id', agentIds);

    // Build a map: agentUid -> list of ratings
    final Map<String, List<int>> ratingsByAgent = {};
    for (final r in reviewRows as List) {
      final agentId = r['agent_id'] as String;
      final rating  = r['rating']   as int;
      ratingsByAgent.putIfAbsent(agentId, () => []).add(rating);
    }

    final list = <Agent>[];
    int idx = 0;
    for (final row in rows) {
      final uid    = row['id']         as String;
      final name   = (row['full_name'] as String?) ?? 'Agent';
      final avatar = (row['avatar_url'] as String?) ??
          'https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(name)}&backgroundColor=b6e3f4';
      final phone  = row['phone']      as String?;

      final ratings     = ratingsByAgent[uid] ?? [];
      final reviewCount = ratings.length;
      final avgRating   = reviewCount == 0
          ? 0.0
          : ratings.reduce((a, b) => a + b) / reviewCount;

      list.add(Agent(
        id:          idx + 1,
        name:        name,
        role:        'Verified Agent',
        avatarUrl:   avatar,
        rating:      double.parse(avgRating.toStringAsFixed(1)),
        reviewCount: reviewCount,
        uid:         uid,
        phone:       phone,
      ));
      idx++;
    }
    return list;
  }

  // ── Reviews ──────────────────────────────────────────────────────────────────────

  /// Fetch all reviews for an agent (by their profile UUID).
  static Future<List<Review>> fetchAgentReviews(String agentUid) async {
    final rows = await _sb
        .from('reviews')
        .select('id, reviewer_name, reviewer_avatar, rating, comment, created_at')
        .eq('agent_id', agentUid)
        .order('created_at', ascending: false)
        .limit(10);
    return (rows as List).map((r) => Review(
      id:             r['id']              as int,
      reviewerName:   r['reviewer_name']   as String? ?? 'User',
      reviewerAvatar: r['reviewer_avatar'] as String?,
      rating:         r['rating']          as int,
      comment:        r['comment']         as String?,
      createdAt:      DateTime.parse(r['created_at'] as String),
    )).toList();
  }

  /// Return the current user’s existing star rating for [agentUid], or null.
  static Future<int?> fetchMyReviewForAgent(String agentUid) async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final row = await _sb
        .from('reviews')
        .select('rating')
        .eq('reviewer_id', uid)
        .eq('agent_id', agentUid)
        .maybeSingle();
    return row?['rating'] as int?;
  }

  /// Upsert a review (creates or updates the current user’s review).
  static Future<void> submitReview({
    required String agentUid,
    required int    rating,
    String?         comment,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return;

    // Read own profile for denormalized name/avatar on the review row
    final profile = await _sb
        .from('profiles')
        .select('full_name, avatar_url')
        .eq('id', uid)
        .maybeSingle();

    final reviewerName = profile?['full_name']   as String?
        ?? currentUser?.userMetadata?['full_name'] as String?
        ?? 'User';
    final reviewerAvatar = profile?['avatar_url'] as String?;
    final trimmed = comment?.trim();

    await _sb.from('reviews').upsert({
      'reviewer_id':     uid,
      'reviewer_name':   reviewerName,
      'reviewer_avatar': reviewerAvatar,
      'agent_id':        agentUid,
      'rating':          rating,
      'comment':         (trimmed?.isEmpty ?? true) ? null : trimmed,
    }, onConflict: 'reviewer_id,agent_id');
  }


  /// Fetch all listings submitted by the current user.
  static Future<List<Map<String, dynamic>>> fetchMyListings() async {
    final uid = currentUser?.id;
    if (uid == null) return [];
    final rows = await _sb
        .from('user_listings')
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Update an existing listing's text fields. Re-resets status to 'pending'
  /// so the admin reviews the updated version.
  static Future<void> updateListing({
    required int id,
    required String title,
    required String price,
    required String location,
    required String type,
    required int beds,
    required int baths,
    required String sqft,
    required String floors,
    required String description,
    required String badge,
    List<File>? newImageFiles,
    List<String>? existingImageUrls,
  }) async {
    final uid = currentUser?.id ?? 'anon';

    List<String> imageUrls = List.from(existingImageUrls ?? []);

    if (newImageFiles != null && newImageFiles.isNotEmpty) {
      final compressed = await ImageHelper.prepareBatch(
        newImageFiles,
        prefix: 'listing_edit',
        uid: uid,
      );
      for (final file in compressed) {
        final storagePath = 'listings/$uid/${p.basename(file.path)}';
        await _sb.storage.from('property-images').upload(
          storagePath, file,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        imageUrls.add(_sb.storage.from('property-images').getPublicUrl(storagePath));
      }
    }

    final coords = _geocode(location, seed: title + description);

    await _sb.from('user_listings').update({
      'title':       title,
      'price':       price,
      'location':    location,
      'type':        type,
      'beds':        beds,
      'baths':       baths,
      'sqft':        sqft,
      'floors':      floors,
      'description': description,
      'badge':       badge,
      'image_urls':  imageUrls,
      'lat':         coords.key,
      'lng':         coords.value,
      'status':      'pending', // back to pending for re-review
    }).eq('id', id);
  }

  /// Permanently delete a listing row (and optionally its images).
  static Future<void> deleteListing(int id) async {
    await _sb.from('user_listings').delete().eq('id', id);
  }

  /// Build smart notifications from existing data — no extra table needed.
  /// Sources:
  ///   • user_listings  → approval / rejection / pending events
  ///   • conversations  → unread message alerts
  static Future<List<AppNotification>> fetchNotifications() async {
    final uid = currentUser?.id;
    if (uid == null) return [];

    final notes = <AppNotification>[];

    // ── Listing status notifications ──────────────────────────────────────
    try {
      final rows = await _sb
          .from('user_listings')
          .select('id, title, status, created_at, admin_note')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      for (final r in rows as List<dynamic>) {
        final status = (r['status'] as String?) ?? 'pending';
        final title  = (r['title']  as String?) ?? 'Your listing';
        final ts     = DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now();
        final note   = (r['admin_note'] as String?);

        switch (status) {
          case 'approved':
            notes.add(AppNotification(
              id: 'listing_approved_${r['id']}',
              type: NotificationType.listingApproved,
              title: 'Listing Approved 🎉',
              body: '"$title" is now live on 123Homes.',
              time: ts,
            ));
          case 'rejected':
            notes.add(AppNotification(
              id: 'listing_rejected_${r['id']}',
              type: NotificationType.listingRejected,
              title: 'Listing Not Approved',
              body: note != null
                  ? '"$title" was rejected. Reason: $note'
                  : '"$title" was not approved. Tap to edit and resubmit.',
              time: ts,
            ));
          case 'pending':
            notes.add(AppNotification(
              id: 'listing_pending_${r['id']}',
              type: NotificationType.listingPending,
              title: 'Listing Under Review ⏳',
              body: '"$title" is being reviewed by our team.',
              time: ts,
            ));
        }
      }
    } catch (_) {}

    // ── Unread message notifications ──────────────────────────────────────
    try {
      final convRows = await _sb
          .from('conversations')
          .select('id, last_msg, unread, updated_at')
          .eq('user_id', uid)
          .gt('unread', 0)
          .order('updated_at', ascending: false);

      for (final r in convRows as List<dynamic>) {
        final unread = (r['unread'] as int?) ?? 0;
        final last   = (r['last_msg'] as String?) ?? 'New message';
        final ts     = DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now();
        notes.add(AppNotification(
          id: 'msg_${r['id']}',
          type: NotificationType.newMessage,
          title: 'New Message 💬',
          body: unread == 1 ? last : '$unread unread messages',
          time: ts,
        ));
      }
    } catch (_) {}

    // Sort newest first
    notes.sort((a, b) => b.time.compareTo(a.time));
    return notes;
  }

  // ── Agent verification ────────────────────────────────────────────────────

  /// Fetch the current user's profile: details, is_verified + latest application status.
  static Future<Map<String, dynamic>> fetchMyProfile() async {
    final uid = currentUser?.id;
    if (uid == null) {
      return {
        'is_verified': false,
        'application_status': null,
        'admin_note': null,
        'full_name': 'Unknown User',
        'avatar_url': null,
        'email': '',
      };
    }

    // Get profile row
    final profile = await _sb
        .from('profiles')
        .select('is_verified, full_name, avatar_url, phone')
        .eq('id', uid)
        .maybeSingle();

    final isVerified = (profile?['is_verified'] as bool?) ?? false;
    final fullName = profile?['full_name'] as String? ?? currentUser?.userMetadata?['full_name'] as String? ?? 'Unknown User';
    final avatarUrl = profile?['avatar_url'] as String?;
    final phone = profile?['phone'] as String?;
    final email = currentUser?.email ?? '';

    // Get latest application (most recently submitted)
    final app = await _sb
        .from('agent_applications')
        .select('status, admin_note')
        .eq('user_id', uid)
        .order('submitted_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return {
      'is_verified':         isVerified,
      'application_status':  app?['status'] as String?,
      'admin_note':          app?['admin_note'] as String?,
      'full_name':           fullName,
      'avatar_url':          avatarUrl,
      'email':               email,
      'phone':               phone,
    };
  }

  /// Update the current user's profile info.
  static Future<void> updateProfile({
    required String fullName,
    String? avatarUrl,
    String? phone,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return;

    final data = <String, dynamic>{
      'full_name': fullName,
    };
    if (avatarUrl != null) {
      data['avatar_url'] = avatarUrl;
    }
    if (phone != null) {
      data['phone'] = phone.trim().isEmpty ? null : phone.trim();
    }

    await _sb.from('profiles').update(data).eq('id', uid);
  }

  /// Upload an avatar image file to the public 'avatars' storage bucket and return the public URL.
  static Future<String> uploadAvatar(File file) async {
    final uid = currentUser?.id ?? 'anon';

    // Compress + rename with canonical pattern
    final compressed = await ImageHelper.prepare(
      file,
      prefix: 'avatar',
      uid: uid,
      quality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    final storagePath = '$uid/${p.basename(compressed.path)}';

    await _sb.storage.from('avatars').upload(
      storagePath,
      compressed,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );

    return _sb.storage.from('avatars').getPublicUrl(storagePath);
  }


  /// Upload CAC document and insert a new agent_application row.
  static Future<void> submitAgentApplication({
    required String businessName,
    required String phone,
    required int experienceYears,
    required File cacDoc,
  }) async {
    final uid = currentUser?.id ?? 'anon';
    final user = currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'Unknown';

    // Upload CAC doc to private bucket
    final ext = p.extension(cacDoc.path).replaceFirst('.', '');
    final storagePath = '$uid/cac_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _sb.storage.from('agent-docs').upload(
      storagePath,
      cacDoc,
      fileOptions: FileOptions(contentType: 'application/$ext', upsert: true),
    );

    // We store the storage path (admin uses service-role to generate signed URL)
    await _sb.from('agent_applications').insert({
      'user_id':          uid,
      'full_name':        fullName,
      'business_name':    businessName,
      'phone':            phone,
      'experience_years': experienceYears,
      'cac_doc_url':      storagePath,
      'status':           'pending',
      'submitted_at':     DateTime.now().toIso8601String(),
    });
  }
  // ── Property fetching ─────────────────────────────────────────────────────

  /// Fetch approved user listings from Supabase and map them to [Property] objects.
  /// Only reads from `user_listings` where status = 'approved'.
  static Future<List<Property>> fetchProperties() async {
    // Fetch approved listings — promoted ones first, then newest
    final userRows = await _sb
        .from('user_listings')
        .select('*')
        .eq('status', 'approved')
        .order('is_promoted', ascending: false)
        .order('promoted_at',  ascending: false)
        .order('created_at',   ascending: false);

    final list = <Property>[];
    if ((userRows as List).isEmpty) return list;

    // Batch fetch profiles for all posters
    final userIds = userRows
        .map((row) => row['user_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet()
        .toList();

    final Map<String, Map<String, dynamic>> profilesMap = {};
    final Map<String, List<int>> ratingsByAgent = {};

    if (userIds.isNotEmpty) {
      try {
        final profileRows = await _sb
            .from('profiles')
            .select('id, full_name, avatar_url, phone, is_verified')
            .inFilter('id', userIds);
        for (final p in profileRows as List) {
          profilesMap[p['id'] as String] = p as Map<String, dynamic>;
        }

        // Fetch reviews to calculate rating dynamically for each poster
        final reviewRows = await _sb
            .from('reviews')
            .select('agent_id, rating')
            .inFilter('agent_id', userIds);
        for (final r in reviewRows as List) {
          final agentId = r['agent_id'] as String;
          final rating  = r['rating']   as int;
          ratingsByAgent.putIfAbsent(agentId, () => []).add(rating);
        }
      } catch (_) {}
    }

    int idx = 0;
    for (final row in userRows) {
      final rawId = row['id'] as int;
      final id = rawId + 10000; // Offset to avoid any future conflicts
      final beds = (row['beds'] as int?) ?? 0;
      final sqft = (row['sqft'] as String?) ?? '0';

      final imageUrls = row['image_urls'] as List<dynamic>?;
      final imagePath = (imageUrls != null && imageUrls.isNotEmpty)
          ? imageUrls.first as String
          : 'assets/images/house1.png';

      final agentIndex = rawId % 4;
      final isPromoted  = (row['is_promoted'] as bool?) ?? false;
      final promotedAtStr = row['promoted_at'] as String?;

      // Resolve poster Agent details
      final uid = row['user_id'] as String?;
      final profile = uid != null ? profilesMap[uid] : null;
      final name = profile?['full_name'] as String? ?? 'Unknown Agent';
      final avatar = profile?['avatar_url'] as String? ??
          'https://api.dicebear.com/7.x/avataaars/svg?seed=${Uri.encodeComponent(name)}&backgroundColor=b6e3f4';
      final phone = profile?['phone'] as String?;
      final isVerified = (profile?['is_verified'] as bool?) ?? false;

      final ratings = uid != null ? (ratingsByAgent[uid] ?? []) : [];
      final reviewCount = ratings.length;
      final avgRating = reviewCount == 0
          ? 0.0
          : ratings.reduce((a, b) => a + b) / reviewCount;

      final agent = Agent(
        id: idx + 1,
        name: name,
        role: isVerified ? 'Verified Agent' : 'Agent',
        avatarUrl: avatar,
        rating: double.parse(avgRating.toStringAsFixed(1)),
        reviewCount: reviewCount,
        uid: uid,
        phone: phone,
      );

      list.add(Property(
        id:             id,
        name:           row['title'] as String,
        price:          row['price'] as String,
        location:       (row['location'] as String?) ?? '',
        type:           (row['type'] as String?) ?? 'house',
        beds:           beds,
        baths:          (row['baths'] as int?) ?? 0,
        rating:         double.parse(avgRating.toStringAsFixed(1)), // Use real rating of poster
        imagePath:      imagePath,
        badge:          (row['badge'] as String?) ?? 'New',
        description:    (row['description'] as String?) ?? '',
        agentIndex:     agentIndex,
        sqft:           sqft,
        floors:         (row['floors'] as String?) ?? '1 Floor',
        tags:           ['$beds Rooms', '$sqft Sqm', 'New'],
        lat:            (row['lat'] as num?)?.toDouble() ?? _geocode(row['location'] as String? ?? '', seed: (row['title'] as String? ?? '') + rawId.toString()).key,
        lng:            (row['lng'] as num?)?.toDouble() ?? _geocode(row['location'] as String? ?? '', seed: (row['title'] as String? ?? '') + rawId.toString()).value,
        posterVerified: isVerified, // Use database verification status
        isPromoted:     isPromoted,
        promotedAt:     promotedAtStr != null ? DateTime.tryParse(promotedAtStr) : null,
        posterUid:      uid,
        agent:          agent,
      ));
      idx++;
    }

    return list;
  }

  /// Boost a listing to the top by setting is_promoted = true and
  /// recording the current timestamp for ordering.
  static Future<void> promoteListing(int id) async {
    await _sb.from('user_listings').update({
      'is_promoted': true,
      'promoted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  /// Fetch all conversations for the current user, including the last message.
  static Future<List<ChatConversation>> fetchConversations() async {
    final uid = currentUser?.id;
    if (uid == null) return [];

    final rows = await _sb
        .from('conversations')
        .select('id, agent_id, created_at')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    final convs = <ChatConversation>[];
    for (final row in rows as List<dynamic>) {
      final convId   = row['id'] as int;
      final agentId  = row['agent_id'] as int;
      final agentIdx = (agentId - 1).clamp(0, 999999);

      // Fetch last message + unread count
      final msgs = await _sb
          .from('chat_messages')
          .select('*')
          .eq('conv_id', convId)
          .order('created_at', ascending: false)
          .limit(1);

      final unread = await _sb
          .from('chat_messages')
          .select('id')
          .eq('conv_id', convId)
          .eq('is_read', false)
          .neq('sender_id', uid);

      final lastRow = (msgs as List).isNotEmpty ? msgs.first : null;
      convs.add(ChatConversation(
        id:         convId,
        agentId:    agentId,
        agentIndex: agentIdx,
        createdAt:  DateTime.parse(row['created_at'] as String),
        messages:   [],
        lastMsg:    lastRow?['text'] as String? ?? 'Start a conversation…',
        lastTime:   lastRow != null
            ? _formatTime(DateTime.parse(lastRow['created_at'] as String))
            : '',
        unreadCount: (unread as List).length,
      ));
    }
    return convs;
  }

  static Future<int> getOrCreateConversation(int agentId) async {
    final uid = currentUser!.id;
    // Check if it already exists
    final existing = await _sb
        .from('conversations')
        .select('id')
        .eq('user_id', uid)
        .eq('agent_id', agentId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as int;
    }

    // Otherwise, create a new one
    final inserted = await _sb
        .from('conversations')
        .insert({'user_id': uid, 'agent_id': agentId})
        .select('id')
        .single();
    return inserted['id'] as int;
  }

  /// Fetch messages for a conversation.
  static Future<List<ChatMessage>> fetchMessages(int convId) async {
    final rows = await _sb
        .from('chat_messages')
        .select('*')
        .eq('conv_id', convId)
        .order('created_at');
    return (rows as List).map((r) => ChatMessage.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Send a message.
  static Future<void> sendChatMessage(int convId, String text) async {
    await _sb.from('chat_messages').insert({
      'conv_id':   convId,
      'sender_id': currentUser!.id,
      'text':      text,
      'is_read':   false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Mark all messages in a conversation as read (for current user).
  static Future<void> markMessagesRead(int convId) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _sb
        .from('chat_messages')
        .update({'is_read': true})
        .eq('conv_id', convId)
        .eq('is_read', false)
        .neq('sender_id', uid);
  }

  /// Subscribe to real-time new messages in a conversation.
  /// Call [channel.unsubscribe()] to cancel.
  static RealtimeChannel subscribeToMessages(
      int convId, void Function(ChatMessage) onNewMessage) {
    return _sb
        .channel('messages:$convId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conv_id',
            value: convId,
          ),
          callback: (payload) {
            final msg = ChatMessage.fromJson(payload.newRecord);
            onNewMessage(msg);
          },
        )
        .subscribe();
  }

  static String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    if (now.difference(local).inDays == 0) {
      return '${local.hour.toString().padLeft(2,'0')}:${local.minute.toString().padLeft(2,'0')}';
    } else if (now.difference(local).inDays == 1) {
      return 'Yesterday';
    } else {
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return days[local.weekday - 1];
    }
  }
}

