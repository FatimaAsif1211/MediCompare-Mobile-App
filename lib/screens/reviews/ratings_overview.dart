import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class RatingsOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.amber,
        title: Text("Ratings & Overview", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  _buildRatingCard(),
                  SizedBox(height: 25),
                  _buildDetailedBars(),
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
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Icon(Icons.stars_rounded, size: 60, color: Colors.white),
          SizedBox(height: 15),
          Text("Product Satisfaction", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text(
            "Based on verified user experiences and clinical ratings.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text("4.5", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black87)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => Icon(
              index < 4 ? Icons.star_rounded : Icons.star_half_rounded,
              color: Colors.amber,
              size: 28,
            )),
          ),
          SizedBox(height: 10),
          Text("Total 1.2k Ratings", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDetailedBars() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          _ratingBar("5 Star", 0.7, Colors.green),
          _ratingBar("4 Star", 0.2, Colors.lightGreen),
          _ratingBar("3 Star", 0.05, Colors.amber),
          _ratingBar("2 Star", 0.03, Colors.orange),
          _ratingBar("1 Star", 0.02, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _ratingBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[100],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
          SizedBox(width: 10),
          Text("${(value * 100).toInt()}%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}