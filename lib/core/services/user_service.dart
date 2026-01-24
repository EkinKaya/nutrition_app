import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Kullanıcı koleksiyonu referansı
  static CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Mevcut kullanıcının ID'si
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Yeni kullanıcı profili oluştur
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
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Kullanıcı profilini getir
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final doc = await _usersCollection.doc(userId).get();
    return doc.data();
  }

  /// Kullanıcı profilini güncelle
  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _usersCollection.doc(userId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Kullanıcı profilini dinle (real-time)
  static Stream<DocumentSnapshot<Map<String, dynamic>>>? getUserProfileStream() {
    final userId = currentUserId;
    if (userId == null) return null;

    return _usersCollection.doc(userId).snapshots();
  }
}
