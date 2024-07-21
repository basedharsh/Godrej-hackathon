import 'package:flutter/material.dart';

class MessageFormatter extends StatelessWidget {
  final String message;
  const MessageFormatter({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> formattedText = _formatMessage(message);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: formattedText,
    );
  }

  List<Widget> _formatMessage(String message) {
    List<Widget> formattedText = [];
    bool inBulletList = false;

    message.split('\n').forEach((line) {
      if (line.startsWith('## ')) {
        formattedText.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              line.replaceFirst('## ', ''),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22.0,
                color: Colors.white,
              ),
            ),
          ),
        );
      } else if (line.startsWith('# ')) {
        formattedText.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              line.replaceFirst('# ', ''),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: Colors.white,
              ),
            ),
          ),
        );
      } else if (line.startsWith('**') &&
          line.endsWith('**') &&
          !line.contains(' ')) {
        formattedText.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              line.substring(2, line.length - 2),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          ),
        );
      } else if (line.startsWith('*')) {
        if (!inBulletList) {
          inBulletList = true;
          formattedText.add(const SizedBox(height: 8));
        }
        formattedText.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '\u2022 ',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: _buildInlineFormattedText(line.substring(2)),
              ),
            ],
          ),
        );
      } else {
        if (inBulletList) {
          inBulletList = false;
          formattedText.add(const SizedBox(height: 8));
        }
        formattedText.add(
          _buildInlineFormattedText(line),
        );
      }
    });

    return formattedText;
  }

  Widget _buildInlineFormattedText(String text) {
    final textSpans = <TextSpan>[];
    final parts = text.split(RegExp(r'(\*\*.*?\*\*)'));

    for (var part in parts) {
      if (part.startsWith('**') && part.endsWith('**')) {
        textSpans.add(
          TextSpan(
            text: part.substring(2, part.length - 2),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19.0,
              color: Colors.white,
            ),
          ),
        );
      } else {
        textSpans.addAll(_handleNestedBoldText(part));
      }
    }

    return RichText(
      text: TextSpan(
        children: textSpans,
      ),
    );
  }

  List<TextSpan> _handleNestedBoldText(String text) {
    final spans = <TextSpan>[];
    final parts = text.split(RegExp(r'(\*\*.*?\*\*)'));

    for (var part in parts) {
      if (part.startsWith('**') && part.endsWith('**')) {
        spans.add(
          TextSpan(
            text: part.substring(2, part.length - 2),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
              color: Colors.white,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: part,
            style: const TextStyle(
              fontSize: 14.0,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return spans;
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';

// class MessageFormatter extends StatelessWidget {
//   final String message;
//   const MessageFormatter({required this.message, Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MarkdownBody(
//       data: message,
//       styleSheet: MarkdownStyleSheet(
//         h1: const TextStyle(
//             fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.white),
//         h2: const TextStyle(
//             fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
//         p: const TextStyle(fontSize: 14.0, color: Colors.white),
//         strong: const TextStyle(
//             fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
//         listBullet: const TextStyle(fontSize: 14.0, color: Colors.white),
//       ),
//     );
//   }
// }

