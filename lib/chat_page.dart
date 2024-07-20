import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:godrage/Models/chat_model.dart';
import 'package:godrage/app_theme.dart';
import 'package:godrage/globals.dart';
import 'package:godrage/history_section.dart';
import 'package:godrage/message_input.dart';
import 'package:godrage/message_tab.dart';
import 'package:godrage/providers/session_provider.dart';
import 'package:godrage/sidebar.dart';
import 'package:godrage/utils/get_uuid.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:godrage/providers/message_tab_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.title});

  final String title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String _selectedSessionID = '';
  String _selectedOption = 'Messages';
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
    final provider = Provider.of<MessagesTabProvider>(context, listen: false);

    // Add user's message to the local state
    provider.addMessage(ChatMessage(message: question, isUserMessage: true));
    String id = getUUID();

    sessionsRef.doc(sessionId).update({
      'chat_history': FieldValue.arrayUnion([
        {
          'message': question,
          'isUser': true,
          'id': id,
        }
      ])
    });

    provider.setIsTyping(true);

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
        final botMessage = responseData['chat_history']
            .last['content']; // Adjust based on your API response

        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.addBotMessage(
              ChatMessage(message: botMessage, isUserMessage: false));
        });

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        provider.setIsTyping(false);

        if (kDebugMode) {
          print('Failed to ask question: ${response.statusCode}');
        }
      }
    } catch (e) {
      provider.setIsTyping(false);

      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  void _selectSession(String sessionID) {
    setState(() {
      _selectedSessionID = sessionID;
      _selectedOption = 'Messages';
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
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        String url = 'http://127.0.0.1:5000/create_session';
        var request = http.MultipartRequest('POST', Uri.parse(url));

        request.fields['chat_name'] = chatName;
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'files',
            file.bytes!,
            filename: file.name,
          ));
        } else if (file.path != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'files',
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
                  'Please enter a chat name and upload a document to create a new chat.'),
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

  void _selectOption(String option) {
    setState(() {
      _selectedOption = option;
    });
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
                            child: _selectedOption == 'Pinned Message'
                                ? PinnedMessageTab(
                                    sessionID: _selectedSessionID)
                                : _selectedOption == 'Choose Model'
                                    ? ChooseModelTab(
                                        sessionID: _selectedSessionID)
                                    : MessagesTab(
                                        scrollController: _scrollController,
                                        sessionID: _selectedSessionID,
                                      ),
                          ),
                          if (_selectedOption == 'Messages')
                            // Message is Sent
                            MessageInput(
                              controller: _controller,
                              sendMessage: () {
                                final message = _controller.text.trim();
                                if (message.isNotEmpty) {
                                  _askQuestion(
                                    question: message,
                                    sessionId: _selectedSessionID,
                                  );
                                  _controller.clear();
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (showSidebar)
                HistorySection(
                  onSelectOption: _selectOption,
                ),
            ],
          );
        },
      ),
    );
  }
}

class PinnedMessageTab extends StatelessWidget {
  final String sessionID;

  const PinnedMessageTab({super.key, required this.sessionID});

  @override
  Widget build(BuildContext context) {
    // Replace with the actual pinned message UI
    return Center(
      child: Text(
        'Pinned Messages for Session: $sessionID',
        style: AppTheme.fontStyleLarge,
      ),
    );
  }
}

class ChooseModelTab extends StatelessWidget {
  final String sessionID;

  const ChooseModelTab({super.key, required this.sessionID});

  @override
  Widget build(BuildContext context) {
    // Replace with the actual choose model UI
    return Center(
      child: Text(
        'Choose Model for Session: $sessionID',
        style: AppTheme.fontStyleLarge,
      ),
    );
  }
}
