import 'package:flutter/foundation.dart';
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
  String _selectedSessionID = '';
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _newChatNameController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await context.read<SessionProvider>().getSessions();
    setState(() {
      _selectedSessionID = context.read<SessionProvider>().sessions.isNotEmpty
          ? context.read<SessionProvider>().sessions.first['id']
          : '';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _newChatNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _askQuestion(
      {required String sessionId, required String question}) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/ask_question'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'session_id': sessionId,
          'question': question,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final chatHistory = responseData['chat_history'];

        if (kDebugMode) {
          print(chatHistory);
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        // Handle error
        if (kDebugMode) {
          print('Failed to ask question: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  // void _sendFile(FilePickerResult result) {
  //   setState(() {
  //     _messages.add(ChatMessage(file: result.files.first, isUserMessage: true));
  //     _chatMessages[_selectedChat] = _messages;
  //   });
  //   _scrollController.animateTo(
  //     _scrollController.position.maxScrollExtent,
  //     duration: const Duration(milliseconds: 300),
  //     curve: Curves.easeOut,
  //   );

  //   // Simulate an automatic reply after sending a file
  //   Future.delayed(const Duration(seconds: 1), () {
  //     setState(() {
  //       _messages
  //           .add(ChatMessage(text: 'File received!', isUserMessage: false));
  //       _chatMessages[_selectedChat] = _messages;
  //     });
  //     _scrollController.animateTo(
  //       _scrollController.position.maxScrollExtent,
  //       duration: const Duration(milliseconds: 300),
  //       curve: Curves.easeOut,
  //     );
  //   });
  // }

  void _selectSession(String sessionID) {
    setState(() {
      _selectedSessionID = sessionID;
    });
    if (MediaQuery.of(context).size.width < 600) {
      Navigator.pop(context); // Close the drawer on mobile
    }
  }

  Future<void> _addNewChat(String chatName) async {
    final sessionProvider = context.read<SessionProvider>();
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        String url = 'http://127.0.0.1:5000/create_session';
        var request = http.MultipartRequest('POST', Uri.parse(url));

        request.fields['chat_name'] = chatName;
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
          if (kDebugMode) {
            print('File not supported');
          }
          return;
        }

        var response = await request.send();

        if (response.statusCode == 200) {
          var responseData = await http.Response.fromStream(response);
          var responseJson = json.decode(responseData.body);
          if (kDebugMode) {
            print('Response from server: $responseJson');
          }
          sessionProvider.addSession(responseJson);

          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // Handle error
          if (kDebugMode) {
            print('Failed to create session: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  void _showAddChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Chat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Please enter a chat name and upload a PDF file to create a new chat.'),
              TextField(
                controller: _newChatNameController,
                decoration: const InputDecoration(
                  hintText: 'Chat Name',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Upload'),
              onPressed: () async {
                await _addNewChat(_newChatNameController.text);
              },
            ),
          ],
        );
      },
    );
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
                selectedSessionID: _selectedSessionID,
                selectChat: _selectSession,
                addNewChat: _showAddChatDialog,
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
                  selectedSessionID: _selectedSessionID,
                  selectChat: _selectSession,
                  addNewChat: _showAddChatDialog,
                ),
              Expanded(
                child: Container(
                  color: AppTheme.colorDarkGrey,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
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
                              scrollController: _scrollController,
                              sessionID: _selectedSessionID,
                            ),
                          ),
                          MessageInput(
                            controller: _controller,
                            sendMessage: () {
                              _askQuestion(
                                question: _controller.text,
                                sessionId: _selectedSessionID,
                              );
                            },
                            // sendFile: (){},
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
