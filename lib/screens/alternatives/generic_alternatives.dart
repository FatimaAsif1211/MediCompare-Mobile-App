import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../comparison/price_comparison.dart';

class GenericAlternatives extends StatelessWidget {
  final List<String>? aiAlternatives;

  GenericAlternatives({this.aiAlternatives});

  @override
  Widget build(BuildContext context) {
    // If we have AI data, we use it. Otherwise, we show dummy data.
    final List<Map<String, dynamic>> displayItems = aiAlternatives != null
        ? aiAlternatives!.map((name) => {
            "name": name,
            "price": "---",
            "saving": "Variable",
            "manufacturer": "Local Manufacturer"
          }).toList()
        : [
            {"name": "Paracetamol", "price": "15", "saving": "87%", "manufacturer": "Local Labs"},
            {"name": "Ibuprofen", "price": "25", "saving": "69%", "manufacturer": "Generic Pharma"},
            {"name": "Amoxicillin", "price": "120", "saving": "60%", "manufacturer": "BioMed"},
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.secondary,
        title: Text("Generic Alternatives", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(20),
              physics: BouncingScrollPhysics(),
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                var item = displayItems[index];
                return _buildAlternativeCard(context, item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      color: AppColors.secondary,
      child: Text(
        "Save money with these versions containing the same active ingredients, suggested by AI.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
      ),
    );
  }

  Widget _buildAlternativeCard(BuildContext context, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PriceComparison(medicineName: item["name"]),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 28),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item["name"], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(item["manufacturer"], style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
              child: Text(item["saving"] == "Variable" ? "Switch" : "Save ${item["saving"]}", 
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
