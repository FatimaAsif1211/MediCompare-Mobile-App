import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class GenericVsBranded extends StatelessWidget {
  final String? brandName;
  final String? genericName;

  GenericVsBranded({this.brandName, this.genericName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text("Generic vs Branded", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildComparisonCard(
                    "Selected Brand", 
                    brandName ?? "Current Medicine", 
                    "Market Price", 
                    Colors.redAccent, 
                    "Proprietary Brand", 
                    Icons.branding_watermark_rounded
                  ),
                  SizedBox(height: 10),
                  Center(child: Icon(Icons.swap_vert_circle_rounded, color: Colors.grey[400], size: 40)),
                  SizedBox(height: 10),
                  _buildComparisonCard(
                    "Generic Formula", 
                    genericName ?? "Loading Formula...", 
                    "Lower Cost", 
                    AppColors.secondary, 
                    "Active Ingredient", 
                    Icons.science_rounded
                  ),
                  
                  SizedBox(height: 30),
                  
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.orange, Colors.orangeAccent]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        Text("ESTIMATED SAVINGS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 5),
                        Text("Up to 70%", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
                        Text("By switching to generics", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 25),
                  _buildFactSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      color: AppColors.primary,
      child: Text(
        "Compare the clinical equivalence between branded and generic versions.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
      ),
    );
  }

  Widget _buildComparisonCard(String type, String name, String priceLabel, Color color, String sub, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(sub, style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Text(priceLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildFactSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.blue),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              "Generic medicines contain the same active ingredients and are bio-equivalent to their branded counterparts.",
              style: TextStyle(color: Colors.blue[800], fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
