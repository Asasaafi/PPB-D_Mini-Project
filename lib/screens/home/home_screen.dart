import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/food_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/food_card.dart';
import 'edit_food_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  ExpiryStatus? _activeFilter;
  final _firestoreService = FirestoreService();
  late AnimationController _fabAnim;

  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  void _editFood(FoodModel food) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditFoodScreen(food: food)),
    );
  }

  Future<void> _deleteFood(FoodModel food) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF7F4EF),
        title: const Text(
          'Remove food?',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B2E22),
          ),
        ),
        content: Text(
          'Delete "${food.name}" from your list?',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7C72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B7C72))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE63946),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) await _firestoreService.deleteFood(food.id);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: SafeArea(
        child: StreamBuilder<List<FoodModel>>(
          stream: _firestoreService.getFoods(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF2D6A4F), strokeWidth: 2),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDED),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.warning_amber_rounded,
                            size: 36, color: Color(0xFFE63946)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFFE63946), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            final allFoods = snapshot.data ?? [];
            final expired = allFoods
                .where((f) => f.status == ExpiryStatus.expired)
                .length;
            final nearExpiry = allFoods
                .where((f) => f.status == ExpiryStatus.nearExpiry)
                .length;
            final safe =
                allFoods.where((f) => f.status == ExpiryStatus.safe).length;
            final filtered = _activeFilter == null
                ? allFoods
                : allFoods.where((f) => f.status == _activeFilter).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_greetingIcon(),
                                      size: 16,
                                      color: const Color(0xFF6B7C72)),
                                  const SizedBox(width: 5),
                                  Text(_greetingText(),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7C72))),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Your\nPantry',
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B2E22),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showProfileSheet(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D6A4F),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2D6A4F)
                                      .withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: _StatsBar(
                        expired: expired,
                        nearExpiry: nearExpiry,
                        safe: safe,
                        total: allFoods.length),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          count: allFoods.length,
                          color: const Color(0xFF2D6A4F),
                          isActive: _activeFilter == null,
                          onTap: () => setState(() => _activeFilter = null),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Fresh',
                          count: safe,
                          color: const Color(0xFF2D6A4F),
                          isActive: _activeFilter == ExpiryStatus.safe,
                          onTap: () => setState(
                              () => _activeFilter = ExpiryStatus.safe),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Near',
                          count: nearExpiry,
                          color: const Color(0xFFF4A261),
                          isActive: _activeFilter == ExpiryStatus.nearExpiry,
                          onTap: () => setState(
                              () => _activeFilter = ExpiryStatus.nearExpiry),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Expired',
                          count: expired,
                          color: const Color(0xFFE63946),
                          isActive: _activeFilter == ExpiryStatus.expired,
                          onTap: () => setState(
                              () => _activeFilter = ExpiryStatus.expired),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Text(
                      '${filtered.length} item${filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7C72)),
                    ),
                  ),
                ),

                filtered.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(hasFilter: _activeFilter != null),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final food = filtered[index];
                              return FoodCard(
                                food: food,
                                onTap: () => _editFood(food),
                                onEdit: () => _editFood(food),
                                onDelete: () => _deleteFood(food),
                              );
                            },
                            childCount: filtered.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.78,
                          ),
                        ),
                      ),
              ],
            );
          },
        ),
      ),

      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, 'add_food'),
          backgroundColor: const Color(0xFF2D6A4F),
          elevation: 4,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Add Food',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF7F4EF),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF2D6A4F).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 40, color: Color(0xFF2D6A4F)),
            ),
            const SizedBox(height: 12),
            Text(
              _user?.email ?? 'User',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B2E22)),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE63946),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  IconData _greetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    return Icons.nightlight_round;
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _StatsBar extends StatelessWidget {
  final int expired, nearExpiry, safe, total;
  const _StatsBar(
      {required this.expired,
      required this.nearExpiry,
      required this.safe,
      required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2D6A4F).withOpacity(0.28),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          _StatItem(label: 'Total', value: '$total', color: Colors.white),
          _divider(),
          _StatItem(
              label: 'Fresh',
              value: '$safe',
              color: const Color(0xFF95D5B2)),
          _divider(),
          _StatItem(
              label: 'Near',
              value: '$nearExpiry',
              color: const Color(0xFFFFD166)),
          _divider(),
          _StatItem(
              label: 'Expired',
              value: '$expired',
              color: const Color(0xFFFF6B6B)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withOpacity(0.2));
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.65),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive ? color : Colors.grey.shade200, width: 1.5),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? Colors.white
                        : const Color(0xFF6B7C72))),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.25)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF6B7C72))),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                hasFilter
                    ? Icons.search_off_rounded
                    : Icons.shopping_cart_outlined,
                size: 44,
                color: const Color(0xFF2D6A4F),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter ? 'No items found' : 'Your pantry is empty',
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B2E22),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'No food items match this filter.'
                  : 'Tap the button below to start\ntracking your food freshness.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF6B7C72), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}