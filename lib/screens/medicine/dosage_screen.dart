import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class DosageScreen extends StatelessWidget {
  final String medicineName;
  final dynamic dynamicDosage;

  DosageScreen({required this.medicineName, this.dynamicDosage});

  @override
  Widget build(BuildContext context) {
    String dosageInfo = "Follow physician's prescription exactly. Dose varies by age, weight, and condition. Information is being updated from clinical sources.";
    
    if (dynamicDosage != null) {
      if (dynamicDosage is String) {
        dosageInfo = dynamicDosage;
      } else if (dynamicDosage is List) {
        dosageInfo = dynamicDosage.join('\n');
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.secondary,
        title: Text("Dosage & Timing", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader("Guidelines", "Dosage summary for $medicineName"),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildDosageCard("Recommended Intake", dosageInfo, Icons.timer_rounded, AppColors.secondary),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber[800]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Do not self-medicate. All dosages are for informational purposes only.",
                            style: TextStyle(fontSize: 13, color: Colors.amber[900], fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Icon(Icons.timer_rounded, size: 60, color: Colors.white),
          SizedBox(height: 15),
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDosageCard(String group, String instructions, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 6),
                Text(instructions, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
