import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';
import 'uses_screen.dart';
import 'dosage_screen.dart';
import 'side_effects_screen.dart';
import 'warnings_screen.dart';
import '../comparison/price_comparison.dart';
import '../comparison/generic_vs_branded.dart';
import '../comparison/compare_medicines.dart';
import '../comparison/best_deals.dart';
import 'manufacturer_screen.dart';
import '../alternatives/generic_alternatives.dart';
import '../alternatives/substitute_medicines.dart';
import '../alternatives/savings_details.dart';
import '../reviews/ratings_overview.dart';
import '../reviews/write_review.dart';
import '../reviews/reviews_list.dart';

class MedicineDetail extends StatefulWidget {
  final String name;

  const MedicineDetail({super.key, required this.name});

  @override
  State<MedicineDetail> createState() => _MedicineDetailState();
}

class _MedicineDetailState extends State<MedicineDetail> {
  bool _isLoading = true;
  Map<String, dynamic>? _medicineData;

  @override
  void initState() {
    super.initState();
    _fetchMedicineDetails();
  }

  Future<void> _fetchMedicineDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('medicines')
          .doc(widget.name.toLowerCase())
          .get();

      if (doc.exists) {
        setState(() {
          _medicineData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching medicine details: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Truly robust helper to split by comma, semicolon, or newline
  // even if the value is already a list (common for CSV/Firestore imports).
  List<String> _ensureList(dynamic value) {
    if (value == null) return [];
    List<String> result = [];
    
    void processString(String str) {
      // Split by comma, semicolon, or newline
      final List<String> parts = str.split(RegExp(r'[,;\n]'));
      for (var part in parts) {
        String trimmed = part.trim();
        if (trimmed.isNotEmpty && trimmed.toLowerCase() != "n/a") {
          result.add(trimmed);
        }
      }
    }

    if (value is List) {
      for (var item in value) {
        if (item != null) {
          processString(item.toString());
        }
      }
    } else {
      processString(value.toString());
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> alternatives = _ensureList(_medicineData?['generic_alternatives']);
    final String genericName = _medicineData?['generic_name']?.toString() ?? "Formula details not available";
    final String manufacturer = _medicineData?['manufacturer']?.toString() ?? "N/A";
    
    final List<String> sideEffects = _ensureList(_medicineData?['side_effects']);
    final List<String> warnings = _ensureList(_medicineData?['warnings']);
    final List<String> uses = _ensureList(_medicineData?['uses']);
    final List<String> symptoms = _ensureList(_medicineData?['symptoms_treated']);
    final List<String> substitutes = _ensureList(_medicineData?['substitutes']);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 20),
                  Text(
                    "Searching for ${widget.name}...",
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainInfoCard(genericName),
                        const SizedBox(height: 25),
                        _buildSectionTitle("Medical Information"),
                        _buildOptionGrid(context, [
                          _Option(
                              "Uses",
                              Icons.healing_rounded,
                              AppColors.primary,
                              UsesScreen(
                                medicineName: widget.name,
                                dynamicUses: uses,
                                dynamicSymptoms: symptoms,
                              )),
                          _Option(
                              "Dosage",
                              Icons.timer_rounded,
                              AppColors.secondary,
                              DosageScreen(
                                medicineName: widget.name,
                                dynamicDosage: _medicineData?['dosage_adult'],
                              )),
                          _Option(
                              "Side Effects",
                              Icons.warning_amber_rounded,
                              Colors.orange,
                              SideEffectsScreen(
                                aiEffects: sideEffects.isEmpty ? ["N/A"] : sideEffects,
                              )),
                          _Option(
                              "Warnings",
                              Icons.error_outline_rounded,
                              Colors.redAccent,
                              WarningsScreen(
                                aiWarnings: warnings.isEmpty ? ["N/A"] : warnings,
                              )),
                          _Option(
                              "Manufacturer",
                              Icons.factory_rounded,
                              Colors.blueGrey,
                              ManufacturerScreen(
                                manufacturer: manufacturer,
                              )),
                        ]),
                        const SizedBox(height: 25),
                        _buildSectionTitle("Alternatives & Savings"),
                        _buildOptionList(context, [
                          _Option(
                            "Generic Alternatives",
                            Icons.auto_awesome_rounded,
                            AppColors.secondary,
                            GenericAlternatives(aiAlternatives: alternatives),
                            subtitle: "Same formula, lower price",
                          ),
                          _Option(
                            "Substitutes",
                            Icons.reorder_rounded,
                            Colors.purple,
                            SubstituteMedicines(aiSubstitutes: substitutes),
                            subtitle: "Other brands with similar effect",
                          ),
                          _Option(
                            "Savings Details", 
                            Icons.savings_rounded, 
                            AppColors.accent, 
                            SavingsDetails(
                              medicineName: widget.name,
                              genericName: genericName,
                            ), 
                            subtitle: "How much you can save today"
                          ),
                        ]),
                        const SizedBox(height: 25),
                        _buildSectionTitle("Comparison & Deals"),
                        _buildOptionList(context, [
                          _Option("Price Comparison", Icons.compare_arrows_rounded, AppColors.primary, PriceComparison(medicineName: widget.name), subtitle: "Find the lowest price near you"),
                          _Option(
                            "Generic vs Branded", 
                            Icons.swap_horiz_rounded, 
                            AppColors.secondary, 
                            GenericVsBranded(
                              brandName: widget.name,
                              genericName: genericName,
                            ), 
                            subtitle: "See the difference in cost"
                          ),
                          _Option("Compare Medicines", Icons.library_add_rounded, Colors.blue, CompareMedicines(initialMedicine: widget.name), subtitle: "Side-by-side comparison"),
                          _Option("Best Deals", Icons.local_offer_rounded, AppColors.accent, BestDeals(medicineName: widget.name, genericName: genericName), subtitle: "Exclusive discounts and offers"),
                        ]),
                        const SizedBox(height: 25),
                        _buildSectionTitle("Community & Reviews"),
                        _buildOptionGrid(context, [
                          _Option("Ratings", Icons.star_rounded, Colors.amber, RatingsOverview()),
                          _Option("Write Review", Icons.rate_review_rounded, Colors.blue, WriteReview()),
                          _Option("All Reviews", Icons.forum_rounded, AppColors.primary, ReviewsList()),
                        ]),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfoCard(String generic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication_rounded, size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: 15),
          Text(
            widget.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            generic,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 15),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "Category: ",
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              Text(
                _medicineData?['category']?.toString() ?? "N/A",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildOptionGrid(BuildContext context, List<_Option> options) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 0.9,
      children: options.map((opt) => _buildGridItem(context, opt)).toList(),
    );
  }

  Widget _buildGridItem(BuildContext context, _Option opt) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => opt.screen)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: opt.color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(opt.icon, color: opt.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              opt.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionList(BuildContext context, List<_Option> options) {
    return Column(
      children: options.map((opt) => _buildListItem(context, opt)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, _Option opt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => opt.screen)),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: opt.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(opt.icon, color: opt.color, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    if (opt.subtitle != null)
                      Text(opt.subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  _Option(this.title, this.icon, this.color, this.screen, {this.subtitle});
}
