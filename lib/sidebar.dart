import 'package:flutter/material.dart';
import 'package:godrage/app_theme.dart';

class Sidebar extends StatelessWidget {
  final List<String> chatList;
  final String selectedChat;
  final Function(String) selectChat;
  final VoidCallback addNewChat;

  const Sidebar({
    super.key,
    required this.chatList,
    required this.selectedChat,
    required this.selectChat,
    required this.addNewChat,
  });

  @override
  Widget build(BuildContext context) {
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
                  'assets/logo.png', // Replace with your logo asset path
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

          for (String chat in chatList)
            SidebarItem(
              icon: Icons.chat,
              text: chat,
              isSelected: selectedChat == chat,
              onTap: () => selectChat(chat),
            ),
          const Spacer(),
          // ElevatedButton(
          //   onPressed: addNewChat,
          //   child: const Text('Add New Chat'),
          // ),
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
