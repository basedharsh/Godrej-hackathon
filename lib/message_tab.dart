import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:godrage/Models/chat_model.dart';
import 'package:godrage/app_theme.dart';
import 'package:godrage/providers/message_tab_provider.dart';
import 'package:godrage/providers/session_provider.dart';
import 'package:godrage/widgets/typing_indicator.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // Import this for Clipboard functionality
import 'package:flutter/scheduler.dart'; // Import this for SchedulerBinding

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
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MessagesTabProvider>(context, listen: false);
    provider.scrollController = widget.scrollController;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (widget.scrollController.hasClients) {
      widget.scrollController.jumpTo(
        widget.scrollController.position.maxScrollExtent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sessionID.isEmpty) {
      return Container(
          color: AppTheme.backgroundColor,
          child: const Center(
              child: Text("Waiting for session...",
                  style: TextStyle(color: AppTheme.textColor))));
    }

    final chatStream =
        context.read<SessionProvider>().getSessionStream(widget.sessionID);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: chatStream,
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: AppTheme.backgroundColor,
            child: const Center(
                child: CircularProgressIndicator(color: AppTheme.textColor)),
          );
        }

        if (snapshot.hasError) {
          return Container(
            color: AppTheme.backgroundColor,
            child: const Center(
                child: Text("Error loading messages.",
                    style: TextStyle(color: AppTheme.textColor))),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.data() == null) {
          return Container(
            color: AppTheme.backgroundColor,
            child: const Center(
                child: Text("No messages found.",
                    style: TextStyle(color: AppTheme.textColor))),
          );
        }
        final sessionData = snapshot.data!.data();
        if (sessionData == null) {
          return Container(
            color: AppTheme.backgroundColor,
            child: const Center(
                child: Text("No messages found.",
                    style: TextStyle(color: AppTheme.textColor))),
          );
        }

        final messages =
            (sessionData['chat_history'] as List<dynamic>).map((messageData) {
          return ChatMessage.fromFirestore(messageData);
        }).toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<MessagesTabProvider>(context, listen: false)
              .scrollController
              .animateTo(
                Provider.of<MessagesTabProvider>(context, listen: false)
                    .scrollController
                    .position
                    .maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final provider =
              Provider.of<MessagesTabProvider>(context, listen: false);
          provider.updateMessages(messages);
          provider.loadFavorites(messages, widget.sessionID); // Load favorites

          SchedulerBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        });

        return Container(
          color: AppTheme.backgroundColor,
          child: Consumer<MessagesTabProvider>(
            builder: (context, provider, child) {
              return ListView.builder(
                controller: provider.scrollController,
                itemCount:
                    provider.messages.length + (provider.isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == provider.messages.length && provider.isTyping) {
                    return _buildTypingIndicator();
                  }

                  final message = provider.messages[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Align(
                      alignment: message.isUserMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: _buildMessage(message, index, provider),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMessage(
      ChatMessage message, int index, MessagesTabProvider provider) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.45, // Width of chat bubble
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
                color: provider.highlightedIndex == index
                    ? (message.isUserMessage
                        ? AppTheme.userMessageHighlightedBackgroundColor
                        : AppTheme.botMessageBackgroundColor)
                    : (message.isUserMessage
                        ? AppTheme.userMessageBackgroundColor
                        : AppTheme.botMessageBackgroundColor),
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
                        color: AppTheme.textColor, // Set text color to white
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
                            IconButton(
                              icon: Icon(
                                provider.isMessageFavorited(index)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: provider.isMessageFavorited(index)
                                    ? Colors.red
                                    : AppTheme.textColor,
                                size: 16,
                              ),
                              onPressed: () {
                                provider.toggleFavorite(
                                    index, message.message, widget.sessionID);
                              },
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

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.45,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  decoration: const BoxDecoration(
                    color: AppTheme.typingIndicatorBackgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.zero,
                      bottomLeft: Radius.circular(15.0),
                      bottomRight: Radius.circular(15.0),
                      topRight: Radius.circular(15.0),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TypingIndicatorDots(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
