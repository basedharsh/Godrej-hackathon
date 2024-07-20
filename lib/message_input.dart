import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback sendMessage;

  const MessageInput({
    super.key,
    required this.controller,
    required this.sendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Set background color to black
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
                hintStyle: const TextStyle(
                    color: Colors.white70), // Set hint text color to white
                filled: true,
                fillColor: Colors
                    .grey[800], // Set input field background color to dark grey
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none, // Remove the border
                ),
                contentPadding: const EdgeInsets.all(12.0),
              ),
              style: const TextStyle(
                  color: Colors.white), // Set text color to white
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            onPressed: sendMessage,
            tooltip: 'Send',
            backgroundColor: Colors.orange,
            child: const Icon(Icons.send,
                color: Colors.white), // Set icon color to white
          ),
        ],
      ),
    );
  }
}
