import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../medicine/medicine_detail.dart';

class CabinetScreen extends StatefulWidget {
  @override
  _CabinetScreenState createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  final List<Map<String, String>> medicinesData = [
    {"name": "Panadol", "quantity": "20/30 tablets", "status": "In Stock"},
    {"name": "Brufen", "quantity": "5/20 tablets", "status": "Low Stock"},
    {"name": "Augmentin", "quantity": "14/14 tablets", "status": "In Stock"}
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedStatus = "In Stock";

  void _addMedicine() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add New Medicine",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Medicine Name",
                  prefixIcon: const Icon(Icons.medication_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                validator: (val) => val == null || val.isEmpty ? "Please enter name" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: "Quantity (e.g. 10 tablets)",
                  prefixIcon: const Icon(Icons.inventory_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                validator: (val) => val == null || val.isEmpty ? "Please enter quantity" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: "Stock Status",
                  prefixIcon: const Icon(Icons.info_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                items: ["In Stock", "Low Stock", "Out of Stock"]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedStatus = val!),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        medicinesData.add({
                          "name": _nameController.text,
                          "quantity": _quantityController.text,
                          "status": _selectedStatus,
                        });
                      });
                      _nameController.clear();
                      _quantityController.clear();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Medicine added successfully!"),
                          backgroundColor: AppColors.secondary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Add to Cabinet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text("Medicine Cabinet", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: medicinesData.isEmpty 
              ? const Center(child: Text("Cabinet is empty. Add some medicines!"))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: medicinesData.length,
                  itemBuilder: (context, index) {
                    return _buildCabinetCard(context, medicinesData[index]);
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMedicine,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Add Medicine", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_rounded, size: 60, color: Colors.white),
          const SizedBox(height: 15),
          const Text(
            "Your Digital Locker",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "You have ${medicinesData.length} medicines saved in your cabinet.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCabinetCard(BuildContext context, Map<String, String> med) {
    bool isLowStock = med['status'] == "Low Stock";
    bool isOutOfStock = med['status'] == "Out of Stock";
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineDetail(name: med['name']!)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(med['quantity']!, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isOutOfStock ? Colors.red : (isLowStock ? Colors.orange : AppColors.secondary)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                med['status']!,
                style: TextStyle(
                  color: isOutOfStock ? Colors.red : (isLowStock ? Colors.orange : AppColors.secondary),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
