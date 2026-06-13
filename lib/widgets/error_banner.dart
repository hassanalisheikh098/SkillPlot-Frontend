import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8D7DA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFF5C6CB)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Color(0xFF721C24)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Color(0xFF721C24), fontSize: 14),
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF721C24),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Color(0xFF721C24)),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text("Retry"),
            ),
          ],
        ],
      ),
    );
  }
}
