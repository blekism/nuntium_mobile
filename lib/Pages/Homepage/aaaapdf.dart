import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl; // Pass the URL of the PDF file.

  const PdfViewerScreen({super.key, required this.pdfUrl});

  @override
  PdfViewerScreenState createState() => PdfViewerScreenState();
}

class PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localFilePath;
  int currentPage = 0;
  int totalPages = 0;

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
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        centerTitle: true,
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
    );
  }
}
