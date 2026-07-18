// lib/screens/messages_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';

// ── Messages List ─────────────────────────────────────────────────────────────
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<ChatConversation> _convs = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final convs = await SupabaseService.fetchConversations();
      if (mounted) setState(() { _convs = convs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ChatConversation> get _filtered {
    if (_search.isEmpty) return _convs;
    final q = _search.toLowerCase();
    return _convs.where((c) {
      return c.lastMsg.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text('Messages',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.textDark)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _load,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: c.surface, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Icon(Icons.refresh_rounded, size: 18, color: c.textDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 46, padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: c.surface, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 18, color: c.textLight),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: TextStyle(color: c.textDark, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search conversations…',
                        hintStyle: TextStyle(color: c.textLight, fontSize: 14),
                        border: InputBorder.none, isDense: true,
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? _buildEmpty(c)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 2),
                            itemBuilder: (ctx, i) {
                              final conv = _filtered[i];
                              final agList = context.read<AppState>().agents;
                              final agIdx = agList.isEmpty ? 0 : conv.agentIndex.clamp(0, agList.length - 1);
                              final agent = agList.isEmpty
                                  ? const Agent(id: 0, name: 'Agent', role: 'Verified Agent',
                                      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=agent', rating: 4.8)
                                  : agList[agIdx];
                              return _ConvItem(
                                agent: agent,
                                conv: conv,
                                onTap: () async {
                                  await SupabaseService.markMessagesRead(conv.id);
                                  if (context.mounted) {
                                    await Navigator.push(ctx,
                                        MaterialPageRoute(builder: (_) => ChatScreen(convId: conv.id, agentIndex: conv.agentIndex)));
                                    _load();
                                  }
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppColorSet c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: c.iconBg, shape: BoxShape.circle),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 32, color: c.textLight),
          ),
          const SizedBox(height: 16),
          Text('No conversations yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textDark)),
          const SizedBox(height: 6),
          Text('Tap "Contact Agent" on any property\nto start a conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textGrey, height: 1.5)),
        ],
      ),
    );
  }
}

// ── Conversation list item ────────────────────────────────────────────────────
class _ConvItem extends StatelessWidget {
  final Agent agent;
  final ChatConversation conv;
  final VoidCallback onTap;
  const _ConvItem({required this.agent, required this.conv, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(radius: 25, backgroundImage: NetworkImage(agent.avatarUrl), backgroundColor: c.iconBg),
                if (conv.agentIndex < 2)
                  Positioned(
                    bottom: 1, right: 1,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: c.green, shape: BoxShape.circle,
                        border: Border.all(color: c.surface, width: 2)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agent.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textDark)),
                  const SizedBox(height: 2),
                  Text(conv.lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: c.textLight)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(conv.lastTime, style: TextStyle(fontSize: 11, color: c.textLight)),
                const SizedBox(height: 4),
                if (conv.unreadCount > 0)
                  Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                    child: Center(child: Text('${conv.unreadCount}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chat Screen ───────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final int convId;
  final int agentIndex;
  const ChatScreen({super.key, required this.convId, required this.agentIndex});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll  = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  RealtimeChannel? _channel;
  final String _uid = SupabaseService.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    final msgs = await SupabaseService.fetchMessages(widget.convId);
    await SupabaseService.markMessagesRead(widget.convId);
    if (mounted) {
      setState(() { _messages = msgs; _loading = false; });
      _scrollToBottom();
    }
  }

  void _subscribeRealtime() {
    _channel = SupabaseService.subscribeToMessages(widget.convId, (msg) {
      if (mounted) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
        if (msg.senderId != _uid) {
          SupabaseService.markMessagesRead(widget.convId);
        }
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await SupabaseService.sendChatMessage(widget.convId, text);
      // Realtime will deliver it back via subscription
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c     = context.colors;
    final agList = context.read<AppState>().agents;
    final agIdx  = agList.isEmpty ? 0 : widget.agentIndex.clamp(0, agList.length - 1);
    final agent  = agList.isEmpty
        ? const Agent(id: 0, name: 'Agent', role: 'Verified Agent',
            avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=agent', rating: 4.8)
        : agList[agIdx];

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        shadowColor: c.cardShadow,
        leadingWidth: 40,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: c.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(agent.avatarUrl), backgroundColor: c.iconBg),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textDark)),
                Row(children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: c.green, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Online', style: TextStyle(fontSize: 11, color: c.green)),
                ]),
              ],
            ),
          ],
        ),
        // ← Call icon REMOVED per user request
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyChat(c, agent)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _buildBubble(_messages[i], c),
                      ),
          ),
          _buildInput(c),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(AppColorSet c, Agent agent) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 36, backgroundImage: NetworkImage(agent.avatarUrl), backgroundColor: c.iconBg),
          const SizedBox(height: 14),
          Text(agent.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.textDark)),
          const SizedBox(height: 6),
          Text('Say hello! Start the conversation below.',
              style: TextStyle(fontSize: 13, color: c.textGrey)),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, AppColorSet c) {
    final isMine = msg.senderId == _uid;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? c.primary : c.surface,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(msg.text, style: TextStyle(
                fontSize: 14,
                color: isMine ? Colors.white : c.textDark,
                height: 1.4)),
            const SizedBox(height: 3),
            Text(msg.timeLabel, style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white60 : c.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(AppColorSet c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _ctrl,
                onSubmitted: (_) => _send(),
                style: TextStyle(color: c.textDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(color: c.textLight, fontSize: 14),
                  border: InputBorder.none, isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: c.primary, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.4),
                    blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
