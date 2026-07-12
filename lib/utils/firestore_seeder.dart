import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class FirestoreSeeder {
  static Future<void> uploadMedicinesFromCsv() async {
    try {
      print('Starting Firestore Seeding...');
      // 1. Load the CSV file from assets
      final String csvData = await rootBundle.loadString('lib/csv/medicines.csv');

      // 2. Parse CSV
      List<List<dynamic>> rows = const CsvToListConverter().convert(csvData);

      if (rows.isEmpty) {
        print('CSV file is empty.');
        return;
      }

      // Extract headers (first row)
      List<String> headers = rows[0].map((e) => e.toString().trim()).toList();

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final CollectionReference medicinesRef = firestore.collection('medicines');

      // 3. Loop through rows (start from index 1 to skip headers)
      for (int i = 1; i < rows.length; i++) {
        Map<String, dynamic> data = {};

        for (int j = 0; j < headers.length; j++) {
          var value = rows[i][j];
          
          // Basic type conversion for Booleans
          if (value == "True" || value == "true") value = true;
          if (value == "False" || value == "false") value = false;
          
          data[headers[j]] = value;
        }

        // Use medicine_name as the document ID (normalized to lowercase for easier lookup)
        String medicineName = data['medicine_name'].toString().trim();
        String docId = medicineName.toLowerCase();
        
        await medicinesRef.doc(docId).set(data);
        print('Uploaded: $medicineName');
      }
      print('Database Seeding Completed Successfully!');
    } catch (e) {
      print('Error seeding database: $e');
    }
  }
}
