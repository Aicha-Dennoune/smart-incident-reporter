import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/chat_service.dart';
import '../../theme/industrial_tokens.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/industrial/neo_card.dart';

class IncidentChatPage extends StatefulWidget {
  const IncidentChatPage({
    super.key,
    required this.incidentId,
    required this.incidentTitle,
    required this.currentUserId,
    required this.currentUserRole,
    required this.otherUserId,
  });

  final String incidentId;
  final String incidentTitle;
  final String currentUserId;
  final String currentUserRole;
  final String otherUserId;

  @override
  State<IncidentChatPage> createState() => _IncidentChatPageState();
}

class _IncidentChatPageState extends State<IncidentChatPage> {
  final _chat = ChatService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  late final StreamSubscription _readSub;

  @override
  void initState() {
    super.initState();
    _readSub = _chat.watchMessages(widget.incidentId).listen((_) {
      _chat.markAllAsRead(
        incidentId: widget.incidentId,
        currentUserId: widget.currentUserId,
      );
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _readSub.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<String> _currentUserName() async {
    final u = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .get();
    final d = u.data() ?? {};
    final prenom = d['prenom']?.toString() ?? '';
    final nom = d['nom']?.toString() ?? '';
    final full = '$prenom $nom'.trim();
    return full.isEmpty ? 'Utilisateur' : full;
  }

  Future<void> _send() async {
    if (_sending) return;
    final txt = _textController.text.trim();
    if (txt.isEmpty) return;
    setState(() => _sending = true);
    try {
      final senderName = await _currentUserName();
      await _chat.sendMessage(
        incidentId: widget.incidentId,
        senderId: widget.currentUserId,
        senderName: senderName,
        senderRole: widget.currentUserRole,
        text: txt,
      );
      _textController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur envoi: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _hhmm(Timestamp? ts) {
    if (ts == null) return '--:--';
    final dt = ts.toDate();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Discussion'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.incidentTitle,
                    style: const TextStyle(
                      color: IndustrialTokens.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (widget.otherUserId.trim().isEmpty)
                    const Text(
                      'Interlocuteur : inconnu',
                      style: TextStyle(
                        color: IndustrialTokens.textSecondary,
                        fontSize: 12,
                      ),
                    )
                  else
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.otherUserId)
                          .snapshots(),
                      builder: (context, snap) {
                        final d = snap.data?.data() ?? {};
                        final name =
                            '${d['prenom'] ?? ''} ${d['nom'] ?? ''}'.trim();
                        return Text(
                          'Interlocuteur : ${name.isEmpty ? widget.otherUserId : name}',
                          style: const TextStyle(
                            color: IndustrialTokens.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chat.watchMessages(widget.incidentId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur discussion: ${snapshot.error}',
                      style: const TextStyle(color: IndustrialTokens.statRed),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun message pour le moment.',
                      style: TextStyle(color: IndustrialTokens.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    final mine = (d['senderId']?.toString() ?? '') ==
                        widget.currentUserId;
                    final text = d['text']?.toString() ?? '';
                    final senderName = d['senderName']?.toString() ?? '';
                    final createdAt = d['createdAt'] as Timestamp?;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color:
                              mine
                                  ? IndustrialTokens.neon.withValues(alpha: 0.2)
                                  : IndustrialTokens.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: IndustrialTokens.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!mine)
                              Text(
                                senderName,
                                style: const TextStyle(
                                  color: IndustrialTokens.neonMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (!mine) const SizedBox(height: 2),
                            Text(
                              text,
                              style: const TextStyle(
                                color: IndustrialTokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _hhmm(createdAt),
                              style: const TextStyle(
                                color: IndustrialTokens.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        filled: true,
                        fillColor: IndustrialTokens.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: IndustrialTokens.cardBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon:
                        _sending
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.send_rounded),
                    label: const Text('Envoyer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

