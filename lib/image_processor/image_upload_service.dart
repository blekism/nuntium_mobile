import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

class ImageUploadService {
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  ImageUploadService({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generates a perceptual hash that detects similar images
  Future<String> _generatePerceptualHash(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes)!;

      // 1. Crop to focus on central content (ignoring watermarks/edges)
      final cropped = img.copyCrop(
        image,
        x: (image.width * 0.1).toInt(),
        y: (image.height * 0.1).toInt(),
        width: (image.width * 0.8).toInt(),
        height: (image.height * 0.8).toInt(),
      );

      // 2. Normalization pipeline
      final normalized = img.grayscale(
        img.gaussianBlur(
          img.copyResize(cropped, width: 32, height: 32),
          radius: 2, // Blur to tolerate small movements
        ),
      );

      // 3. Calculate average pixel value
      final pixels = normalized.getBytes();
      final avg = pixels.reduce((a, b) => a + b) / pixels.length;

      // 4. Generate binary hash (1 if pixel > avg, 0 otherwise)
      return pixels.map((p) => p > avg ? '1' : '0').join();
    } catch (e) {
      // Fallback to file hash if processing fails
      final bytes = await imageFile.readAsBytes();
      return sha256.convert(bytes).toString();
    }
  }

  /// Calculates similarity percentage between two hashes
  double _calculateSimilarity(String hash1, String hash2) {
    int matchingBits = 0;
    final length = hash1.length < hash2.length ? hash1.length : hash2.length;

    for (int i = 0; i < length; i++) {
      if (hash1[i] == hash2[i]) matchingBits++;
    }
    return matchingBits / length;
  }

  /// Uploads approved images with progress tracking and stores the perceptual hash
  Future<List<UploadResult>> uploadApprovedImages({
    required List<File> approvedImages,
    required String userId,
    void Function(int, double)? onProgress,
  }) async {
    final results = <UploadResult>[];

    for (int i = 0; i < approvedImages.length; i++) {
      final imageFile = approvedImages[i];
      try {
        final hash =
            await _generatePerceptualHash(imageFile); // Generate hash here
        final ext = path.extension(imageFile.path);
        final storagePath =
            'images/${hash.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}$ext';

        // Upload with progress
        final uploadTask = _storage.ref(storagePath).putFile(imageFile);
        onProgress?.call(i, 0);
        uploadTask.snapshotEvents.listen((snapshot) {
          onProgress?.call(i, snapshot.bytesTransferred / snapshot.totalBytes);
        });

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore, including the hash
        final batch = _firestore.batch();
        final hashRef = _firestore.collection('image_hashes').doc();
        batch.set(hashRef, {
          'hash': hash, // Store the generated hash
          'url': downloadUrl,
          'uploaded_by': userId,
          'created_at': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        results.add(UploadResult.success(
          file: imageFile,
          url: downloadUrl,
          storagePath: storagePath,
        ));
      } catch (e) {
        results.add(UploadResult.failure(
          file: imageFile,
          error: e.toString(),
        ));
      }
    }

    return results;
  }

  /// Finds similar existing images based on a list of image URLs
  Future<Map<String, List<String>>> findSimilarExistingImages(
      List<String> imageUrls,
      {double threshold = 0.75}) async {
    Map<String, String> urlToHash = {};
    Map<String, List<String>> similarityMap = {};

    // 1. Fetch hashes for the provided image URLs
    final snapshot = await _firestore
        .collection('image_hashes')
        .where('url', whereIn: imageUrls)
        .get();
    for (final doc in snapshot.docs) {
      urlToHash[doc.get('url') as String] = doc.get('hash') as String;
      similarityMap[doc.get('url') as String] = []; // Initialize the map
    }

    // 2. Fetch all existing hashes (optimize this if needed for large datasets)
    final allHashesSnapshot = await _firestore.collection('image_hashes').get();
    Map<String, String> allHashes = {};
    for (final doc in allHashesSnapshot.docs) {
      allHashes[doc.get('url') as String] = doc.get('hash') as String;
    }

    // 3. Compare hashes
    for (final currentImageUrl in imageUrls) {
      final currentHash = urlToHash[currentImageUrl];
      if (currentHash != null) {
        for (final existingImageUrl in allHashes.keys) {
          if (currentImageUrl != existingImageUrl) {
            final existingHash = allHashes[existingImageUrl];
            if (existingHash != null &&
                _calculateSimilarity(currentHash, existingHash) >= threshold) {
              similarityMap[currentImageUrl]?.add(existingImageUrl);
            }
          }
        }
      }
    }

    similarityMap.removeWhere((_, value) => value.isEmpty);
    return similarityMap;
  }
}

/// Result of individual upload attempt
class UploadResult {
  final File file;
  final String? url;
  final String? storagePath;
  final String? error;

  bool get isSuccess => url != null;

  UploadResult.success({
    required this.file,
    required this.url,
    required this.storagePath,
  }) : error = null;

  UploadResult.failure({
    required this.file,
    required this.error,
  })  : url = null,
        storagePath = null;
}
