import 'package:flutter/material.dart';
import 'package:godrage/Models/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessagesTabProvider extends ChangeNotifier {
  bool isTyping = false;
  int? highlightedIndex;
  late ScrollController scrollController;
  List<ChatMessage> messages = [];
  int? pinOptionIndex;
  Set<int> favoritedMessages = {}; // Track favorited messages by their index

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

  void showPinOption(int index, bool show) {
    pinOptionIndex = show ? index : null;
    notifyListeners();
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

  bool isMessageFavorited(int index) {
    return favoritedMessages.contains(index);
  }

  void toggleFavorite(int index, String messageContent, String sessionId) {
    if (favoritedMessages.contains(index)) {
      favoritedMessages.remove(index);
      _updateFavoriteStatusInFirestore(messageContent, sessionId, false);
    } else {
      favoritedMessages.add(index);
      _updateFavoriteStatusInFirestore(messageContent, sessionId, true);
    }
    notifyListeners();
  }

  void loadFavorites(List<ChatMessage> messages, String sessionId) async {
    final favs = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('favorites')
        .get();

    favoritedMessages.clear();
    for (var doc in favs.docs) {
      final messageIndex = messages.indexWhere((msg) => msg.message == doc.id);
      if (messageIndex != -1) {
        favoritedMessages.add(messageIndex);
      }
    }
    notifyListeners();
  }

  void _updateFavoriteStatusInFirestore(
      String messageContent, String sessionId, bool isFavorited) {
    final docRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('favorites')
        .doc(messageContent);

    if (isFavorited) {
      docRef.set({
        'messageContent': messageContent,
        'sessionId': sessionId,
        'createdAt': DateTime.now(),
      });
    } else {
      docRef.delete();
    }
  }
}
