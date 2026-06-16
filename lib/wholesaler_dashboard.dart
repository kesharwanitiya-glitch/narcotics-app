import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'inward_page.dart';
import 'login_screen.dart';
import 'outward_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_page.dart';
import 'main.dart';

class WholesalerDashboard extends StatefulWidget {
   final int userId;
  final String wholesalerName;
  final String wholesalerEmail;
   final String wholesalerGstin;
   final String wholesalerLicense;
   final String wholesalerPhone;

  const WholesalerDashboard({
    super.key,
    required this.userId,
    required this.wholesalerName, 
    required this.wholesalerEmail,
     required this.wholesalerGstin,
      required this.wholesalerLicense,
      required this.wholesalerPhone,
  });

  @override
  State<WholesalerDashboard> createState() => _WholesalerDashboardState();
}

class _WholesalerDashboardState extends State<WholesalerDashboard> {
  String currentView = 'Home';

  final mNameCtrl = TextEditingController();
  final mAddressCtrl = TextEditingController();
  final mPhoneCtrl = TextEditingController();
  final mEmailCtrl = TextEditingController();
  final mWebsiteCtrl = TextEditingController();
  final mLicenseCtrl = TextEditingController();
  final mGstinCtrl = TextEditingController();

  final dBrandIdCtrl = TextEditingController();
  final dGtinCtrl = TextEditingController();
  final dBrandNameCtrl = TextEditingController();
  final dStrengthCtrl = TextEditingController();
  final newSaltCtrl = TextEditingController(); 

  final TextEditingController drugSearchCtrl = TextEditingController();
String drugSearch = '';
  
  String selectedGenericName = 'Alprazolam';
  String selectedPackagingType = 'Strip';

  final List<String> genericNarcoticsList = [
    'Alprazolam', 'Buprenorphine', 'Codeine', 'Nitrazepam', 'Tramadol',
    'Pentazocine', 'Ketamine', 'Diazepam', 'Clonazepam', 'Opioids', '➕ Add New Drug Salt'
  ];

  List<dynamic> masterDrugsList = [];
  bool isLoadingDrugs = false;

