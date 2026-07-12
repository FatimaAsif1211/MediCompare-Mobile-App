import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../services/scraper_service.dart';

class PriceComparison extends StatefulWidget {
  final String medicineName;

  const PriceComparison({super.key, required this.medicineName});

  @override
  State<PriceComparison> createState() => _PriceComparisonState();
}

class _PriceComparisonState extends State<PriceComparison> {
  late Future<List<PriceResult>> _pricesFuture;

  @override
  void initState() {
    super.initState();
    _pricesFuture = ScraperService.scrapePrices(widget.medicineName);
  }

  void _handleLaunch(BuildContext context, String url) async {
    // Debug print to console to verify the tap is working
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
        title: const Text("Price Comparison",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(widget.medicineName),
          Expanded(
            child: FutureBuilder<List<PriceResult>>(
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

                // Filter results to show only those which have a price
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppColors.primary,
      child: Column(
        children: [
          Text(
            "Live prices for $name",
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          const Text(
            "Showing results with verified prices",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
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
      child: Material( // Material is required for InkWell ripple
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
