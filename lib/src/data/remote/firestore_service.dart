import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  FirebaseFirestore get db => _firestore;

  DocumentReference<Map<String, dynamic>> userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> shopDoc(String shopId) {
    return _firestore.collection('shops').doc(shopId);
  }

  DocumentReference<Map<String, dynamic>> shopSubDoc(String shopId, String collection, String docId) {
    return _firestore.collection('shops').doc(shopId).collection(collection).doc(docId);
  }

  CollectionReference<Map<String, dynamic>> shopSubCollection(String shopId, String collection) {
    return _firestore.collection('shops').doc(shopId).collection(collection);
  }
}