  Future<void> fetchMasterDrugs() async {
    setState(() { isLoadingDrugs = true; });
    final url = Uri.parse('http://10.0.2.2:5000/get-all-drugs');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() { masterDrugsList = jsonDecode(response.body); isLoadingDrugs = false; });
      } else {
        setState(() { isLoadingDrugs = false; });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Failed to sync logs from DB backend."), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      setState(() { isLoadingDrugs = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Connection error while fetching master list."), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> saveManufacturer() async {
    final url = Uri.parse('http://10.0.2.2:5000/add-manufacturer');
    final String name = mNameCtrl.text.trim();
    final String address = mAddressCtrl.text.trim();
    final String phone = mPhoneCtrl.text.trim();
    final String email = mEmailCtrl.text.trim();
    final String website = mWebsiteCtrl.text.trim();
    final String license = mLicenseCtrl.text.trim().toUpperCase();
    final String gstin = mGstinCtrl.text.trim().toUpperCase();

    if (name.isEmpty || address.isEmpty || phone.isEmpty || email.isEmpty || license.isEmpty || gstin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Please fill all mandatory fields!"), backgroundColor: Colors.orangeAccent, behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      final response = await http.post(url, headers: {"Content-Type": "application/json"},
        body: jsonEncode({"wholesaler_email": widget.wholesalerEmail, "name": name, "address": address, "phone": phone, "email": email, "website": website, "license_no": license, "gstin": gstin}));
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎉 Manufacturer Registered Successfully!"), backgroundColor: Colors.indigo, behavior: SnackBarBehavior.floating));
        mNameCtrl.clear(); mAddressCtrl.clear(); mPhoneCtrl.clear(); mEmailCtrl.clear(); mWebsiteCtrl.clear(); mLicenseCtrl.clear(); mGstinCtrl.clear();
        setState(() { currentView = 'Home'; });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${responseData['message']}"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection timeout with backend node architecture."), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> saveDrugMaster() async {
    final url = Uri.parse('http://10.0.2.2:5000/add-drug-master');
    final String gtin = dGtinCtrl.text.trim();
    final String brandName = dBrandNameCtrl.text.trim();
    final String strength = dStrengthCtrl.text.trim();
    final String brandId = dBrandIdCtrl.text.trim();

    if (brandId.isEmpty || gtin.isEmpty || brandName.isEmpty || strength.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Please fill all drug specification fields!"), backgroundColor: Colors.orangeAccent, behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      final response = await http.post(url, headers: {"Content-Type": "application/json"},
        body: jsonEncode({"brand_id": brandId, "gtin": gtin, "generic_name": selectedGenericName, "brand_name": brandName, "strength": strength, "packaging_type": selectedPackagingType, "added_by": widget.wholesalerEmail}));
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎉 Drug Successfully Configured in Master Catalog!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        dBrandIdCtrl.clear(); dGtinCtrl.clear(); dBrandNameCtrl.clear(); dStrengthCtrl.clear();
        setState(() { currentView = 'Home'; });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${responseData['message']}"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection failure with backend server schema."), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> updateDrugMaster(String gtin, String generic, String brand, String strength, String packaging) async {
    final url = Uri.parse('http://10.0.2.2:5000/update-drug-master');
    try {
      final response = await http.put(url, headers: {"Content-Type": "application/json"},
        body: jsonEncode({"gtin": gtin, "generic_name": generic, "brand_name": brand, "strength": strength, "packaging_type": packaging, "added_by": widget.wholesalerEmail}));
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✏️ Catalog Details Updated Successfully!"), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
        fetchMasterDrugs(); 
      } else {
        final responseData = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${responseData['message']}"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection failure during update."), behavior: SnackBarBehavior.floating));
    }
  }

  void _showEditDrugDialog(Map<String, dynamic> drug) {
    final editBrandCtrl = TextEditingController(text: drug['drug_name'] ?? drug['brand_name']);
    final editStrengthCtrl = TextEditingController(text: drug['strength']);
    String editGeneric = drug['generic_name'] ?? 'Alprazolam';
    String editPackaging = drug['packaging_type'] ?? 'Strip';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)]),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                      ),
                      child: Row(children: [
                        const CircleAvatar(radius: 18, backgroundColor: Colors.white24, child: Icon(Icons.edit_note_rounded, color: Colors.white, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("Edit Drug Specifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("GTIN: ${drug['gtin']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ])),
                      ]),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        _styledDropdown<String>(label: "Salt Composition", icon: Icons.science_rounded,
                          value: genericNarcoticsList.contains(editGeneric) ? editGeneric : genericNarcoticsList.first,
                          items: genericNarcoticsList.where((e) => !e.contains('➕')).map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                          onChanged: (v) => setDialogState(() => editGeneric = v!)),
                        const SizedBox(height: 14),
                        _styledTextField(controller: editBrandCtrl, label: "Brand Name", icon: Icons.bookmark_added_rounded),
                        const SizedBox(height: 14),
                        _styledTextField(controller: editStrengthCtrl, label: "Strength", icon: Icons.monitor_weight_rounded),
                        const SizedBox(height: 14),
                        _styledDropdown<String>(label: "Packaging Type", icon: Icons.layers_rounded,
                          value: ['Strip', 'Box', 'Vial / Injection'].contains(editPackaging) ? editPackaging : 'Strip',
                          items: ['Strip', 'Box', 'Vial / Injection'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                          onChanged: (v) => setDialogState(() => editPackaging = v!)),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFF3949AB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text("CANCEL", style: TextStyle(color: Color(0xFF3949AB), fontWeight: FontWeight.bold)))),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: const Color(0xFF3949AB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                          onPressed: () { Navigator.pop(context); updateDrugMaster(drug['gtin'], editGeneric, editBrandCtrl.text.trim(), editStrengthCtrl.text.trim(), editPackaging); },
                          child: const Text("UPDATE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                      ]),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showAddCustomSaltDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)]),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: const Row(children: [
                  CircleAvatar(radius: 18, backgroundColor: Colors.white24, child: Icon(Icons.science_rounded, color: Colors.white, size: 20)),
                  SizedBox(width: 12),
                  Text("Add New Narcotic Salt", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ),
              Padding(padding: const EdgeInsets.all(20),
                child: _styledTextField(controller: newSaltCtrl, label: "Chemical Composition / Salt Name", icon: Icons.biotech_rounded, hint: "e.g., Morphine", capitalization: TextCapitalization.words)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () { newSaltCtrl.clear(); Navigator.pop(context); setState(() { selectedGenericName = genericNarcoticsList.first; }); },
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFF3949AB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text("CANCEL", style: TextStyle(color: Color(0xFF3949AB), fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: const Color(0xFF3949AB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                    onPressed: () {
                      String inputSalt = newSaltCtrl.text.trim();
                      if (inputSalt.isNotEmpty) {
                        if (!genericNarcoticsList.contains(inputSalt)) { setState(() { genericNarcoticsList.insert(genericNarcoticsList.length - 1, inputSalt); selectedGenericName = inputSalt; }); }
                        else { setState(() { selectedGenericName = inputSalt; }); }
                        newSaltCtrl.clear(); Navigator.pop(context);
                      }
                    },
                    child: const Text("ADD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  // ─── HELPER WIDGETS ───────────────────────────────────────────────────────────

  Widget _styledTextField({
    required TextEditingController controller, required String label, required IconData icon,
    String? hint, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters,
    int maxLines = 1, String? prefixText, TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller, keyboardType: keyboardType, inputFormatters: inputFormatters,
      maxLines: maxLines, textCapitalization: capitalization,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label, hintText: hint, prefixText: prefixText,
        prefixIcon: Icon(icon, color: const Color(0xFF3949AB), size: 20),
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        filled: true, fillColor: const Color(0xFFF8F9FF),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E4F0), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3949AB), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _styledDropdown<T>({
    required String label, required IconData icon, required T value,
    required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF3949AB), size: 20),
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        filled: true, fillColor: const Color(0xFFF8F9FF),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E4F0), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3949AB), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items, onChanged: onChanged,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 6),
      child: Row(children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF3949AB), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF3949AB), letterSpacing: 0.5)),
      ]),
    );
  }

  @override
  void dispose() {
    mNameCtrl.dispose(); mAddressCtrl.dispose(); mPhoneCtrl.dispose(); mEmailCtrl.dispose(); mWebsiteCtrl.dispose(); mLicenseCtrl.dispose(); mGstinCtrl.dispose();
    dGtinCtrl.dispose(); dBrandNameCtrl.dispose(); dStrengthCtrl.dispose(); newSaltCtrl.dispose(); dBrandIdCtrl.dispose();  drugSearchCtrl.dispose();
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    String appTitle = "Wholesaler Portal";
    if (currentView == 'AddManufacturer') appTitle = "Add Manufacturer";
    if (currentView == 'AddDrugs') appTitle = "Add Drug Master";
    if (currentView == 'DrugList') appTitle = "Drug Catalog";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(appTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
  IconButton(
    icon: const Icon(Icons.logout),
    onPressed: () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.clear();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (route) => false,
      );
    },
  ),
],
      ),

      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF283593), Color(0xFF3949AB), Color(0xFF5C6BC0)]),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.business_center_rounded, size: 32, color: Colors.white)),
              const SizedBox(height: 14),
              Text(widget.wholesalerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
              const SizedBox(height: 3),
              Text(widget.wholesalerEmail, style: const TextStyle(color: Colors.white60, fontSize: 12), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white30)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 13),
                  SizedBox(width: 5),
                  Text("Verified Wholesaler", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 10),

