import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:godrage/Models/chat_model.dart'; // Ensure this import is correct
import 'package:godrage/providers/session_provider.dart';
import 'package:provider/provider.dart';

class PinnedMessageTab extends StatelessWidget {
  final String sessionID;

  const PinnedMessageTab({super.key, required this.sessionID});

  @override
  Widget build(BuildContext context) {
    if (sessionID.isEmpty) {
      return const Center(child: Text("Invalid session ID."));
    }

    final chatStream =
        context.read<SessionProvider>().getSessionStream(sessionID);

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

        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.data() == null) {
          return const Center(child: Text("No messages found."));
        }

        final sessionData = snapshot.data!.data();
        final messages = (sessionData?['chat_history'] as List<dynamic>)
            .map((messageData) => ChatMessage.fromFirestore(messageData))
            .toList();

        final botMessages =
            messages.where((message) => !message.isUserMessage).toList();

        if (botMessages.isEmpty) {
          return const Center(child: Text("No pinned messages found."));
        }

        return ListView.builder(
          itemCount: botMessages.length,
          itemBuilder: (context, index) {
            final message = botMessages[index];
            return _buildMessage(message);
          },
        );
      },
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.green[50], // Customize the color for bot messages
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message.message,
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
