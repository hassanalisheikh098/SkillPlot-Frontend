import 'package:flutter/material.dart';

class SpLoader extends StatelessWidget {
  final String? message;

  const SpLoader({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF4B0082)),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
