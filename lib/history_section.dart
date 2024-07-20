import 'package:flutter/material.dart';
import 'package:godrage/app_theme.dart';

class HistorySection extends StatelessWidget {
  final Function(String) onSelectOption;

  const HistorySection({super.key, required this.onSelectOption});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppTheme.colorDarkGrey,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Options',
              style: AppTheme.fontStyleLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          const Divider(color: Colors.grey),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildOptionItem(
                  icon: Icons.push_pin,
                  text: 'Pinned Message',
                  onTap: () => onSelectOption('Pinned Message'),
                ),
                _buildOptionItem(
                  icon: Icons.model_training,
                  text: 'Choose Model',
                  onTap: () => onSelectOption('Choose Model'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
        ),
        title: Text(
          text,
          style: AppTheme.fontStyleDefault.copyWith(
            color: Colors.white,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
