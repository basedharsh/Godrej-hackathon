import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:godrage/Models/chat_model.dart';
import 'package:godrage/app_theme.dart';
import 'package:godrage/providers/session_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class PinnedMessageTab extends StatelessWidget {
  final String sessionID;

  const PinnedMessageTab({super.key, required this.sessionID});

  @override
  Widget build(BuildContext context) {
    if (sessionID.isEmpty) {
      return Container(
        color: AppTheme.backgroundColor,
        child: const Center(
          child: Text(
            "Invalid session ID.",
            style: TextStyle(color: AppTheme.textColor),
          ),
        ),
      );
    }

    final chatStream =
        context.read<SessionProvider>().getSessionStream(sessionID);

    return FutureBuilder<String?>(
      future: context.read<SessionProvider>().getSessionName(sessionID),
      builder: (context, nameSnapshot) {
        if (nameSnapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: AppTheme.backgroundColor,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppTheme.textColor,
              ),
            ),
          );
        }

        if (nameSnapshot.hasError) {
          return Container(
            color: AppTheme.backgroundColor,
            child: const Center(
              child: Text(
                "Error loading session name.",
                style: TextStyle(color: AppTheme.textColor),
              ),
            ),
          );
        }

        final sessionName = nameSnapshot.data ?? 'Unknown Session';

        return Container(
          color: AppTheme.backgroundColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Session: $sessionName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: chatStream,
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                          snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.textColor,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          "Error loading messages.",
                          style: TextStyle(color: AppTheme.textColor),
                        ),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data == null ||
                        snapshot.data!.data() == null) {
                      return const Center(
                        child: Text(
                          "No messages found.",
                          style: TextStyle(color: AppTheme.textColor),
                        ),
                      );
                    }

                    final sessionData = snapshot.data!.data();
                    final messages =
                        (sessionData?['chat_history'] as List<dynamic>)
                            .map((messageData) =>
                                ChatMessage.fromFirestore(messageData))
                            .toList();

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('sessions')
                          .doc(sessionID)
                          .collection('favorites')
                          .get(),
                      builder: (context, favSnapshot) {
                        if (favSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.textColor,
                            ),
                          );
                        }

                        if (favSnapshot.hasError) {
                          return const Center(
                            child: Text(
                              "Error loading favorites.",
                              style: TextStyle(color: AppTheme.textColor),
                            ),
                          );
                        }

                        final favDocs = favSnapshot.data?.docs ?? [];
                        final favoriteMessages = messages.where((message) {
                          return favDocs
                              .any((doc) => doc.id == message.message);
                        }).toList();

                        if (favoriteMessages.isEmpty) {
                          return const Center(
                            child: Text(
                              "No pinned messages found.",
                              style: TextStyle(color: AppTheme.textColor),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: favoriteMessages.length,
                          itemBuilder: (context, index) {
                            final message = favoriteMessages[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: Align(
                                alignment: message.isUserMessage
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: _buildMessage(context, message, index),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessage(BuildContext context, ChatMessage message, int index) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.45,
        ),
        child: Column(
          crossAxisAlignment: message.isUserMessage
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              decoration: BoxDecoration(
                color: message.isUserMessage
                    ? AppTheme.userMessageBackgroundColor
                    : AppTheme.botMessageBackgroundColor,
                borderRadius: message.isUserMessage
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(15.0),
                        bottomLeft: Radius.circular(15.0),
                        bottomRight: Radius.circular(15.0),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.zero,
                        bottomLeft: Radius.circular(15.0),
                        bottomRight: Radius.circular(15.0),
                        topRight: Radius.circular(15.0),
                      ),
              ),
              child: message.isUserMessage
                  ? Text(
                      message.message,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            message.message,
                            style: const TextStyle(
                              color: AppTheme.textColor,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                color: AppTheme.textColor,
                                size: 16,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: message.message));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Message copied to clipboard'),
                                  ),
                                );
                              },
                            ),
                            const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
