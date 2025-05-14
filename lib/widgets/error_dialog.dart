import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String message;

  const ErrorDialog({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Error'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
} 