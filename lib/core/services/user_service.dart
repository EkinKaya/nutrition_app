import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  static String? get currentUserId => _auth.currentUser?.uid;

  /// Yeni kullanici profili olustur
  static Future<void> createUserProfile({
    required String email,
    int? age,
    int? weight,
    int? height,
    String? gender,
    String? dietType,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _usersCollection.doc(userId).set({
      'email': email,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'dietType': dietType,
      'pdfUrl': null,
      'pdfName': null,
      'pdfContent': null,
      'pdfUploadedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Kullanici profilini getir
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final doc = await _usersCollection.doc(userId).get();
    return doc.data();
  }

  /// Kullanici profilini guncelle
  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _usersCollection.doc(userId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Kullanici profilini dinle (real-time)
  static Stream<DocumentSnapshot<Map<String, dynamic>>>? getUserProfileStream() {
    final userId = currentUserId;
    if (userId == null) return null;

    return _usersCollection.doc(userId).snapshots();
  }

  /// PDF'den metin cikarir
  static Future<String?> _extractTextFromPdf(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);

      String text = '';
      for (int i = 0; i < document.pages.count; i++) {
        text += extractor.extractText(startPageIndex: i, endPageIndex: i);
        text += '\n';
      }

      document.dispose();

      // Bos veya cok kisa ise null don
      if (text.trim().length < 10) return null;

      // Maksimum 5000 karakter (token tasarrufu icin)
      if (text.length > 5000) {
        text = text.substring(0, 5000);
      }

      return text.trim();
    } catch (e) {
      return null;
    }
  }

  /// PDF yukle - metin cikar ve sakla
  static Future<String?> uploadPdf(File file, String fileName) async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      // Onceki PDF'i sil
      await _deletePreviousPdf();

      // PDF'den metin cikar
      final pdfContent = await _extractTextFromPdf(file);

      // Yeni PDF'i yukle: users/{uid}/documents/blood_test.pdf
      final ref = _storage.ref('users/$userId/documents/$fileName');
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      // Firestore'da PDF bilgisini guncelle
      await _usersCollection.doc(userId).update({
        'pdfUrl': downloadUrl,
        'pdfName': fileName,
        'pdfContent': pdfContent,
        'pdfUploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  /// Onceki PDF'i Storage'dan sil
  static Future<void> _deletePreviousPdf() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final doc = await _usersCollection.doc(userId).get();
      final data = doc.data();
      if (data != null && data['pdfName'] != null) {
        final oldRef = _storage.ref('users/$userId/documents/${data['pdfName']}');
        await oldRef.delete();
      }
    } catch (_) {
      // Dosya yoksa devam et
    }
  }

  /// PDF'i sil
  static Future<void> deletePdf() async {
    final userId = currentUserId;
    if (userId == null) return;

    await _deletePreviousPdf();
    await _usersCollection.doc(userId).update({
      'pdfUrl': null,
      'pdfName': null,
      'pdfContent': null,
      'pdfUploadedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Chat icin tum kullanici verisini getir (profil + pdf content)
  static Future<Map<String, dynamic>?> getFullUserContext() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final doc = await _usersCollection.doc(userId).get();
    return doc.data();
  }
}
