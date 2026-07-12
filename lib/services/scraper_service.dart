import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PriceResult {
  final String site;
  final String productName;
  final double? price;
  final String searchUrl;
  final String? productUrl;
  final String? imageUrl;

  PriceResult({
    required this.site,
    required this.productName,
    this.price,
    required this.searchUrl,
    this.productUrl,
    this.imageUrl,
  });

  String get launchUrl {
    String url = (productUrl != null && productUrl!.isNotEmpty) ? productUrl! : searchUrl;
    // Fix common URL issues
    url = url.trim();
    if (url.isEmpty) return 'https://www.google.com/search?q=$productName';
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    return url;
  }

  String get priceLabel => price != null ? "Rs. ${price!.toStringAsFixed(0)}" : "Check Site";

  factory PriceResult.fromJson(Map<String, dynamic> json, String medicine) {
    return PriceResult(
      site: json['site'] as String? ?? 'Pharmacy',
      productName: json['product_name'] as String? ?? medicine,
      price: (json['price'] as num?)?.toDouble(),
      searchUrl: json['search_url'] as String? ?? '',
      productUrl: json['product_url'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class ScraperService {
  static const String? backendUrl = 'https://medicompare-backend-production.up.railway.app';

  static final Map<String, String Function(String)> _searchUrls = {
    'DVAGO': (q) => 'https://dvago.pk/catalogsearch/result/?q=$q',
    'Dawaai': (q) => 'https://dawaai.pk/medicines?search=$q',
    'Clinix Pharmacy': (q) => 'https://clinix.pk/catalogsearch/result/?q=$q',
    'Servaid': (q) => 'https://servaid.com.pk/catalogsearch/result/?q=$q',
    "Fazal Din's": (q) => 'https://fazaldins.com.pk/catalogsearch/result/?q=$q',
    'Medical Store': (q) => 'https://www.medicalstore.com.pk/index.php?route=product/search&search=$q',
  };

  static Future<List<PriceResult>> scrapePrices(String medicineName) async {
    final encoded = Uri.encodeComponent(medicineName.trim());
    if (backendUrl != null) {
      try {
        final response = await http.get(Uri.parse('$backendUrl/scrape?q=$encoded')).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          return data.map((i) => PriceResult.fromJson(i, medicineName)).toList();
        }
      } catch (e) {
        debugPrint('Backend failed: $e');
      }
    }
    return _searchUrls.entries.map((e) => PriceResult(site: e.key, productName: medicineName, searchUrl: e.value(encoded))).toList();
  }

  static Future<void> launchPharmacySite(String url) async {
    debugPrint('[Scraper] Launching URL: $url');
    final Uri uri = Uri.parse(url);
    try {
      // Try external application mode first (usually opens Chrome/Safari)
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback to platform default
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('[Scraper] Error: $e');
      // If everything fails, try to launch as a string (legacy/fallback)
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}
