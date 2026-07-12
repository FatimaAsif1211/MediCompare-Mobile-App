import 'package:flutter/material.dart';
import '../../widgets/medicine_card.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favorites"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          MedicineCard(name: "Panadol", price: "120"),
          MedicineCard(name: "Brufen", price: "80"),
        ],
      ),
    );
  }
}