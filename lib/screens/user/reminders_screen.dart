import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class RemindersScreen extends StatefulWidget {
  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<Map<String, dynamic>> reminders = [
    {"medicine": "Panadol", "time": "08:00 AM", "status": "Taken", "days": "Daily"},
    {"medicine": "Brufen", "time": "02:00 PM", "status": "Pending", "days": "Mon, Wed, Fri"},
    {"medicine": "Augmentin", "time": "09:00 PM", "status": "Pending", "days": "Daily"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text("Medication Reminders", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                return _buildReminderCard(reminders[index], index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderBottomSheet(context),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Icon(Icons.alarm_on_rounded, size: 60, color: Colors.white),
          SizedBox(height: 15),
          Text(
            "Track Your Doses",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            "Stay on schedule and never miss a medicine.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder, int index) {
    bool isTaken = reminder['status'] == "Taken";
    return Container(
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
            decoration: BoxDecoration(
              color: (isTaken ? AppColors.secondary : Colors.orange).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTaken ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
              color: isTaken ? AppColors.secondary : Colors.orange,
              size: 28,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder['medicine'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(reminder['time'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    SizedBox(width: 12),
                    Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(reminder['days'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: isTaken,
            activeColor: AppColors.secondary,
            onChanged: (val) {
              setState(() {
                reminders[index]['status'] = val ? "Taken" : "Pending";
              });
            },
          ),
        ],
      ),
    );
  }

  void _showAddReminderBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(25, 25, 25, MediaQuery.of(context).viewInsets.bottom + 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add New Reminder", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(decoration: InputDecoration(hintText: "Medicine Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            SizedBox(height: 15),
            TextField(decoration: InputDecoration(hintText: "Time (e.g. 08:00 AM)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            SizedBox(height: 25),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text("Save Reminder", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}