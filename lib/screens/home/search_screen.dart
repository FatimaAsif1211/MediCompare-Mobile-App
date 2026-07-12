import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../medicine/medicine_detail.dart';
import 'search_results.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  
  // Known categories for SearchResults
  final List<String> _categories = [
    "Pain Relief", "Antibiotics", "Heart Care", "Vitamins", "Diabetes",
    "Baby Care", "Skin Care", "Eye Care", "First Aid", "Stomach", "Popular Medicines"
  ];

  final List<String> _recentSearches = ["Panadol", "Brufen", "Augmentin", "Flagyl"];
  final List<String> _trendingSearches = ["Surbex-Z", "Arinac", "Disprin", "Gaviscon", "Ponstan"];

  void _navigateToProduct(String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineDetail(name: name),
      ),
    );
  }

  void _performSearch(String query) {
    String cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    // Check if the query matches a known category
    bool isCategory = _categories.any((c) => c.toLowerCase() == cleanQuery.toLowerCase());

    if (isCategory) {
      // Find the correctly capitalized category name
      String exactCategory = _categories.firstWhere((c) => c.toLowerCase() == cleanQuery.toLowerCase());
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchResults(query: exactCategory),
        ),
      );
    } else {
      // If not a category, treat it as a medicine search
      _navigateToProduct(cleanQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          "Quick Search",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar Section
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 25),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: "Search for medicines, generics...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear_rounded, color: Colors.grey),
                    onPressed: () => _controller.clear(),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // Recent Searches
                if (_recentSearches.isNotEmpty) ...[
                  _buildSectionHeader("Recent Searches", Icons.history_rounded),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _recentSearches.map((s) => _buildSearchChip(s)).toList(),
                  ),
                  SizedBox(height: 30),
                ],

                // Trending Searches
                _buildSectionHeader("Trending Now", Icons.trending_up_rounded),
                SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _trendingSearches.length,
                  itemBuilder: (context, index) {
                    return _buildTrendingItem(_trendingSearches[index]);
                  },
                ),
              ],
            ),
          ),

          // Search Button at bottom
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () => _performSearch(_controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              child: Text(
                "Search Now",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchChip(String label) {
    return GestureDetector(
      onTap: () => _navigateToProduct(label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          label,
          style: TextStyle(color: Colors.black87, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTrendingItem(String label) {
    return ListTile(
      onTap: () => _navigateToProduct(label),
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.north_east_rounded, size: 18, color: AppColors.primary),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
    );
  }
}