Align(
  alignment: Alignment.centerRight,
  child: InkWell(
    onTap: () async {

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfilePage(
            userId: widget.userId,
            name: widget.wholesalerName,
            email: widget.wholesalerEmail,
            phone: widget.wholesalerPhone,
            license: widget.wholesalerLicense,
          ),
        ),
      );

      if (result == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AutoLoginScreen(),
          ),
        );
      }
    },
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.edit,
        color: Colors.white,
        size: 18,
      ),
    ),
  ),
),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 6, top: 4),
                  child: Text("NAVIGATION", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF9E9E9E), letterSpacing: 1.2)),
                ),
                _drawerItem(icon: Icons.dashboard_rounded, label: "Dashboard Home", isSelected: currentView == 'Home', onTap: () { setState(() { currentView = 'Home'; }); Navigator.pop(context); }),
                _drawerItem(icon: Icons.add_business_rounded, label: "Add Manufacturer", isSelected: currentView == 'AddManufacturer', onTap: () { setState(() { currentView = 'AddManufacturer'; }); Navigator.pop(context); }),
                _drawerItem(icon: Icons.add_circle_outline_rounded, label: "Add Drug Master", isSelected: currentView == 'AddDrugs', onTap: () { setState(() { currentView = 'AddDrugs'; }); Navigator.pop(context); }),
                _drawerItem(icon: Icons.medication_liquid_rounded, label: "Drug Catalog", isSelected: currentView == 'DrugList',
                  onTap: () { setState(() { currentView = 'DrugList'; }); Navigator.pop(context); fetchMasterDrugs(); }),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: Column(children: [
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 10),
              _drawerItem(icon: Icons.logout_rounded, label: "Logout", isSelected: false, isDestructive: true,
                onTap: () { Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false); }),
            ]),
          ),
        ]),
      ),

      body: currentView == 'Home' 
          ? _buildOriginalConsole() 
          : (currentView == 'AddManufacturer' 
              ? _buildAddManufacturerForm() 
              : (currentView == 'AddDrugs' ? _buildAddDrugMasterForm() : _buildViewDrugsCatalog())),
    );
  }

  Widget _drawerItem({required IconData icon, required String label, required bool isSelected, required VoidCallback onTap, bool isDestructive = false}) {
    final Color activeColor = const Color(0xFF3949AB);
    final Color destructiveColor = const Color(0xFFE53935);
    final Color itemColor = isDestructive ? destructiveColor : (isSelected ? activeColor : const Color(0xFF4A4A6A));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor.withOpacity(0.12) : isDestructive ? destructiveColor.withOpacity(0.08) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 18, color: itemColor),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: itemColor))),
              if (isSelected) Container(width: 6, height: 6, decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle)),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── HOME CONSOLE (IMPROVED) ──────────────────────────────────────────────────

  Widget _buildOriginalConsole() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gradient Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF283593), Color(0xFF3949AB), Color(0xFF5C6BC0)],
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    "Hello, ${widget.wholesalerName.split(' ').first} 👋",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text("Wholesaler Management Portal", style: TextStyle(color: Colors.white60, fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 18),
              // Info chips row
              Row(children: [
                _headerChip(Icons.assignment_rounded, widget.wholesalerGstin),
                const SizedBox(width: 8),
                _headerChip(Icons.card_membership_rounded, widget.wholesalerLicense),
              ]),
            ]),
          ),

          // ── Operations Section ──
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 22, 18, 12),
            child: Text("Warehouse Operations", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              _buildLargeNavButton(
                title: "INWARD",
                subtitle: "Receive Shipment",
                description: "Scan & verify incoming narcotics from manufacturer",
                icon: Icons.downloading_rounded,
                gradientColors: [const Color(0xFF2E7D32), const Color(0xFF43A047)],
                onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => InwardPage(ownerId: widget.userId, userEmail: widget.wholesalerEmail))); },
              ),
              const SizedBox(height: 12),
              _buildLargeNavButton(
                title: "OUTWARD",
                subtitle: "Dispatch Stock",
                description: "Send narcotics to retailers/hospitals with invoice",
                icon: Icons.upload_file_rounded,
                gradientColors: [const Color(0xFFE65100), const Color(0xFFFF6D00)],
                onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => OutwardPage(ownerId: widget.userId, wholesalerName: widget.wholesalerName, wholesalerGstin: widget.wholesalerGstin, wholesalerLicense: widget.wholesalerLicense))); },
              ),
            ]),
          ),

          // ── Quick Access Section ──
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 24, 18, 12),
            child: Text("Quick Access", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
            child: Row(children: [
              Expanded(child: _quickCard(Icons.add_business_rounded, "Add\nManufacturer", const Color(0xFF3949AB),
                onTap: () => setState(() => currentView = 'AddManufacturer'))),
              const SizedBox(width: 10),
              Expanded(child: _quickCard(Icons.add_circle_outline_rounded, "Add\nDrug Master", const Color(0xFF00695C),
                onTap: () => setState(() => currentView = 'AddDrugs'))),
              const SizedBox(width: 10),
              Expanded(child: _quickCard(Icons.medication_liquid_rounded, "Drug\nCatalog", const Color(0xFF6A1B9A),
                onTap: () { setState(() => currentView = 'DrugList'); fetchMasterDrugs(); })),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String text) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Flexible(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _buildLargeNavButton({
    required String title, required String subtitle, required String description,
    required IconData icon, required List<Color> gradientColors, required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
            Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text(description, style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 15),
          ),
        ]),
      ),
    );
  }

  Widget _quickCard(IconData icon, String label, Color color, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 9),
          Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, height: 1.3),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  // ─── ADD MANUFACTURER FORM ────────────────────────────────────────────────────

  Widget _buildAddManufacturerForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF3949AB).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.factory_rounded, color: Colors.white, size: 26)),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Manufacturer Registration", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 3),
              Text("Register verified production facilities", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 24),
        _sectionLabel("BASIC INFORMATION"),
        _styledTextField(controller: mNameCtrl, label: "Manufacturer's Name", icon: Icons.factory_outlined),
        const SizedBox(height: 14),
        _styledTextField(controller: mAddressCtrl, label: "Registered Address", icon: Icons.location_on_outlined, maxLines: 2),
        const SizedBox(height: 14),
        _styledTextField(controller: mPhoneCtrl, label: "Contact Phone", icon: Icons.phone_outlined, prefixText: "+91 ", keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
        const SizedBox(height: 14),
        _styledTextField(controller: mEmailCtrl, label: "Email Address", hint: "corporate@gmail.com", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _styledTextField(controller: mWebsiteCtrl, label: "Website (Optional)", hint: "www.firmname.com", icon: Icons.language_outlined, keyboardType: TextInputType.url),
        const SizedBox(height: 20),
        _sectionLabel("REGULATORY DETAILS"),
        _styledTextField(controller: mLicenseCtrl, label: "Drug License Number", hint: "e.g., CG-12345-26", icon: Icons.card_membership_outlined),
        const SizedBox(height: 14),
        _styledTextField(controller: mGstinCtrl, label: "GSTIN (Mandatory)", hint: "15-Digit Alphanumeric Code", icon: Icons.assignment_outlined, inputFormatters: [LengthLimitingTextInputFormatter(15)]),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: saveManufacturer,
          icon: const Icon(Icons.save_rounded, color: Colors.white, size: 20),
          label: const Text("SAVE MANUFACTURER", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54), backgroundColor: const Color(0xFF3949AB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0, shadowColor: Colors.transparent),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ─── ADD DRUG MASTER FORM ─────────────────────────────────────────────────────

  Widget _buildAddDrugMasterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00695C), Color(0xFF26A69A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF00695C).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.medication_rounded, color: Colors.white, size: 26)),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Drug Master Catalog", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 3),
              Text("Configure global drug standards in database", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 24),
        _sectionLabel("IDENTIFICATION"),
        _styledTextField(controller: dBrandIdCtrl, label: "Brand ID", hint: "e.g., BR_001", icon: Icons.badge_outlined),
        const SizedBox(height: 14),
        _styledTextField(controller: dGtinCtrl, label: "GTIN / Barcode (8–14 digits)", hint: "Unique numerical identifier", icon: Icons.qr_code_scanner_rounded, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)]),
        const SizedBox(height: 20),
        _sectionLabel("DRUG COMPOSITION"),
        _styledDropdown<String>(
          label: "Generic Salt Composition", icon: Icons.science_rounded, value: selectedGenericName,
          items: genericNarcoticsList.map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: t.startsWith('➕') ? const Color(0xFF3949AB) : const Color(0xFF1A1A2E), fontWeight: t.startsWith('➕') ? FontWeight.bold : FontWeight.normal)))).toList(),
          onChanged: (v) { if (v == '➕ Add New Drug Salt') { _showAddCustomSaltDialog(); } else { setState(() { selectedGenericName = v!; }); } },
        ),
        const SizedBox(height: 14),
        _styledTextField(controller: dBrandNameCtrl, label: "Brand / Drug Name", hint: "e.g., Alprax", icon: Icons.bookmark_added_rounded),
        const SizedBox(height: 14),
        _styledTextField(controller: dStrengthCtrl, label: "Composition Strength", hint: "e.g., 0.5mg", icon: Icons.monitor_weight_rounded),
        const SizedBox(height: 20),
        _sectionLabel("PACKAGING"),
        _styledDropdown<String>(
          label: "Packaging Configuration", icon: Icons.layers_rounded, value: selectedPackagingType,
          items: ['Strip', 'Box', 'Vial / Injection'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => selectedPackagingType = v!),
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: saveDrugMaster,
          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
          label: const Text("REGISTER DRUG IN MASTER", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54), backgroundColor: const Color(0xFF00695C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0, shadowColor: Colors.transparent),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ─── DRUG CATALOG VIEW (IMPROVED) ────────────────────────────────────────────

  Widget _buildViewDrugsCatalog() {
    if (isLoadingDrugs) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: Color(0xFF3949AB)),
        SizedBox(height: 16),
        Text("Loading drug catalog...", style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
      ]));
    }

    if (masterDrugsList.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.inventory_2_outlined, size: 56, color: Color(0xFFBDBDBD))),
        const SizedBox(height: 18),
        const Text("Catalog is Empty", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A4A6A))),
        const SizedBox(height: 6),
        Text("No drugs have been configured yet.", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      ]));
    }
