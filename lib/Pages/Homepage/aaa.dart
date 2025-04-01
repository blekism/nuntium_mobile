import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareToFacebookPage extends StatelessWidget {
  final String urlToShare =
      "https://example.com"; // Replace with the URL you want to share

  // Function to handle Facebook sharing
  Future<void> shareToFacebook() async {
    final encodedUrl = Uri.encodeComponent(
        "https://music.youtube.com/watch?v=oXSw8DGjf5E&list=RDAMVM8yvWcZ8BtrQ");
    final String facebookUrl =
        "https://www.facebook.com/sharer/sharer.php?u=$encodedUrl";
    final Uri webUri = Uri.parse(facebookUrl);

    try {
      bool launched = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(webUri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (e) {
      debugPrint("Could not launch Facebook: $e");
      throw "Could not launch Facebook sharing";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Share to Facebook"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: shareToFacebook,
          child: const Text("Share to Facebook"),
        ),
      ),
    );
  }
}
