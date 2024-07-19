import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:godrage/app_theme.dart';
import 'package:godrage/history_section.dart';
import 'package:godrage/message_input.dart';
import 'package:godrage/message_tab.dart';
import 'package:godrage/providers/session_provider.dart';
import 'package:godrage/sidebar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.title});

  final String title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String _selectedChat = 'Chat 1';
  final List<String> _chatList = ['Chat 1', 'Chat 2', 'Chat 3'];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _newChatController = TextEditingController();
  final Map<String, List<ChatMessage>> _chatMessages = {
    'Chat 1': [ChatMessage(text: 'Hello!'), ChatMessage(text: 'How are you?')],
    'Chat 2': [
      ChatMessage(text: 'Hi there!'),
      ChatMessage(text: 'What\'s up?')
    ],
    'Chat 3': [
      ChatMessage(text: 'Hey!'),
      ChatMessage(text: 'Long time no see!')
    ],
  };
  late List<ChatMessage> _messages;

  final ScrollController _scrollController = ScrollController();

  init() async {
    _messages = _chatMessages[_selectedChat] ?? [];
    await context.read<SessionProvider>().getSessions();
    print("init");
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _newChatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(text: _controller.text, isUserMessage: true));
        _chatMessages[_selectedChat] = _messages;
        _controller.clear();
      });
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      // Simulate an automatic reply after sending a message
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _messages.add(ChatMessage(
              text: 'This is an automatic reply.', isUserMessage: false));
          _chatMessages[_selectedChat] = _messages;
        });
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendFile(FilePickerResult result) {
    setState(() {
      _messages.add(ChatMessage(file: result.files.first, isUserMessage: true));
      _chatMessages[_selectedChat] = _messages;
    });
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    // Simulate an automatic reply after sending a file
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages
            .add(ChatMessage(text: 'File received!', isUserMessage: false));
        _chatMessages[_selectedChat] = _messages;
      });
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _selectChat(String chatName) {
    setState(() {
      _selectedChat = chatName;
      _messages = _chatMessages[chatName] ?? [];
    });
    if (MediaQuery.of(context).size.width < 600) {
      Navigator.pop(context); // Close the drawer on mobile
    }
  }

  Future<void> _addNewChat() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        // Local Flask server URL
        String url = 'http://127.0.0.1:5000/create_session';

        var request = http.MultipartRequest('POST', Uri.parse(url));

        // Handle file content for web
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'pdfs',
            file.bytes!,
            filename: file.name,
          ));
        } else if (file.path != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'pdfs',
            file.path!,
            filename: file.name,
          ));
        } else {
          print('File not supported');
          return;
        }

        var response = await request.send();

        if (response.statusCode == 200) {
          var responseData = await http.Response.fromStream(response);
          var responseJson = json.decode(responseData.body);
          String newChatName = 'Chat ${_chatList.length + 1}';
          print('Response from server: $responseJson');

          // setState(() {
          //   _chatList.add(newChatName);
          //   _chatMessages[newChatName] = [];
          //   _selectedChat = newChatName;
          //   _messages = [];
          //   _newChatController.clear();
          // });

          // Navigator.of(context).pop();
        } else {
          // Handle error
          print('Failed to create session: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showDrawer = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: showDrawer
          ? PreferredSize(
              preferredSize: const Size.fromHeight(30.0),
              child: AppBar(
                backgroundColor: AppTheme.colorDarkGrey,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(widget.title,
                    style: AppTheme.fontStyleLarge.copyWith(
                      color: Colors.white,
                    )),
              ),
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(10.0),
              child: AppBar(
                backgroundColor: AppTheme.colorDarkGrey,
              ),
            ),
      drawer: showDrawer
          ? Drawer(
              child: Sidebar(
                chatList: _chatList,
                selectedChat: _selectedChat,
                selectChat: _selectChat,
                addNewChat: _addNewChat,
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool showSidebar = constraints.maxWidth > 600;
          return Row(
            children: <Widget>[
              if (showSidebar)
                Sidebar(
                  chatList: _chatList,
                  selectedChat: _selectedChat,
                  selectChat: _selectChat,
                  addNewChat: _addNewChat,
                ),
              Expanded(
                child: Container(
                  color: AppTheme.colorDarkGrey,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(
                          16.0), // Margin around the container
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16.0), // Rounded corners
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
                        children: <Widget>[
                          Expanded(
                            child: MessagesTab(
                              messages: _messages,
                              scrollController: _scrollController,
                            ),
                          ),
                          MessageInput(
                            controller: _controller,
                            sendMessage: _sendMessage,
                            sendFile: _sendFile,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (showSidebar) const HistorySection(),
            ],
          );
        },
      ),
    );
  }
}

class ChatMessage {
  final String? text;
  final PlatformFile? file;
  final bool isUserMessage;

  ChatMessage({this.text, this.file, this.isUserMessage = true});
}