List<dynamic> filteredDrugs = masterDrugsList.where((drug) {
  return (drug['drug_name'] ?? drug['brand_name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(drugSearch.toLowerCase()) ||

      (drug['generic_name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(drugSearch.toLowerCase()) ||

      (drug['gtin'] ?? '')
          .toString()
          .toLowerCase()
          .contains(drugSearch.toLowerCase()) ||

      (drug['strength'] ?? '')
          .toString()
          .toLowerCase()
          .contains(drugSearch.toLowerCase());
}).toList();
    return Column(children: [
      Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: drugSearchCtrl,
        onChanged: (value) {
          setState(() {
            drugSearch = value;
          });
        },
        decoration: InputDecoration(
          hintText: "Search Drug, Salt, GTIN, Strength...",
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF3949AB),
          ),
          suffixIcon: drugSearch.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    drugSearchCtrl.clear();
                    setState(() {
                      drugSearch = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE0E4F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF3949AB),
              width: 2,
            ),
          ),
        ),
      ),
    ),
      // Stats Banner
      Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFF3949AB).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          const Icon(Icons.analytics_rounded, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          Text("${masterDrugsList.length} Products Registered", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: const Text("MASTER CATALOG", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
        
        ]),
      ),

      Expanded(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: filteredDrugs.length,
          itemBuilder: (context, index) {
            final drug = filteredDrugs[index];
            final String displayDrugName = drug['drug_name'] ?? drug['brand_name'] ?? 'Unknown Brand';
            final bool isOwner = drug['added_by'] == widget.wholesalerEmail;

            // Packaging type accent colors
            final Map<String, Color> pkgColorMap = {
              'Strip': const Color(0xFF1565C0),
              'Box': const Color(0xFF6A1B9A),
              'Vial / Injection': const Color(0xFFAD1457),
            };
            final Color pkgColor = pkgColorMap[drug['packaging_type']] ?? const Color(0xFF3949AB);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEF0F8), width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Drug icon
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(13)),
                    child: const Icon(Icons.medication_rounded, color: Color(0xFF3949AB), size: 26),
                  ),
                  const SizedBox(width: 12),

                  // Details
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Name + packaging badge
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: Text(displayDrugName, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Color(0xFF1A1A2E)))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: pkgColor.withOpacity(0.09), borderRadius: BorderRadius.circular(8)),
                          child: Text(drug['packaging_type'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pkgColor)),
                        ),
                      ]),
                      const SizedBox(height: 5),
                      // Salt
                      Row(children: [
                        const Icon(Icons.science_outlined, size: 13, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 4),
                        Expanded(child: Text("${drug['generic_name'] ?? '—'}",
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 10),
                      // GTIN + Strength + Edit
                      Row(children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              const Icon(Icons.qr_code_rounded, size: 13, color: Color(0xFF3949AB)),
                              const SizedBox(width: 4),
                              Expanded(child: Text(drug['gtin'] ?? '—',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF3949AB), fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.monitor_weight_outlined, size: 13, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(drug['strength'] ?? '', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                          ]),
                        ),
                        const SizedBox(width: 6),
                        isOwner
                          ? GestureDetector(
                              onTap: () => _showEditDrugDialog(drug),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFCC80))),
                                child: const Icon(Icons.edit_note_rounded, color: Color(0xFFE65100), size: 20),
                              ))
                          : Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFBDBDBD), size: 18)),
                      ]),
                    ]),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }}