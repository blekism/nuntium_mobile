import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String postId;
  final String pdfUrl; // Pass the URL of the PDF file.
  final bool isPosted;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.postId,
    required this.isPosted,
  });

  @override
  PdfViewerScreenState createState() => PdfViewerScreenState();
}

class PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  String? localFilePath;
  int currentPage = 0;
  int totalPages = 0;
  final firebaseFunctions = FirebaseFunctions();
  bool _postActionInitiated = false;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf(widget.pdfUrl);
  }

  Future<void> _downloadAndSavePdf(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/temp.pdf');
      await file.writeAsBytes(response.bodyBytes);

      setState(() {
        localFilePath = file.path;
      });
    } catch (e) {
      print("Error downloading PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        appbarTitle: 'Luminary',
        hasNavigated: false,
      ),
      body: localFilePath != null
          ? Stack(
              children: [
                PDFView(
                  filePath: localFilePath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  onRender: (pages) {
                    setState(() {
                      totalPages = pages ?? 0;
                    });
                  },
                  onPageChanged: (page, _) {
                    setState(() {
                      currentPage = page ?? 0;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: MediaQuery.of(context).size.height * .05,
                      width: MediaQuery.of(context).size.width * .20,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0XFF020B40),
                      ),
                      child: Center(
                        child: Text(
                          '${currentPage + 1} / $totalPages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Please wait while we retrieve your document'),
                  SizedBox(height: 8),
                  CircularProgressIndicator()
                ],
              ),
            ),
      floatingActionButton: widget.isPosted == false &&
              !_postActionInitiated // Modify condition here
          ? FloatingActionButton.extended(
              onPressed: () async {
                // Make onPressed async
                if (widget.postId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Post ID is missing.')),
                  );
                  return;
                }
                setState(() {
                  _postActionInitiated = true; // Hide FAB immediately
                });
                try {
                  await firebaseFunctions.approveInstantPost(widget.postId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Article submitted for posting!')),
                  );
                } catch (e) {
                  print('Error approving post: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to approve post: $e')),
                  );
                  setState(() {
                    _postActionInitiated = false;
                  });
                }
              },
              label: const Text('Post Article'),
              icon: const Icon(Icons.send),
              backgroundColor: Colors.white, // As per user's visible code
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
