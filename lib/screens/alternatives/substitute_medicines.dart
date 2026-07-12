import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../comparison/price_comparison.dart';

class SubstituteMedicines extends StatelessWidget {
  final List<String>? aiSubstitutes;

  SubstituteMedicines({this.aiSubstitutes});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> displayItems = aiSubstitutes != null
        ? aiSubstitutes!.map((name) => {
            "name": name,
            "price": "---",
            "manufacturer": "Local Pharma"
          }).toList()
        : [
            {"name": "Calpol", "price": "100", "manufacturer": "GSK"},
            {"name": "Disprin", "price": "40", "manufacturer": "Reckitt"},
            {"name": "Panamax", "price": "95", "manufacturer": "Sanofi"},
            {"name": "Paracetamol (Generic)", "price": "15", "manufacturer": "Local Labs"},
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        title: Text("Substitute Medicines", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                return _buildSubstituteCard(context, item);
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
      color: Colors.purple,
      child: Text(
        "AI-suggested brands and variations that provide the same therapeutic effect.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
      ),
    );
  }

  Widget _buildSubstituteCard(BuildContext context, Map<String, String> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PriceComparison(medicineName: item["name"]!),
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
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.swap_horiz_rounded, color: Colors.purple, size: 28),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item["name"]!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(item["manufacturer"]!, style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
