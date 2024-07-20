import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback sendMessage;
  // final Function(FilePickerResult) sendFile;

  const MessageInput({
    super.key,
    required this.controller,
    required this.sendMessage,
    // required this.sendFile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          // IconButton(
          //   icon: const Icon(Icons.document_scanner_outlined),
          //   onPressed: () async {
          //     FilePickerResult? result = await FilePicker.platform.pickFiles();
          //     if (result != null) {
          //       sendFile(result);
          //     }
          //   },
          //   tooltip: 'Upload',
          // ),
          const SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.all(12.0),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            onPressed: sendMessage,
            tooltip: 'Send',
            backgroundColor: Colors.orange,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
