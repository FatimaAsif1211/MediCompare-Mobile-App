import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../services/scraper_service.dart';

class BestDeals extends StatefulWidget {
  final String? medicineName;
  final String? genericName;

  const BestDeals({super.key, this.medicineName, this.genericName});

  @override
  State<BestDeals> createState() => _BestDealsState();
}

class _BestDealsState extends State<BestDeals> {
  late Future<List<PriceResult>> _dealsFuture;

  @override
  void initState() {
    super.initState();
    _dealsFuture = _fetchTopDeals();
  }

  Future<List<PriceResult>> _fetchTopDeals() async {
    List<String> queries = [];
    
    // Prioritize the current medicine and its generic
    if (widget.medicineName != null && widget.medicineName!.isNotEmpty) {
      queries.add(widget.medicineName!);
    }
    
    if (widget.genericName != null && 
        widget.genericName != "N/A" && 
        !widget.genericName!.toLowerCase().contains("not available")) {
      queries.add(widget.genericName!);
    }
    
    // If no context provided (e.g., opened from a general menu), use popular items
    if (queries.isEmpty) {
      queries.addAll(["Panadol", "Brufen", "Augmentin", "Nexum"]);
    }
    
    List<PriceResult> allResults = [];
    
    try {
      // Scrape for all identified queries
      final List<List<PriceResult>> scrapedLists = await Future.wait(
        queries.map((name) => ScraperService.scrapePrices(name))
      );

      for (var list in scrapedLists) {
        allResults.addAll(list);
      }
      
      // Filter for results that actually have a price
      allResults = allResults.where((p) => p.price != null).toList();
      
      // Sort by price (ascending) to show the "Best Deals" first
      allResults.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
      
    } catch (e) {
      debugPrint("Error fetching best deals: $e");
    }
    
    // Return top 10 best deals
    return allResults.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    String headerText = widget.medicineName != null 
        ? "Finding the lowest prices for ${widget.medicineName} and its alternatives..."
        : "Searching for the best deals on popular medicines...";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.accent,
        title: const Text("Best Deals", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(headerText),
          Expanded(
            child: FutureBuilder<List<PriceResult>>(
              future: _dealsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.accent),
                        SizedBox(height: 20),
                        Text("Comparing prices across pharmacies...", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                
                final deals = snapshot.data ?? [];
                
                if (deals.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 20),
                          const Text(
                            "No live deals found at the moment.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: deals.length,
                  itemBuilder: (context, index) {
                    final deal = deals[index];
                    // We can label the first few as "Best Price" or "HOT"
                    String label = index == 0 ? "BEST PRICE" : "VERIFIED";
                    if (index == 0) {
                      return _dealCard(
                        deal.productName,
                        deal.priceLabel,
                        label,
                        deal.site,
                        true,
                        deal.launchUrl,
                      );
                    }
                    return _dealCard(
                      deal.productName,
                      deal.priceLabel,
                      label,
                      deal.site,
                      false,
                      deal.launchUrl,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppColors.accent,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
      ),
    );
  }

  Widget _dealCard(String name, String price, String label, String site, bool isHot, String url) {
    return GestureDetector(
      onTap: () => ScraperService.launchPharmacySite(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHot ? Colors.orange.withOpacity(0.1) : AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isHot ? Icons.whatshot_rounded : Icons.local_offer_rounded,
                color: isHot ? Colors.orange : AppColors.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    site,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isHot ? Colors.redAccent : Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isHot) ...[
                  const SizedBox(height: 8),
                  const Text("🔥 TOP DEAL", style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
