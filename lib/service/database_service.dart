import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> create({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final DocumentReference ref = _firestore
        .collection(collectionPath)
        .doc(docId);
    await ref.set(data);
  }

  Future<DocumentSnapshot?> read({
    required String collectionPath,
    required String docId,
  }) async {
    final DocumentReference ref = _firestore
        .collection(collectionPath)
        .doc(docId);
    final DocumentSnapshot snapshot = await ref.get();
    return snapshot.exists ? snapshot : null;
  }

  Future<void> update({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final DocumentReference ref = _firestore
        .collection(collectionPath)
        .doc(docId);
    await ref.update(data);
  }

  Future<void> set({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final DocumentReference ref = _firestore
        .collection(collectionPath)
        .doc(docId);
    await ref.set(data, SetOptions(merge: merge));
  }

  Future<void> delete({
    required String collectionPath,
    required String docId,
  }) async {
    final DocumentReference ref = _firestore
        .collection(collectionPath)
        .doc(docId);
    await ref.delete();
  }
}
