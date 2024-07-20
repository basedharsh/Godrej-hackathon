import 'package:flutter/material.dart';
import 'package:godrage/app_theme.dart';
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
      color: AppTheme.colorDarkGrey,
      child: Column(
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
                  'God-Rage',
                  style: AppTheme.fontStyleLarge.copyWith(color: Colors.white),
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
          ElevatedButton(
            onPressed: addNewChat,
            child: const Text('Add New Chat'),
          ),
          const Divider(color: Colors.grey),
          SidebarItem(
            icon: Icons.logout,
            text: 'Log out',
            isSelected: false,
            onTap: () {},
          ),
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
      color:
          isSelected ? AppTheme.colorGrey.withOpacity(0.2) : Colors.transparent,
      child: ListTile(
        leading:
            Icon(icon, color: isSelected ? AppTheme.colorYellow : Colors.white),
        title: Text(
          text,
          style: AppTheme.fontStyleDefault.copyWith(
            color: isSelected ? AppTheme.colorYellow : Colors.white,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
