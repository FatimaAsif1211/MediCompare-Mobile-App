import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class SavingsDetails extends StatelessWidget {
  final String? medicineName;
  final String? genericName;

  SavingsDetails({this.medicineName, this.genericName});

  @override
  Widget build(BuildContext context) {
    // These would ideally come from a pricing service or the AI
    // For now, we use realistic placeholders if AI data is present
    bool hasData = medicineName != null;
    int branded = hasData ? 150 : 120;
    int generic = hasData ? 45 : 15;
    int saving = branded - generic;
    double percentage = (saving / branded) * 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.accent,
        title: Text("Savings Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(saving, medicineName ?? "this medicine"),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildComparisonTable(branded, generic, medicineName, genericName),
                  SizedBox(height: 25),
                  _buildSavingBreakdown(saving, percentage),
                  SizedBox(height: 25),
                  _buildAdviceCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int saving, String name) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Icon(Icons.savings_rounded, size: 60, color: Colors.white),
          SizedBox(height: 15),
          Text("Smart Savings", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text(
            "By choosing generic alternatives for $name, you could save approximately Rs. $saving per pack.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(int branded, int generic, String? bName, String? gName) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          _buildPriceRow(bName ?? "Branded Price", branded, Colors.redAccent),
          Divider(height: 30),
          _buildPriceRow(gName ?? "Generic Price", generic, AppColors.secondary),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label, 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text("Rs. $value", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSavingBreakdown(int saving, double percentage) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green, Colors.lightGreen]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat("${percentage.toStringAsFixed(0)}%", "Percentage"),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStat("Rs. $saving", "Total Saved"),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildAdviceCard() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        "Generic medicines provide the same quality and efficacy at a fraction of the cost. Always confirm with your pharmacist before switching brands.",
        style: TextStyle(fontSize: 13, color: Colors.blue[800], height: 1.4),
        textAlign: TextAlign.center,
      ),
    );
  }
}
