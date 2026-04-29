import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpiryStatus { safe, nearExpiry, expired }

class FoodModel {
  final String id;
  final String name;
  final DateTime expiryDate;
  final String? imageUrl;
  final String? notes;
  final String? category;
  final DateTime dateAdded;
  final String userId;

  FoodModel({
    required this.id,
    required this.name,
    required this.expiryDate,
    this.imageUrl,
    this.notes,
    this.category,
    required this.dateAdded,
    required this.userId,
  });

  /// Days remaining until expiry (negative = already expired)
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  ExpiryStatus get status {
    final days = daysRemaining;
    if (days < 0) return ExpiryStatus.expired;
    if (days <= 2) return ExpiryStatus.nearExpiry;
    return ExpiryStatus.safe;
  }

  factory FoodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodModel(
      id: doc.id,
      name: data['name'] ?? '',
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      notes: data['notes'],
      category: data['category'],
      dateAdded: data['dateAdded'] != null
          ? (data['dateAdded'] as Timestamp).toDate()
          : DateTime.now(),
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'imageUrl': imageUrl,
      'notes': notes,
      'category': category,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'userId': userId,
    };
  }

  FoodModel copyWith({
    String? id,
    String? name,
    DateTime? expiryDate,
    String? imageUrl,
    String? notes,
    String? category,
    DateTime? dateAdded,
    String? userId,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      dateAdded: dateAdded ?? this.dateAdded,
      userId: userId ?? this.userId,
    );
  }
}