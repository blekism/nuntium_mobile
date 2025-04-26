import 'Package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  final String? customMessage;

  const LoadingScreen({
    super.key,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFD0D0D0).withOpacity(0.5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF020B40)),
            ),
            const SizedBox(height: 20),
            Text(
              customMessage ?? 'Loading...',
              style: const TextStyle(
                color: Color(0XFF020B40),
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
