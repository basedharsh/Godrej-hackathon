import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:godrage/Models/chat_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class MessagesTabProvider extends ChangeNotifier {
  bool isTyping = false;
  int? highlightedIndex;
  late ScrollController scrollController;
  Map<int, List<String>> articleLinks = {};
  List<ChatMessage> messages = [];

  MessagesTabProvider({required this.scrollController});

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

  Future<void> fetchArticles(String topic, int index) async {
    String prompt =
        "Give Links of top 5 articles related to the topic of $topic";

    try {
      final model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: "AIzaSyCYMHQs8ZPkDC6vSAGqHor17luXQ6ZSXrA");
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      // Extracting links from the response
      final links = _extractLinks(response.text!);
      articleLinks[index] = links;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  List<String> _extractLinks(String responseText) {
    // Parse the response to extract article links
    final RegExp linkRegExp = RegExp(r'https?://\S+');
    return linkRegExp
        .allMatches(responseText)
        .map((match) => match.group(0)!)
        .toList();
  }

  void updateMessages(List<ChatMessage> newMessages) {
    messages = newMessages;
    notifyListeners();
  }
}
