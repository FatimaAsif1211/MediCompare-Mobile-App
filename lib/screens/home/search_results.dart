import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';
import '../../widgets/medicine_card.dart';

class SearchResults extends StatelessWidget {
  final String query;
  final List<String>? categoryKeywords;

  const SearchResults({super.key, required this.query, this.categoryKeywords});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          query,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final allDocs = snapshot.data?.docs ?? [];
          
          // Filter documents locally based on keywords or direct query match
          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dbCategory = data['category']?.toString().toLowerCase() ?? "";
            
            if (categoryKeywords != null && categoryKeywords!.isNotEmpty) {
              return categoryKeywords!.any((keyword) => dbCategory.contains(keyword.toLowerCase()));
            }
            return dbCategory.contains(query.toLowerCase());
          }).toList();

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                color: AppColors.primary,
                child: Text(
                  filteredDocs.isEmpty
                      ? "No results found in $query"
                      : "Found ${filteredDocs.length} medicines in $query",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              Expanded(
                child: filteredDocs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final data = filteredDocs[index].data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MedicineCard(
                              name: data['medicine_name'] ?? data['name'] ?? 'Unknown',
                              price: data['price']?.toString() ?? 'N/A',
                              manufacturer: data['manufacturer']?.toString(),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No medicines found in this category",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
