import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference get _foods => _db.collection('foods');

  Future<void> addFood(FoodModel food) {
    return _foods.add(food.toFirestore());
  }

  Stream<List<FoodModel>> getFoods() {
    if (_uid == null) return const Stream.empty();
    return _foods
        .where('userId', isEqualTo: _uid)
        .orderBy('expiryDate', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FoodModel.fromFirestore(d)).toList());
  }

  Future<void> updateFood(FoodModel food) {
    return _foods.doc(food.id).update(food.toFirestore());
  }

  Future<void> deleteFood(String id) {
    return _foods.doc(id).delete();
  }
}