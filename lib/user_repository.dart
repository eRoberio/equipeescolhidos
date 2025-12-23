import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final CollectionReference users = FirebaseFirestore.instance.collection('users');

  Future<bool> isAdmin(String userId) async {
    final doc = await users.doc(userId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      return data['isAdmin'] == true;
    }
    return false;
  }

  Future<void> createUser(String userId, {bool isAdmin = false}) async {
    await users.doc(userId).set({
      'isAdmin': isAdmin,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
