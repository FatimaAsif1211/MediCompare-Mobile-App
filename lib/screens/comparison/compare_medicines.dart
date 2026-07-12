import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';

class CompareMedicines extends StatefulWidget {
  final String? initialMedicine;

  const CompareMedicines({super.key, this.initialMedicine});

  @override
  State<CompareMedicines> createState() => _CompareMedicinesState();
}

class _CompareMedicinesState extends State<CompareMedicines> {
  String medicine1 = "";
  String medicine2 = "";
  
  Map<String, dynamic>? _medicine1Data;
  Map<String, dynamic>? _medicine2Data;
  bool _isLoading = true;
  List<String> medicineList = [];

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('medicines').get();
      final names = snapshot.docs.map((doc) {
        final data = doc.data();
        return (data['medicine_name'] ?? data['name'] ?? doc.id).toString();
      }).toList();
      
      setState(() {
        medicineList = names..sort();
        
        // Set initial values
        if (widget.initialMedicine != null && medicineList.contains(widget.initialMedicine)) {
          medicine1 = widget.initialMedicine!;
        } else if (medicineList.isNotEmpty) {
          medicine1 = medicineList.first;
        }

        if (medicineList.length > 1) {
          medicine2 = medicineList.firstWhere((name) => name != medicine1, orElse: () => medicineList[1]);
        } else if (medicineList.isNotEmpty) {
          medicine2 = medicineList.first;
        }
      });
      
      if (medicine1.isNotEmpty && medicine2.isNotEmpty) {
        await _fetchComparison();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading medicines: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _getMedicineData(String name) async {
    // Try by ID first (lowercase)
    var doc = await FirebaseFirestore.instance
        .collection('medicines')
        .doc(name.toLowerCase())
        .get();
    
    if (doc.exists) return doc.data();

    // Try by querying the name field if ID match fails
    var query = await FirebaseFirestore.instance
        .collection('medicines')
        .where('medicine_name', isEqualTo: name)
        .limit(1)
        .get();
    
    if (query.docs.isNotEmpty) return query.docs.first.data();

    query = await FirebaseFirestore.instance
        .collection('medicines')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
        
    if (query.docs.isNotEmpty) return query.docs.first.data();
    
    return null;
  }

  Future<void> _fetchComparison() async {
    setState(() => _isLoading = true);
    try {
      final data1 = await _getMedicineData(medicine1);
      final data2 = await _getMedicineData(medicine2);

      setState(() {
        _medicine1Data = data1;
        _medicine2Data = data2;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching comparison: $e");
      setState(() => _isLoading = false);
    }
  }

  String _getValue(Map<String, dynamic>? data, String key) {
    if (data == null) return "N/A";
    var val = data[key];
    if (val == null) return "N/A";
    
    if (val is List) {
      return val.where((e) => e != null && e.toString().toLowerCase() != "n/a").join(", ");
    }
    
    String str = val.toString();
    return str.toLowerCase() == "n/a" ? "N/A" : str;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text("Compare Medicines", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSelectionHeader(),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (medicineList.isEmpty)
             const Expanded(child: Center(child: Text("No medicines found in database.")))
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildComparisonSection("General Info", [
                      _ComparisonRow("Brand Name", medicine1, medicine2),
                      _ComparisonRow("Generic Name", 
                        _getValue(_medicine1Data, 'generic_name'), 
                        _getValue(_medicine2Data, 'generic_name')),
                      _ComparisonRow("Manufacturer", 
                        _getValue(_medicine1Data, 'manufacturer'), 
                        _getValue(_medicine2Data, 'manufacturer')),
                      _ComparisonRow("Category", 
                        _getValue(_medicine1Data, 'category'), 
                        _getValue(_medicine2Data, 'category')),
                    ]),
                    const SizedBox(height: 20),
                    _buildComparisonSection("Clinical Details", [
                      _ComparisonRow("Uses", 
                        _getValue(_medicine1Data, 'uses'), 
                        _getValue(_medicine2Data, 'uses')),
                      _ComparisonRow("Side Effects", 
                        _getValue(_medicine1Data, 'side_effects'), 
                        _getValue(_medicine2Data, 'side_effects')),
                      _ComparisonRow("Dosage", 
                        _getValue(_medicine1Data, 'dosage_adult'), 
                        _getValue(_medicine2Data, 'dosage_adult')),
                    ]),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          const Divider(height: 1),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildSelectionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.primary,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDropdown(medicine1, (val) {
                if (val != null && val != medicine1) {
                  setState(() => medicine1 = val);
                  _fetchComparison();
                }
              })),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.compare_arrows_rounded, color: Colors.white70),
              ),
              Expanded(child: _buildDropdown(medicine2, (val) {
                if (val != null && val != medicine2) {
                  setState(() => medicine2 = val);
                  _fetchComparison();
                }
              })),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Side-by-side clinical comparison from database",
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String current, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current.isEmpty && medicineList.isNotEmpty ? medicineList.first : current,
          isExpanded: true,
          dropdownColor: AppColors.primary,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          items: medicineList.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value, overflow: TextOverflow.ellipsis));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String value1;
  final String value2;

  const _ComparisonRow(this.label, this.value1, this.value2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(value1, style: const TextStyle(fontSize: 14, color: Colors.black87))),
              const SizedBox(width: 16),
              Expanded(child: Text(value2, style: const TextStyle(fontSize: 14, color: Colors.black87))),
            ],
          ),
        ],
      ),
    );
  }
}
