import 'package:flutter/material.dart';
import 'package:godrage/app_theme.dart';

class HistorySection extends StatelessWidget {
  const HistorySection({super.key});

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
              'History',
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
                _buildHistoryItem(
                  icon: Icons.create,
                  text: 'Create welcome form',
                  isSelected: true,
                ),
                _buildHistoryItem(
                  icon: Icons.info_outline,
                  text: 'Instructions',
                  isSelected: false,
                ),
                _buildHistoryItem(
                  icon: Icons.work_outline,
                  text: 'Career',
                  isSelected: false,
                ),
                _buildHistoryItem(
                  icon: Icons.timeline,
                  text: 'Career',
                  isSelected: false,
                ),
                _buildHistoryItem(
                  icon: Icons.person_add_alt_1,
                  text: 'Onboarding',
                  isSelected: false,
                ),
                _buildHistoryItem(
                  icon: Icons.help_outline,
                  text: 'Onboarding',
                  isSelected: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required String text,
    required bool isSelected,
  }) {
    return Container(
      color:
          isSelected ? AppTheme.colorBlue.withOpacity(0.2) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.colorYellow : Colors.white,
        ),
        title: Text(
          text,
          style: AppTheme.fontStyleDefault.copyWith(
            color: isSelected ? AppTheme.colorYellow : Colors.white,
          ),
        ),
        onTap: () {
          // Handle history item tap
        },
      ),
    );
  }
}
