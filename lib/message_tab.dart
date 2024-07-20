import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:godrage/providers/session_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MessagesTab extends StatefulWidget {
  final ScrollController scrollController;
  final String sessionID;

  const MessagesTab({
    super.key,
    required this.scrollController,
    required this.sessionID,
  });

  @override
  _MessagesTabState createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  bool isTyping = false;

  @override
  Widget build(BuildContext context) {
    if (widget.sessionID.isEmpty) {
      return const Center(child: Text("Invalid session ID."));
    }

    final chatStream =
        context.read<SessionProvider>().getSessionStream(widget.sessionID);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: chatStream,
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text("Error loading messages."));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("No messages found."));
        }

        final sessionData = snapshot.data!.data();
        if (sessionData == null) {
          return const Center(child: Text("No messages found."));
        }

        final messages =
            (sessionData['chat_history'] as List<dynamic>).map((messageData) {
          return ChatMessage.fromFirestore(messageData);
        }).toList();

        return ListView.builder(
          controller: widget.scrollController,
          itemCount: messages.length + (isTyping ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == messages.length && isTyping) {
              return _buildTypingIndicator();
            }

            final message = messages[index];
            return Container(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: message.isUserMessage
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: message.isUserMessage
                    ? _buildUserMessage(message)
                    : _buildBotMessage(message),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserMessage(ChatMessage message) {
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15.0),
            bottomLeft: Radius.circular(15.0),
            bottomRight: Radius.circular(15.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.message,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              DateFormat('hh:mm a')
                  .format(DateTime.now()), // Replace with actual timestamp
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotMessage(ChatMessage message) {
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(15.0),
            bottomLeft: Radius.circular(15.0),
            bottomRight: Radius.circular(15.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.black,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    message.message,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.black87, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message.message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard'),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              DateFormat('hh:mm a')
                  .format(DateTime.now()), // Replace with actual timestamp
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(15.0),
                bottomLeft: Radius.circular(15.0),
                bottomRight: Radius.circular(15.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.black,
                ),
                const SizedBox(width: 8.0),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String message;
  final bool isUserMessage;

  ChatMessage({required this.message, required this.isUserMessage});

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    return ChatMessage(
      message: data['message'] ?? '',
      isUserMessage: data['isUser'] ?? false,
    );
  }
}
