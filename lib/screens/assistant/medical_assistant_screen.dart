import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import '../medicine/medicine_detail.dart';
import '../comparison/price_comparison.dart';

class MedicalAssistantScreen extends StatefulWidget {
  const MedicalAssistantScreen({super.key});

  @override
  State<MedicalAssistantScreen> createState() => _MedicalAssistantScreenState();
}

class _MedicalAssistantScreenState extends State<MedicalAssistantScreen> {
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];
  bool _hasSearched = false;

  final List<String> _quickSymptoms = [
    "Headache", "Fever", "Heart Pain", "Stomach Ache", "Cold & Flu", 
    "Skin Allergy", "Muscle Pain", "Acidity", "Cough"
  ];

  // Mapping simple symptoms to more comprehensive search keywords for specific matching
  final Map<String, List<String>> _symptomToKeywords = {
    "Heart Pain": ["Cardiac", "Heart", "Chest Pain", "Hypertension", "Angina", "Blood Pressure", "Cardiovascular"],
    "Stomach Ache": ["Stomach", "Gastric", "Acidity", "Digestion", "Abdominal", "Antacid", "PPI", "Laxative", "Nausea", "Ulcer"],
    "Headache": ["Headache", "Migraine", "Pain Relief", "Analgesic", "Neurological"],
    "Fever": ["Fever", "Pyretic", "Cold", "Antipyretic", "Inflammation"],
    "Cold & Flu": ["Cold", "Flu", "Cough", "Congestion", "Nasal", "Antihistamine", "Respiratory"],
    "Muscle Pain": ["Muscle", "Body Ache", "Inflammation", "NSAID", "Joint Pain", "Spasm"],
    "Skin Allergy": ["Skin", "Allergy", "Itching", "Dermatitis", "Topical", "Rash", "Eczema"],
    "Acidity": ["Acidity", "Heartburn", "Gas", "Acid Reflux", "Indigestion", "Gastritis"],
    "Cough": ["Cough", "Throat", "Expectorant", "Dry Cough", "Bronchitis", "Phlegm"],
  };

  Future<void> _findMedicine({String? directSymptom}) async {
    final symptomText = directSymptom ?? _symptomsController.text;
    
    if (symptomText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter or select your symptoms")),
      );
      return;
    }

    if (directSymptom != null) {
      _symptomsController.text = directSymptom;
    }

    setState(() {
      _isLoading = true;
      _results = [];
      _hasSearched = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('medicines').get();
      final symptomsInput = symptomText.toLowerCase();
      
      // Build a list of keywords to search for
      List<String> searchKeywords = [];
      
      // Use mapped keywords if it's a quick selection
      if (_symptomToKeywords.containsKey(symptomText)) {
        searchKeywords.addAll(_symptomToKeywords[symptomText]!.map((e) => e.toLowerCase()));
      } else {
        // Smart split for manual input
        searchKeywords = symptomsInput.split(RegExp(r'[,\s]+')).where((e) => e.length > 2).toList();
        if (searchKeywords.isEmpty) searchKeywords.add(symptomsInput);
      }

      List<Map<String, dynamic>> matches = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final symptomsTreated = _ensureList(data['symptoms_treated']).map((e) => e.toLowerCase()).toList();
        final uses = _ensureList(data['uses']).map((e) => e.toLowerCase()).toList();
        final category = (data['category'] ?? "").toString().toLowerCase();
        final name = (data['medicine_name'] ?? data['name'] ?? "").toString().toLowerCase();
        
        double matchScore = 0;

        // Specific weighting for precision (e.g. Heart/Stomach)
        for (var keyword in searchKeywords) {
          if (category.contains(keyword)) matchScore += 5.0; // High weight for category
          if (symptomsTreated.any((s) => s.contains(keyword))) matchScore += 4.0;
          if (name.contains(keyword)) matchScore += 2.0;
          if (uses.any((u) => u.contains(keyword))) matchScore += 1.0;
        }

        if (matchScore > 0) {
          matches.add({...data, 'id': doc.id, 'matchScore': matchScore});
        }
      }

      // Sort by relevance score
      matches.sort((a, b) => (b['matchScore'] as double).compareTo(a['matchScore'] as double));

      setState(() {
        _results = matches;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error finding medicine: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _ensureList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return value.toString().split(RegExp(r'[,;\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCritical = _symptomsController.text == "Heart Pain";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Medical Assistant", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (isCritical) _buildCriticalWarning(),
            const SizedBox(height: 25),
            const Text(
              "What is your primary concern?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _quickSymptoms.map((symptom) => _buildSymptomChip(symptom)).toList(),
            ),
            const SizedBox(height: 25),
            const Text(
              "User Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              hintText: "Enter Age",
              icon: Icons.person_outline,
              controller: _ageController,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              hintText: "Or type symptoms (e.g. chest pain, acidity)",
              icon: Icons.medical_services_outlined,
              controller: _symptomsController,
            ),
            const SizedBox(height: 25),
            CustomButton(
              text: "Find Best Medicine",
              onPressed: () => _findMedicine(),
              isLoading: _isLoading,
            ),
            const SizedBox(height: 30),
            if (_hasSearched) ...[
              _buildResultsHeader(),
              const SizedBox(height: 15),
              if (_results.isEmpty && !_isLoading)
                _buildNoResults()
              else
                ..._results.map((med) => _buildMedicineResultCard(med)).toList(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 28),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "IMPORTANT: For chest/heart pain, please consult a doctor immediately. Do not self-medicate for severe conditions.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _results.isEmpty ? "No matches found" : "Best Matches",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            if (_results.isNotEmpty)
              Text(
                "Based on: ${_symptomsController.text}",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        if (_results.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: Text("${_results.length} found", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildSymptomChip(String label) {
    bool isSelected = _symptomsController.text == label;
    return GestureDetector(
      onTap: () => _findMedicine(directSymptom: label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForSymptom(label),
              size: 16,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForSymptom(String label) {
    switch (label) {
      case "Heart Pain": return Icons.favorite_rounded;
      case "Stomach Ache": return Icons.monitor_weight_rounded;
      case "Headache": return Icons.psychology_rounded;
      case "Fever": return Icons.thermostat_rounded;
      case "Acidity": return Icons.water_drop_rounded;
      case "Cold & Flu": return Icons.ac_unit_rounded;
      case "Skin Allergy": return Icons.face_rounded;
      case "Muscle Pain": return Icons.fitness_center_rounded;
      case "Cough": return Icons.record_voice_over_rounded;
      default: return Icons.healing_rounded;
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Smart Assistant",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  "Select a specific pain area or type symptoms for precision matching.",
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded, size: 50, color: Colors.grey[400]),
          ),
          const SizedBox(height: 15),
          Text("No matching medicines found.", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Try broad keywords like 'stomach' or 'pain'.", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMedicineResultCard(Map<String, dynamic> med) {
    final name = med['medicine_name'] ?? med['name'] ?? "Unknown";
    final category = med['category'] ?? "General";
    
    // Dosage logic based on age
    final int userAge = int.tryParse(_ageController.text) ?? 30;
    final dosage = (userAge < 12) ? (med['dosage_pediatric'] ?? med['dosage_adult'] ?? "N/A") : (med['dosage_adult'] ?? "N/A");
    
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(category, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineDetail(name: name)));
                },
                icon: Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 18),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          ),
          _buildDetailRow(Icons.description_outlined, "Uses", med['uses']),
          _buildDetailRow(Icons.timer_outlined, "Suggested Dosage", dosage),
          _buildDetailRow(Icons.warning_amber_rounded, "Side Effects", med['side_effects']),
          _buildDetailRow(Icons.error_outline_rounded, "Warnings", med['warnings']),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: "Compare Prices",
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PriceComparison(medicineName: name)));
                  },
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    String text = "N/A";
    if (value != null) {
      if (value is List) {
        text = value.join(", ");
      } else {
        text = value.toString();
      }
    }
    
    if (text.toLowerCase() == "n/a" || text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 14, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                children: [
                  TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  TextSpan(text: text, style: TextStyle(color: Colors.grey[800])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
