import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';
import '../../widgets/medicine_card.dart';
import '../home/search_screen.dart';
import '../home/categories_screen.dart';
import '../home/search_results.dart';
import '../comparison/compare_medicines.dart';
import '../comparison/best_deals.dart';
import '../comparison/search_price.dart';
import '../assistant/medical_assistant_screen.dart';
import '../profile/profile_screen.dart';
import '../user/reminders_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String? displayName;
  HomeScreen({super.key, this.displayName});

  final User? user = FirebaseAuth.instance.currentUser;

  // Friendly categories mapping with keywords to match technical DB categories
  final List<FriendlyCategory> friendlyCategories = [
    FriendlyCategory("Pain Relief", Icons.healing_rounded, AppColors.accent, ["Analgesic", "NSAID", "Antipyretic", "Pain"]),
    FriendlyCategory("Antibiotics", Icons.local_pharmacy_rounded, Colors.teal, ["Antibiotic", "Anti-bacterial"]),
    FriendlyCategory("Heart Care", Icons.favorite_rounded, Colors.redAccent, ["Antihypertensive", "Cardiac", "Heart", "Antiplatelet", "Antihyperlipidemic"]),
    FriendlyCategory("Vitamins", Icons.spa_rounded, AppColors.secondary, ["Vitamin", "Supplement", "Mineral", "Multivitamin"]),
    FriendlyCategory("Diabetes", Icons.water_drop_rounded, Colors.orangeAccent, ["Antidiabetic", "Diabetes"]),
    FriendlyCategory("Baby Care", Icons.child_care_rounded, Colors.blueAccent, ["Baby", "Children", "Infant", "Pediatric"]),
    FriendlyCategory("Skin Care", Icons.face_retouching_natural_rounded, Colors.pinkAccent, ["Skin", "Topical", "Dermatological"]),
    FriendlyCategory("Stomach", Icons.monitor_weight_rounded, Colors.brown, ["Stomach", "Antacid", "PPI", "Gastric", "Laxative"]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Health Categories", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CategoriesScreen()));
                  }),
                  const SizedBox(height: 15),
                  _buildDynamicCategoryList(context),
                  const SizedBox(height: 25),
                  _buildAssistantCard(context),
                  const SizedBox(height: 25),
                  _buildPromoCard(context),
                  const SizedBox(height: 30),
                  _buildSectionHeader("Popular Medicines", () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen()));
                  }),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('medicines').limit(15).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: CircularProgressIndicator(),
                )));
              }

              final docs = snapshot.data?.docs ?? [];
              
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MedicineCard(
                          name: data['medicine_name'] ?? data['name'] ?? 'Unknown',
                          price: data['price']?.toString() ?? 'N/A',
                          manufacturer: data['manufacturer']?.toString(),
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchScreen())),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.search, color: Colors.white),
        label: const Text("Search Medicines", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDynamicCategoryList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);

        final dbCategories = snapshot.data!.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['category']?.toString().toLowerCase() ?? "")
            .toList();

        // Only show friendly categories that have matches in the database
        final activeCategories = friendlyCategories.where((friendly) {
          return dbCategories.any((dbCat) => 
              friendly.keywords.any((kw) => dbCat.contains(kw.toLowerCase())));
        }).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: activeCategories.map((cat) => _buildCategoryItem(context, cat)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(BuildContext context, FriendlyCategory cat) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SearchResults(query: cat.name, categoryKeywords: cat.keywords),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: cat.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: cat.color.withOpacity(0.2), width: 1),
              ),
              child: Icon(cat.icon, color: cat.color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              cat.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    String nameToShow = displayName ?? user?.displayName ?? "User";
    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.sort_rounded, color: Colors.white, size: 30),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RemindersScreen())),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen())),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hello, $nameToShow", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Find your medicines at best prices", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        TextButton(onPressed: onSeeAll, child: const Text("See All", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildAssistantCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalAssistantScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 30),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Medical Assistant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 4),
                  Text("Enter symptoms for suggestions", style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.secondary, const Color(0xFF388E3C)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Generic Savings", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text("Save up to 80% on prescriptions with generic alternatives.", style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.savings_rounded, size: 60, color: Colors.white.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    String nameToShow = displayName ?? user?.displayName ?? "User";
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            accountName: Text(nameToShow),
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: AppColors.primary)),
          ),
          ListTile(leading: const Icon(Icons.home), title: const Text("Home"), onTap: () => Navigator.pop(context)),
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: AppColors.primary),
            title: const Text("Medical Assistant"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalAssistantScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.compare_arrows), 
            title: const Text("Compare"), 
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareMedicines()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.search_outlined), 
            title: const Text("Search Price"), 
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPriceScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_offer_outlined), 
            title: const Text("Best Deals"), 
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BestDeals()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red), 
            title: const Text("Logout"), 
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (_) => LoginScreen()), 
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class FriendlyCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  FriendlyCategory(this.name, this.icon, this.color, this.keywords);
}
