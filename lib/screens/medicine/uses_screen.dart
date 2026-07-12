import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class UsesScreen extends StatelessWidget {
  final String medicineName;
  final dynamic dynamicUses;
  final dynamic dynamicSymptoms;

  UsesScreen({
    required this.medicineName,
    this.dynamicUses,
    this.dynamicSymptoms,
  });

  final Map<String, Map<String, dynamic>> medicineData = {
    "Panadol": {
      "header": "Pain & Fever Relief",
      "description": "Standard paracetamol based medication for common ailments.",
      "common_uses": [
        "Headaches and migraines.",
        "Reduction of fever (antipyretic).",
        "Toothaches and muscle pain.",
        "Cold and flu symptoms."
      ],
      "mechanism": [
        "Inhibits prostaglandin synthesis in the CNS.",
        "Acts on the hypothalamic heat-regulating center to reduce fever."
      ]
    },
  };

  @override
  Widget build(BuildContext context) {
    String header = "Medicine Information";
    String description = "Detailed uses and benefits for $medicineName.";
    List<String> commonUses = ["Information for this medicine is being updated."];
    List<String> mechanism = ["Please consult your doctor for medical advice."];

    final data = medicineData[medicineName];
    if (data != null) {
      header = data['header']?.toString() ?? header;
      description = data['description']?.toString() ?? description;

      if (data['common_uses'] is List) {
        List<String> mockUses = [];
        for (var item in (data['common_uses'] as List)) {
          if (item != null) mockUses.add(item.toString());
        }
        commonUses = mockUses;
      }

      if (data['mechanism'] is List) {
        List<String> mockMech = [];
        for (var item in (data['mechanism'] as List)) {
          if (item != null) mockMech.add(item.toString());
        }
        mechanism = mockMech;
      }
    }

    // Safely parse dynamicUses using a loop to avoid closure type inference errors
    if (dynamicUses != null) {
      List<String> parsedUses = [];
      if (dynamicUses is List) {
        for (var item in (dynamicUses as List)) {
          if (item != null) {
            String val = item.toString().trim();
            if (val.isNotEmpty) parsedUses.add(val);
          }
        }
      } else if (dynamicUses is String) {
        List<String> parts = dynamicUses.split(';');
        for (var part in parts) {
          String trimmed = part.trim();
          if (trimmed.isNotEmpty) {
            parsedUses.add(trimmed);
          }
        }
      }
      if (parsedUses.isNotEmpty) {
        commonUses = parsedUses;
      }
    }

    // Safely parse dynamicSymptoms
    if (dynamicSymptoms != null) {
      if (dynamicSymptoms is List) {
        description = "Commonly used for: ${(dynamicSymptoms as List).join(', ')}";
      } else {
        description = "Commonly used for: ${dynamicSymptoms.toString()}";
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text("Indications & Uses",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(header, description),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection("Common Uses", commonUses,
                      Icons.check_circle_outline_rounded, AppColors.primary),
                  const SizedBox(height: 25),
                  _buildSection("Mechanism of Action", mechanism,
                      Icons.info_outline_rounded, Colors.blue),
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
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Icon(Icons.healing_rounded, size: 60, color: Colors.white),
          const SizedBox(height: 15),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> points, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 15),
          ...points
              .map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: CircleAvatar(radius: 3, backgroundColor: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(point,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                    height: 1.4))),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}
