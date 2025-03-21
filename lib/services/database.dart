import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Database {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> addUserdb(
      String userID, String email, String userName, String vpa) async {
    try {
      final user = <String, dynamic>{
        'uid': userID,
        'email': email,
        'username': userName,
        'vpa': vpa,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _db.collection("users").doc(userID).set(user);
    } catch (e) {
      rethrow;
    }
  }

  static Future<DocumentSnapshot> _getData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not found");
    }
    return await _db.collection('users').doc(user.uid).get();
  }

  static Future<String> getVpa() async {
    final doc = await _getData();
    final data = doc.data() as Map<String, dynamic>;
    return data['vpa'] ?? '';
  }

  static Future<void> updateVpa(String vpa) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not found");
    }
    await _db.collection('users').doc(user.uid).update({'vpa': vpa});
  }

  static Future<String> getUsername() async {
    final doc = await _getData();
    final data = doc.data() as Map<String, dynamic>;
    return data['username'] ?? '';
  }

  static Future<void> addExpense(
      double amount, String payerEmail, String description) async {
    final user = _auth.currentUser;
    final vpa = await getVpa();
    final userName = await getUsername();
    if (user == null) {
      throw Exception("User not found");
    }
    await _db.collection('expenses').add({
      'amount': amount,
      'payerEmail': payerEmail.trim(),
      'creatorId': user.uid,
      'creatorEmail': user.email,
      'creatorName': userName,
      'description': description,
      'creatorVpa': vpa,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateExpenseStatus(
      String expenseId, String status) async {
    await _db.collection('expenses').doc(expenseId).update({'status': status});
  }

  static Future<void> addFavorite(String name, String email) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not found");
    }
    await _db.collection('users').doc(user.uid).collection('favorites').add({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteFavorite(String favoriteId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not found");
    }
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(favoriteId)
        .delete();
  }

  static Future<Map<String, String>> getFavorites() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not found");
    }
    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();
    final favorites = <String, String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      favorites[data['email']] = data['name'];
    }
    return favorites;
  }
}
