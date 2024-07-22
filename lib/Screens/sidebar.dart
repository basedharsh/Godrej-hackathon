import 'package:flutter/material.dart';
import 'package:godrage/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:godrage/providers/session_provider.dart';

class Sidebar extends StatelessWidget {
  final String selectedSessionID;
  final Function(String) selectChat;
  final VoidCallback addNewChat;

  const Sidebar({
    super.key,
    required this.selectedSessionID,
    required this.selectChat,
    required this.addNewChat,
  });

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionProvider>().sessions;

    return Container(
      width: 250,
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 30,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Godrej-Bot',
                  style: AppTheme.fontStyleLarge
                      .copyWith(color: AppTheme.textColor),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey),
          Expanded(
            child: ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final chatName = session['name'] ?? 'Unknown Chat';
                return SidebarItem(
                  icon: Icons.chat,
                  text: chatName,
                  isSelected: selectedSessionID == session['id'],
                  onTap: () => selectChat(session['id']),
                );
              },
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton(
              onPressed: addNewChat,
              style: ElevatedButton.styleFrom(
                foregroundColor: AppTheme.textColor,
                backgroundColor: const Color.fromARGB(255, 251, 112, 69),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Add New Chat'),
            ),
          ),
          const Divider(color: Colors.grey),
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isSelected
          ? const Color.fromARGB(255, 251, 112, 69).withOpacity(0.2)
          : Colors.transparent,
      child: ListTile(
        leading: Icon(icon,
            color: isSelected
                ? const Color.fromARGB(255, 251, 112, 69)
                : AppTheme.textColor),
        title: Text(
          text,
          style: AppTheme.fontStyleDefault.copyWith(
            color: isSelected
                ? const Color.fromARGB(255, 251, 112, 69)
                : AppTheme.textColor,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
