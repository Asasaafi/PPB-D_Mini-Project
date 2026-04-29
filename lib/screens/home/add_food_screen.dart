import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/food_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  DateTime? _selectedDate;
  String? _selectedCategory;
  File? _imageFile;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const List<Map<String, String>> _categories = [
    {'label': 'Fruit', 'emoji': '🍎'},
    {'label': 'Vegetable', 'emoji': '🥦'},
    {'label': 'Dairy', 'emoji': '🧀'},
    {'label': 'Meat', 'emoji': '🥩'},
    {'label': 'Seafood', 'emoji': '🐟'},
    {'label': 'Beverage', 'emoji': '🥤'},
    {'label': 'Snack', 'emoji': '🍪'},
    {'label': 'Grain', 'emoji': '🌾'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF7F4EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Photo',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B2E22),
              ),
            ),
            const SizedBox(height: 20),

            _SourceTile(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              subtitle: 'Open camera',
              color: const Color(0xFF2D6A4F),
              onTap: () async {
                Navigator.pop(context);
                final file = await _storageService.pickFromCamera();
                if (file != null) setState(() => _imageFile = file);
              },
            ),

            const SizedBox(height: 12),

            _SourceTile(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              subtitle: 'Pick an existing photo',
              color: const Color(0xFF52B788),
              onTap: () async {
                Navigator.pop(context);
                final file = await _storageService.pickFromGallery();
                if (file != null) setState(() => _imageFile = file);
              },
            ),

            if (_imageFile != null) ...[
              const SizedBox(height: 12),
              _SourceTile(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                subtitle: 'Delete current photo',
                color: const Color(0xFFE63946),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imageFile = null);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D6A4F),
              onPrimary: Colors.white,
              surface: Color(0xFFF7F4EF),
            ),
            dialogBackgroundColor: const Color(0xFFF7F4EF),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter a food name.');
      return;
    }
    if (_selectedDate == null) {
      _showError('Please select an expiry date.');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showError('You must be logged in.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _storageService.uploadFoodImage(_imageFile!);
      }

      final food = FoodModel(
        id: '',
        name: name,
        expiryDate: _selectedDate!,
        imageUrl: imageUrl,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        category: _selectedCategory,
        dateAdded: DateTime.now(),
        userId: uid,
      );

      await _firestoreService.addFood(food);

      // Schedule notifikasi
      // Note: food.id masih '' karena baru saja dibuat,
      // idealnya Firestore service mengembalikan doc ID.
      // Untuk sekarang kita skip dulu, atau bisa extend FirestoreService.
      await NotificationService.scheduleForFood(food);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError('Failed to save. Please try again.');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFE63946),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Color(0xFF1B2E22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Add Food Item',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B2E22),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        _buildLabel('Food Photo'),
                        const SizedBox(height: 10),
                        _buildImagePicker(),

                        const SizedBox(height: 24),

                        _buildLabel('Food Name *'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hint: 'e.g. Fresh Milk, Spinach...',
                          icon: Icons.fastfood_rounded,
                        ),

                        const SizedBox(height: 24),

                        _buildLabel('Category'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((cat) {
                            final isSelected =
                                _selectedCategory == cat['label'];
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedCategory =
                                    isSelected ? null : cat['label'];
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2D6A4F)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2D6A4F)
                                        : Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF2D6A4F)
                                                .withOpacity(0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(cat['emoji']!,
                                        style:
                                            const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat['label']!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF1B2E22),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        _buildLabel('Expiry Date *'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Color(0xFF2D6A4F),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDate == null
                                      ? 'Select expiry date'
                                      : DateFormat('EEEE, d MMMM yyyy')
                                          .format(_selectedDate!),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _selectedDate == null
                                        ? Colors.grey.shade400
                                        : const Color(0xFF1B2E22),
                                    fontWeight: _selectedDate == null
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.chevron_right_rounded,
                                    color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        ),

                        if (_selectedDate != null) ...[
                          const SizedBox(height: 8),
                          _DatePreviewChip(date: _selectedDate!),
                        ],

                        const SizedBox(height: 24),

                        _buildLabel('Notes (optional)'),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _notesController,
                            maxLines: 3,
                            style: const TextStyle(
                                fontSize: 15, color: Color(0xFF1B2E22)),
                            decoration: InputDecoration(
                              hintText:
                                  'Storage tips, quantity, brand...',
                              hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 40),
                                child: Icon(Icons.notes_rounded,
                                    color: Color(0xFF2D6A4F), size: 20),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D6A4F),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF2D6A4F).withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Save Food Item',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _imageFile != null
                ? const Color(0xFF2D6A4F)
                : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _imageFile != null
            ? _buildImagePreview()
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            _imageFile!,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                'Tap to change photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5EE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.add_a_photo_rounded,
            size: 28,
            color: Color(0xFF2D6A4F),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Add Photo',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B2E22),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Camera or Gallery',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1B2E22),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style:
            const TextStyle(fontSize: 15, color: Color(0xFF1B2E22)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon:
              Icon(icon, color: const Color(0xFF2D6A4F), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B2E22),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DatePreviewChip extends StatelessWidget {
  final DateTime date;
  const _DatePreviewChip({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(date.year, date.month, date.day);
    final days = expiry.difference(today).inDays;

    Color color;
    String label;
    IconData icon;

    if (days < 0) {
      color = const Color(0xFFE63946);
      label = 'Already expired ${days.abs()} day(s) ago';
      icon = Icons.cancel_rounded;
    } else if (days == 0) {
      color = const Color(0xFFF4A261);
      label = 'Expires today!';
      icon = Icons.access_time_rounded;
    } else if (days <= 2) {
      color = const Color(0xFFF4A261);
      label = 'Expires in $days day(s) — Near expiry';
      icon = Icons.access_time_rounded;
    } else {
      color = const Color(0xFF2D6A4F);
      label = 'Expires in $days days — Fresh';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}