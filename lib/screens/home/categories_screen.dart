import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';
import 'search_results.dart';

class FriendlyCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> keywords; // Keywords to match with 'category' field in DB

  FriendlyCategory(this.name, this.icon, this.color, this.keywords);
}

class CategoriesScreen extends StatelessWidget {
  CategoriesScreen({super.key});

  final List<FriendlyCategory> allFriendlyCategories = [
    FriendlyCategory("Pain Relief", Icons.healing_rounded, AppColors.accent, ["Analgesic", "NSAID", "Antipyretic", "Pain"]),
    FriendlyCategory("Antibiotics", Icons.local_pharmacy_rounded, Colors.teal, ["Antibiotic", "Anti-bacterial"]),
    FriendlyCategory("Heart Care", Icons.favorite_rounded, Colors.redAccent, ["Antihypertensive", "Cardiac", "Heart", "Antiplatelet", "Antihyperlipidemic", "Statin"]),
    FriendlyCategory("Vitamins", Icons.spa_rounded, AppColors.secondary, ["Vitamin", "Supplement", "Mineral", "Multivitamin"]),
    FriendlyCategory("Diabetes", Icons.water_drop_rounded, Colors.orangeAccent, ["Antidiabetic", "Diabetes"]),
    FriendlyCategory("Baby Care", Icons.child_care_rounded, Colors.blueAccent, ["Baby", "Children", "Infant", "Pediatric"]),
    FriendlyCategory("Skin Care", Icons.face_retouching_natural_rounded, Colors.pinkAccent, ["Skin", "Topical", "Dermatological", "Cream", "Ointment"]),
    FriendlyCategory("Eye Care", Icons.remove_red_eye_rounded, Colors.cyan, ["Eye", "Ophthalmic", "Drops"]),
    FriendlyCategory("First Aid", Icons.medical_services_rounded, Colors.red, ["First Aid", "Antiseptic"]),
    FriendlyCategory("Stomach", Icons.monitor_weight_rounded, Colors.brown, ["Stomach", "Antacid", "PPI", "Digestive", "Laxative", "Antidiarrheal", "Gastric", "Antispasmodic"]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          "All Categories",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Text(
              "Browse medicines by their health category to find exactly what you need.",
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState("No data available in database.");
                }

                // Get all categories currently present in the Firestore DB
                final List<String> dbCategories = snapshot.data!.docs
                    .map((doc) => (doc.data() as Map<String, dynamic>)['category']?.toString().toLowerCase() ?? "")
                    .toList();

                // Filter our friendly categories to ONLY show those that have matching medicines in the DB
                final List<FriendlyCategory> activeCategories = allFriendlyCategories.where((friendly) {
                  return dbCategories.any((dbCat) {
                    return friendly.keywords.any((keyword) => dbCat.contains(keyword.toLowerCase()));
                  });
                }).toList();

                if (activeCategories.isEmpty) {
                  return _buildEmptyState("No medicines found matching these categories.");
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: activeCategories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryCard(context, activeCategories[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, FriendlyCategory category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchResults(
              query: category.name,
              categoryKeywords: category.keywords,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: category.color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                size: 35,
                color: category.color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "View Items",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
