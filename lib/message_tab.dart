import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:godrage/providers/session_provider.dart';
import 'package:provider/provider.dart';

class MessagesTab extends StatelessWidget {
  final ScrollController scrollController;
  final String sessionID;

  const MessagesTab({
    super.key,
    required this.scrollController,
    required this.sessionID,
  });

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
            controller: scrollController,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: message.isUserMessage
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: <Widget>[
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        decoration: BoxDecoration(
                          color: message.isUserMessage
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          message.message,
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
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
