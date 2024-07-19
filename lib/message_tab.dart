import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:godrage/chat_page.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MessagesTab extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;

  const MessagesTab({
    super.key,
    required this.messages,
    required this.scrollController,
  });

  void _openPdfFile(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFView(
          filePath: path,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Align(
          alignment: message.isUserMessage
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color:
                  message.isUserMessage ? Colors.white : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: message.file != null
                ? InkWell(
                    onTap: () {
                      if (kIsWeb) {
                        // Web handling can be added here
                      } else {
                        if (message.file!.extension == 'pdf') {
                          _openPdfFile(context, message.file!.path!);
                        } else {
                          OpenFile.open(message.file!.path);
                        }
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.insert_drive_file, color: Colors.blue),
                        const SizedBox(height: 8.0),
                        Text(
                          message.file!.name,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black),
                        ),
                      ],
                    ),
                  )
                : Text(
                    message.text!,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
          ),
        );
      },
    );
  }
}
