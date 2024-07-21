import 'package:flutter/material.dart';
import 'package:godrage/Models/chat_model.dart';

class MessagesTabProvider extends ChangeNotifier {
  bool isTyping = false;
  int? highlightedIndex;
  late ScrollController scrollController;
  List<ChatMessage> messages = [];
  Set<int> likedMessages = {}; // Track liked messages by their index

  void simulateIncomingMessage() {
    isTyping = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      isTyping = false;
      highlightedIndex = 3; // Simulating an incoming message index
      notifyListeners();

      Future.delayed(const Duration(seconds: 2), () {
        highlightedIndex = null;
        notifyListeners();
      });
    });
  }

  void updateMessages(List<ChatMessage> newMessages) {
    messages = newMessages;
    notifyListeners();
  }

  void setIsTyping(bool typing) {
    isTyping = typing;
    notifyListeners();
  }

  void addMessage(ChatMessage message) {
    messages.add(message);
    notifyListeners();
  }

  void addBotMessage(ChatMessage message) {
    messages.add(message);
    setIsTyping(false);
    notifyListeners();
  }

  bool isMessageLiked(int index) {
    return likedMessages.contains(index);
  }

  void toggleLike(int index) {
    if (likedMessages.contains(index)) {
      likedMessages.remove(index);
    } else {
      likedMessages.add(index);
    }
    notifyListeners();
  }
}
