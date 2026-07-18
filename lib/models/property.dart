// lib/models/property.dart
class Property {
  final int id;
  final String name;
  final String price;
  final String location;
  final String type;
  final int beds;
  final int baths;
  final double rating;
  final String imagePath;
  final String badge;
  final String description;
  final int agentIndex;
  final String sqft;
  final String floors;
  final List<String> tags;
  final double lat;
  final double lng;
  final bool posterVerified;
  final bool isPromoted;
  final DateTime? promotedAt;
  final String? posterUid;
  final Agent? agent;

  const Property({
    required this.id,
    required this.name,
    required this.price,
    required this.location,
    required this.type,
    required this.beds,
    required this.baths,
    required this.rating,
    required this.imagePath,
    required this.badge,
    required this.description,
    required this.agentIndex,
    required this.sqft,
    required this.floors,
    required this.tags,
    required this.lat,
    required this.lng,
    this.posterVerified = false,
    this.isPromoted = false,
    this.promotedAt,
    this.posterUid,
    this.agent,
  });
}

class Agent {
  final int id;
  final String name;
  final String role;
  final String avatarUrl;
  final double rating;
  final int reviewCount;   // number of reviews backing the rating
  final String? uid;       // Supabase profile UUID (null for legacy mock agents)
  final String? phone;     // Contact number, revealed on demand

  const Agent({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.rating,
    this.reviewCount = 0,
    this.uid,
    this.phone,
  });
}

// ── Review model ──────────────────────────────────────────────────────────────

class Review {
  final int id;
  final String reviewerName;
  final String? reviewerAvatar;
  final int rating;      // 1–5 stars
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.reviewerName,
    this.reviewerAvatar,
    required this.rating,
    this.comment,
    required this.createdAt,
  });
}

// ── Chat models (Supabase-backed) ─────────────────────────────────────────

class ChatMessage {
  final int id;
  final int convId;
  final String senderId;   // auth.uid() of sender
  final String text;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.convId,
    required this.senderId,
    required this.text,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id:        j['id'] as int,
    convId:    j['conv_id'] as int,
    senderId:  j['sender_id'] as String,
    text:      j['text'] as String,
    isRead:    (j['is_read'] as bool?) ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  String get timeLabel {
    final h = createdAt.toLocal().hour.toString().padLeft(2, '0');
    final m = createdAt.toLocal().minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class ChatConversation {
  final int id;
  final int agentId;       // references agents.id
  final int agentIndex;    // 0-based index into local agents list
  final DateTime createdAt;
  List<ChatMessage> messages;
  String lastMsg;
  String lastTime;
  int unreadCount;

  ChatConversation({
    required this.id,
    required this.agentId,
    required this.agentIndex,
    required this.createdAt,
    required this.messages,
    required this.lastMsg,
    required this.lastTime,
    required this.unreadCount,
  });
}

// ── Legacy mock models (kept for compile-time compatibility) ──────────────

class Message {
  final String text;
  final bool isSent;
  final String time;
  const Message({required this.text, required this.isSent, required this.time});
}

class Conversation {
  final int id;
  final int agentIndex;
  String lastMsg;
  final String time;
  int unread;
  final List<Message> messages;
  Conversation({required this.id, required this.agentIndex, required this.lastMsg,
    required this.time, required this.unread, required this.messages});
}

// ── Notifications ─────────────────────────────────────────────────────────────

enum NotificationType { listingApproved, listingRejected, listingPending, newMessage }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime time;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
  });
}
