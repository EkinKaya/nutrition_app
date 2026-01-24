import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Auth methods
  static User? get currentUser => auth.currentUser;
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  static Future<UserCredential> signInWithEmail(String email, String password) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<UserCredential> registerWithEmail(String email, String password) {
    return auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> signOut() => auth.signOut();

  // Firestore collections
  static CollectionReference get usersCollection => firestore.collection('users');
  static CollectionReference get recipesCollection => firestore.collection('recipes');
  static CollectionReference get messagesCollection => firestore.collection('messages');
}
