import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:godrage/providers/session_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

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
  int? highlightedIndex;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController;
    _simulateIncomingMessage();
  }

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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });

        return ListView.builder(
          controller: _scrollController,
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
                child: _buildMessage(message, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessage(ChatMessage message, int index) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: AnimatedContainer(
        duration: const Duration(seconds: 2),
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: highlightedIndex == index
              ? (message.isUserMessage ? Colors.blue[200] : Colors.green[100])
              : (message.isUserMessage ? Colors.blue[100] : Colors.green[50]),
          borderRadius: message.isUserMessage
              ? const BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  bottomLeft: Radius.circular(15.0),
                  bottomRight: Radius.circular(15.0),
                )
              : const BorderRadius.only(
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
        child: message.isUserMessage
            ? Text(
                message.message,
                style: const TextStyle(
                  color: Colors.black,
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[300],
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                    ),
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
                    icon:
                        const Icon(Icons.copy, color: Colors.black87, size: 16),
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
              maxWidth: MediaQuery.of(context).size.width * 0.50,
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
                CircleAvatar(
                  backgroundColor: Colors.green[300],
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8.0),
                const Expanded(
                  child: TypingIndicator(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _simulateIncomingMessage() {
    setState(() {
      isTyping = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        isTyping = false;
        highlightedIndex = 3; // Simulating an incoming message index
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          highlightedIndex = null;
        });
      });
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

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Dot(),
        SizedBox(width: 4),
        Dot(),
        SizedBox(width: 4),
        Dot(),
      ],
    );
  }
}

class Dot extends StatefulWidget {
  const Dot({Key? key}) : super(key: key);

  @override
  _DotState createState() => _DotState();
}

class _DotState extends State<Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const CircleAvatar(
        radius: 4,
        backgroundColor: Colors.grey,
      ),
    );
  }
}
