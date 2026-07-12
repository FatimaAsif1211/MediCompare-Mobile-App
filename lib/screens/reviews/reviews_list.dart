import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class ReviewsList extends StatelessWidget {
  final List<Map<String, dynamic>> reviews = [
    {
      "name": "Ali Hassan",
      "rating": 5.0,
      "comment": "Very effective for my migraine. I switched to the generic version and it works exactly the same. Highly recommended for cost saving!",
      "date": "2 days ago",
      "avatar": Icons.person_rounded,
      "color": Colors.blue
    },
    {
      "name": "Sara Khan",
      "rating": 4.0,
      "comment": "Good results, but make sure to take it after a meal as it can cause slight acidity otherwise. Price is very reasonable.",
      "date": "1 week ago",
      "avatar": Icons.person_2_rounded,
      "color": Colors.pink
    },
    {
      "name": "Ahmed Raza",
      "rating": 3.0,
      "comment": "It's an average medicine. Took some time to show effects for my fever. The branded version seemed a bit faster for me personally.",
      "date": "2 weeks ago",
      "avatar": Icons.person_3_rounded,
      "color": Colors.green
    },
    {
      "name": "Zoya Malik",
      "rating": 5.0,
      "comment": "Great discovery! My pharmacist suggested this substitute and I'm saving so much money now. No side effects seen yet.",
      "date": "1 month ago",
      "avatar": Icons.person_4_rounded,
      "color": Colors.orange
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text("User Reviews", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(20),
              physics: BouncingScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                return _buildReviewCard(reviews[index]);
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
      color: AppColors.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Showing ${reviews.length} verified reviews",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Row(
            children: [
              Text("Sort by: ", style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text("Newest", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: review['color'].withOpacity(0.1),
                    child: Icon(review['avatar'], color: review['color'], size: 20),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['name'],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                      Text(
                        review['date'],
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(
                      review['rating'].toString(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(
            review['comment'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.thumb_up_off_alt_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 5),
              Text("Helpful", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              SizedBox(width: 20),
              Icon(Icons.flag_outlined, size: 16, color: Colors.grey),
              SizedBox(width: 5),
              Text("Report", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}