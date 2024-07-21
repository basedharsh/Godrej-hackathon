import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:godrage/Models/chat_model.dart';
import 'package:godrage/theme/app_theme.dart';
import 'package:godrage/providers/message_tab_provider.dart';
import 'package:godrage/providers/session_provider.dart';
import 'package:godrage/widgets/msg_formatter.dart';
import 'package:godrage/widgets/typing_indicator.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

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

    if (kIsWeb) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
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

        if (kIsWeb) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
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

          SchedulerBinding.instance.addPostFrameCallback((_) {
            final provider =
                Provider.of<MessagesTabProvider>(context, listen: false);
            provider.updateMessages(messages);

            SchedulerBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          });
        } else {
          final provider =
              Provider.of<MessagesTabProvider>(context, listen: false);
          Future.microtask(() => provider.updateMessages(messages));
        }

        return Container(
          color: AppTheme.backgroundColor,
          child: Consumer<MessagesTabProvider>(
            builder: (context, provider, child) {
              return ListView.builder(
                controller:
                    kIsWeb ? provider.scrollController : ScrollController(),
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
    double maxWidthFactor = kIsWeb ? 0.45 : 0.75;

    return FractionallySizedBox(
      alignment:
          message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      widthFactor: maxWidthFactor,
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
            child: IntrinsicWidth(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * maxWidthFactor,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MessageFormatter(
                        message: message.message,
                      ),
                    ),
                    if (!message
                        .isUserMessage) // Only show buttons for non-user messages
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              color: Colors.white,
                              size: 16,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: message.message));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Message copied to clipboard'),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              provider.isMessageLiked(index)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: provider.isMessageLiked(index)
                                  ? Colors.red
                                  : Colors.white,
                              size: 16,
                            ),
                            onPressed: () {
                              provider.toggleLike(index);
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
              maxWidth:
                  MediaQuery.of(context).size.width * (kIsWeb ? 0.45 : 0.75),
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
