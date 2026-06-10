import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSearch;
  final VoidCallback? onNotification;

  const AppHeader({
    super.key,
    required this.title,
    this.onSearch,
    this.onNotification,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineLarge,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search_outlined),
                onPressed: onSearch ?? () {},
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: onNotification ?? () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
