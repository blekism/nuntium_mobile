import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';

class FullscreenTextPage extends StatelessWidget {
  final ValueNotifier<String> contentNotifier;

  const FullscreenTextPage({super.key, required this.contentNotifier});

  @override
  Widget build(BuildContext context) {
    final TextEditingController fullscreenController =
        TextEditingController(text: contentNotifier.value);

    contentNotifier.addListener(() {
      if (fullscreenController.text != contentNotifier.value) {
        fullscreenController.text = contentNotifier.value;
        fullscreenController.selection =
            TextSelection.collapsed(offset: fullscreenController.text.length);
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(
        hasNavigated: false,
        appbarTitle: 'Fullscreen Content',
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ValueListenableBuilder<String>(
          valueListenable: contentNotifier,
          builder: (context, value, child) {
            return TextFormField(
              initialValue: value,
              keyboardType: TextInputType.multiline,
              maxLines: null, // Allows unlimited lines in fullscreen
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                contentNotifier.value = text;
              },
            );
          },
        ),
      ),
    );
  }
}
