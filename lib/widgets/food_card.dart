import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/food_model.dart';

class FoodCard extends StatelessWidget {
  final FoodModel food;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const FoodCard({
    super.key,
    required this.food,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  Color get _statusColor {
    switch (food.status) {
      case ExpiryStatus.expired:
        return const Color(0xFFE63946);
      case ExpiryStatus.nearExpiry:
        return const Color(0xFFF4A261);
      case ExpiryStatus.safe:
        return const Color(0xFF2D6A4F);
    }
  }

  Color get _statusBg {
    switch (food.status) {
      case ExpiryStatus.expired:
        return const Color(0xFFFFEDED);
      case ExpiryStatus.nearExpiry:
        return const Color(0xFFFFF3E0);
      case ExpiryStatus.safe:
        return const Color(0xFFE8F5EE);
    }
  }

  String get _statusLabel {
    switch (food.status) {
      case ExpiryStatus.expired:
        return 'Expired';
      case ExpiryStatus.nearExpiry:
        return 'Near Expiry';
      case ExpiryStatus.safe:
        return 'Fresh';
    }
  }

  IconData get _statusIcon {
    switch (food.status) {
      case ExpiryStatus.expired:
        return Icons.cancel_rounded;
      case ExpiryStatus.nearExpiry:
        return Icons.access_time_rounded;
      case ExpiryStatus.safe:
        return Icons.check_circle_rounded;
    }
  }

  String get _daysLabel {
    final d = food.daysRemaining;
    if (d < 0) return '${d.abs()}d ago';
    if (d == 0) return 'Today!';
    if (d == 1) return '1 day left';
    return '$d days left';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  food.imageUrl != null && food.imageUrl!.isNotEmpty
                      ? Image.memory(
                          base64Decode(food.imageUrl!.split(',').last),
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _placeholder(),
                        )
                      : _placeholder(),

                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      children: [
                        if (onEdit != null)
                          GestureDetector(
                            onTap: onEdit,
                            child: Container(
                              width: 28,
                              height: 28,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),

                        if (onDelete != null)
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, color: Colors.white, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            _statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (food.category != null && food.category!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7F4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        food.category!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2D6A4F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],

                  Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B2E22),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _daysLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    const Map<String, IconData> categoryIcon = {
      'fruit': Icons.restaurant,
      'vegetable': Icons.eco,
      'dairy': Icons.egg_alt,
      'meat': Icons.set_meal,
      'seafood': Icons.set_meal,
      'beverage': Icons.local_drink,
      'snack': Icons.fastfood,
      'grain': Icons.grass,
    };

    final icon = food.category != null
        ? categoryIcon[food.category!.toLowerCase()] ?? Icons.fastfood
        : Icons.fastfood;

    return Container(
      height: 110,
      width: double.infinity,
      color: const Color(0xFFF0F7F4),
      child: Center(
        child: Icon(
          icon,
          size: 44,
          color: const Color(0xFF2D6A4F),
        ),
      ),
    );
  }
}