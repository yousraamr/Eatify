import 'package:flutter/material.dart';

class ViewAllTitleRow extends StatelessWidget {
  final String title;
  final VoidCallback? onView; // 👈 nullable

  const ViewAllTitleRow({
    super.key,
    required this.title,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        // 👇 only show if provided
        if (onView != null)
          TextButton(
            onPressed: onView,
            child: Text(
              "View all",
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          const SizedBox(width: 1), // keeps row structure
      ],
    );
  }
}
