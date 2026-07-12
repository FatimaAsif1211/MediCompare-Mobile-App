import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../services/scraper_service.dart';
import '../../widgets/custom_textfield.dart';

class SearchPriceScreen extends StatefulWidget {
  const SearchPriceScreen({super.key});

  @override
  State<SearchPriceScreen> createState() => _SearchPriceScreenState();
}

class _SearchPriceScreenState extends State<SearchPriceScreen> {
  final TextEditingController _controller = TextEditingController();
  Future<List<PriceResult>>? _pricesFuture;
  bool _hasSearched = false;

  void _handleSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _pricesFuture = ScraperService.scrapePrices(query);
        _hasSearched = true;
      });
    }
  }

  void _handleLaunch(BuildContext context, String url) async {
    debugPrint('DEBUG: Tapped on store. Launching URL: $url');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Redirecting to ${Uri.parse(url).host}..."),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
    
    await ScraperService.launchPharmacySite(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text("Search Medicine Prices",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: _hasSearched ? _buildResults() : _buildInitialState(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppColors.primary,
      child: Column(
        children: [
          CustomTextField(
            hintText: "Enter medicine name...",
            icon: Icons.search,
            controller: _controller,
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Text("Search Now", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            "Search for any medicine to compare live prices",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return FutureBuilder<List<PriceResult>>(
      future: _pricesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text("Searching pharmacies...", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No results found."));
        }

        final filteredPrices = snapshot.data!.where((p) => p.price != null).toList();

        if (filteredPrices.isEmpty) {
          return const Center(child: Text("No verified prices found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: filteredPrices.length,
          itemBuilder: (context, index) {
            return _buildPharmacyCard(context, filteredPrices[index]);
          },
        );
      },
    );
  }

  Widget _buildPharmacyCard(BuildContext context, PriceResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _handleLaunch(context, result.launchUrl),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: result.imageUrl != null && result.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            result.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.local_pharmacy_rounded,
                                    color: AppColors.primary, size: 28),
                          ),
                        )
                      : const Icon(Icons.local_pharmacy_rounded,
                          color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.site,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(result.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 4),
                      const Text("GO TO STORE", 
                        style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(result.priceLabel,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    const SizedBox(height: 5),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
