import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String getChatId(String uid1, String uid2) {
  List<String> ids = [uid1, uid2];
  ids.sort();
  return ids.join("_");
}

class ChatPage extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String receiverId;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class ChatListPage extends StatelessWidget {
  final String currentUserId;

  const ChatListPage({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

              final participants = List<String>.from(
                chat['participants'] ?? [],
              );

              participants.remove(currentUserId);
              final otherUserId = participants.isNotEmpty
                  ? participants.first
                  : "Unknown";

              return ListTile(
                leading: CircleAvatar(
                  child: Text(otherUserId[0].toUpperCase()),
                ),
                title: Text("User: $otherUserId"),
                subtitle: Text(chat['lastMessage'] ?? ""),
                trailing: chat['lastMessageTime'] != null
                    ? Text(
                        DateFormat('hh:mm a').format(
                          (chat['lastMessageTime'] as Timestamp).toDate(),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        chatId: chat.id,
                        senderId: currentUserId,
                        receiverId: otherUserId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId);

    await chatRef.set({
      'participants': [widget.senderId, widget.receiverId],
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderId': widget.senderId,
      'receiverId': widget.receiverId,
      'text': text,
      'messageType': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
    });
  }

  Future<void> _markMessagesAsSeen() async {
    final query = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: widget.senderId)
        .where('isSeen', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      doc.reference.update({'isSeen': true});
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Medical Consultation"),
        backgroundColor: const Color(0xFF1e40af),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                _markMessagesAsSeen();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                if (messages.isEmpty) {
                  return const Center(child: Text("Start the conversation..."));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;

                    final isMe = msg['senderId'] == widget.senderId;

                    final timestamp = msg['timestamp'] as Timestamp?;
                    final time = timestamp != null
                        ? timestamp.toDate()
                        : DateTime.now();

                    return Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF1e40af)
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 16),
                            ),
                          ),
                          child: Text(
                            msg['text'] ?? "",
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat('hh:mm a').format(time),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (isMe)
                                Text(
                                  msg['isSeen'] == true ? "✔✔ Seen" : "✔ Sent",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF1e40af),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
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
