import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login_screen.dart';
import 'drug_traceability_page.dart';
import 'user_stock_page.dart';
import 'edit_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InspectorPage extends StatefulWidget {
  final String inspectorName;
  final String inspectorEmail;
  final String inspectorRole;

  const InspectorPage({
    super.key,
    required this.inspectorName,
    required this.inspectorEmail,
    required this.inspectorRole,
  });

  @override
  State<InspectorPage> createState() => _InspectorPageState();
}

class _InspectorPageState extends State<InspectorPage> with TickerProviderStateMixin {

  static const Color kIndigo = Color(0xFF3949AB);
  static const Color kIndigoLight = Color(0xFF5C6BC0);

  List usersList = [];
  List drugsList = [];
  List wholesalerHistory = [];
  List retailerHistory = [];
  List filteredWholesalerHistory = [];
  List filteredRetailerHistory = [];

  final wholesalerSearchCtrl = TextEditingController();
  final retailerSearchCtrl   = TextEditingController();

  String selectedRole = "Wholesaler";
  dynamic selectedUser;
  dynamic selectedDrug;
  bool loadingDrugs = false;

  final physicalCtrl      = TextEditingController();
  final totalPhysicalCtrl = TextEditingController();

  String digitalStock      = "0";
  String totalDigitalStock = "0";
  List<Map<String, dynamic>> inspectionDrugs = [];

  bool licenseVerified     = false;
  bool stockVerified       = false;
  bool prescriptionChecked = false;
  bool storageChecked      = false;
  bool seizureRequired     = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchHistory("Wholesaler");
    fetchHistory("Retailer");
    wholesalerSearchCtrl.addListener(() => _onSearch("Wholesaler"));
    retailerSearchCtrl.addListener(()   => _onSearch("Retailer"));
  }

  @override
  void dispose() {
    wholesalerSearchCtrl.dispose();
    retailerSearchCtrl.dispose();
    physicalCtrl.dispose();
    totalPhysicalCtrl.dispose();
    super.dispose();
  }
  bool toBool(dynamic v) {
  return v == true ||
      v == 1 ||
      v == "1" ||
      v == "true" ||
      v == "True";
}

  // ── SEARCH FILTER ─────────────────────────────────────────────────────────────
  void _onSearch(String role) {
    final query  = role == "Wholesaler"
        ? wholesalerSearchCtrl.text.trim().toLowerCase()
        : retailerSearchCtrl.text.trim().toLowerCase();
    final source = role == "Wholesaler" ? wholesalerHistory : retailerHistory;
    final result = query.isEmpty
        ? List.from(source)
        : source.where((item) {
            final name    = (item['target_user_name']  ?? '').toString().toLowerCase();
            final license = (item['target_license_no'] ?? '').toString().toLowerCase();
            final date    = (item['audit_date']        ?? '').toString().toLowerCase();
            return name.contains(query) || license.contains(query) || date.contains(query);
          }).toList();
    setState(() {
      if (role == "Wholesaler") filteredWholesalerHistory = result;
      else filteredRetailerHistory = result;
    });
  }

  // ── FETCH USERS ───────────────────────────────────────────────────────────────
  Future fetchUsers() async {
    final res = await http.get(Uri.parse('http://10.0.2.2:5000/get-all-registered-users'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() { usersList = data.where((u) => u['role'] == selectedRole).toList(); });
    }
  }

  // ── FETCH STOCK ───────────────────────────────────────────────────────────────
  Future fetchStock() async {
    if (selectedUser == null) return;
    setState(() { loadingDrugs = true; drugsList = []; });
    final res = await http.get(Uri.parse(
        'http://10.0.2.2:5000/get-user-digital-stock/${selectedUser['full_name']}/${selectedUser['role']}'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      int total = 0;
      for (var item in data) { total += int.tryParse(item['total_qty'].toString()) ?? 0; }
      setState(() { drugsList = data; totalDigitalStock = total.toString(); loadingDrugs = false; });
    }
  }

  // ── ADD DRUG ──────────────────────────────────────────────────────────────────
  void addDrug() {
    if (selectedDrug == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select drug"), behavior: SnackBarBehavior.floating));
      return;
    }
    if (physicalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter physical stock"), behavior: SnackBarBehavior.floating));
      return;
    }
    int digital  = int.tryParse(digitalStock) ?? 0;
    int physical = int.tryParse(physicalCtrl.text) ?? 0;
    int mismatch = digital - physical;
    inspectionDrugs.add({
      "drug_name":     selectedDrug['drug_name'],
      "batch_no":      selectedDrug['batch_no'],
      "digital_stock": digital,
      "physical_stock":physical,
      "mismatch":      mismatch,
      "status":        mismatch == 0 ? "MATCHED" : "UNMATCHED"
    });
    setState(() { selectedDrug = null; digitalStock = "0"; physicalCtrl.clear(); });
  }

  // ── SUBMIT INSPECTION ─────────────────────────────────────────────────────────
  Future submitInspection() async {
    if (selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select user first"), behavior: SnackBarBehavior.floating));
      return;
    }
    if (inspectionDrugs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one drug"), behavior: SnackBarBehavior.floating));
      return;
    }
    final totalPhysical = int.tryParse(totalPhysicalCtrl.text.trim()) ?? 0;
    final totalDigital  = int.tryParse(totalDigitalStock) ?? 0;
    final overallStatus = totalDigital == totalPhysical ? "MATCHED" : "UNMATCHED";

    final res = await http.post(
      Uri.parse('http://10.0.2.2:5000/submit-inspector-visit'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "inspector_name":     widget.inspectorName,
        "target_user_name":   selectedUser['full_name'],
        "target_license_no":  selectedUser['drug_license_no'],
        "target_role":        selectedUser['role'],
        "audit_date":         DateTime.now().toString().split(' ')[0],
        "license_verified":   licenseVerified,
        "stock_verified":     stockVerified,
        "prescription_checked": prescriptionChecked,
        "storage_checked":    storageChecked,
        "seizure_required":   seizureRequired,
        "total_digital_stock":totalDigital,
        "total_physical_stock":totalPhysical,
        "overall_status":     overallStatus,
        "drugs":              inspectionDrugs
      }),
    );

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("✅ Inspection Submitted Successfully"),
        backgroundColor: Color(0xFF2E7D32), behavior: SnackBarBehavior.floating));
      setState(() {
        inspectionDrugs.clear(); selectedUser = null; selectedDrug = null;
        digitalStock = "0"; totalDigitalStock = "0";
        physicalCtrl.clear(); totalPhysicalCtrl.clear();
        licenseVerified = false; stockVerified = false;
        prescriptionChecked = false; storageChecked = false; seizureRequired = false;
      });
      fetchHistory("Wholesaler");
      fetchHistory("Retailer");
    }
  }

  // ── FETCH HISTORY ─────────────────────────────────────────────────────────────
  Future fetchHistory(String role) async {
    final res = await http.get(Uri.parse(
        'http://10.0.2.2:5000/get-audit-history/$role/${widget.inspectorName}'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        if (role == "Wholesaler") { wholesalerHistory = data; filteredWholesalerHistory = List.from(data); }
        else                      { retailerHistory   = data; filteredRetailerHistory   = List.from(data); }
      });
    }
  }

  // ── HISTORY WIDGET ────────────────────────────────────────────────────────────
  Widget buildHistory(List historyList, TextEditingController searchCtrl, String role) {
    final filtered = role == "Wholesaler" ? filteredWholesalerHistory : filteredRetailerHistory;

    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E4F0), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: TextField(
            controller: searchCtrl,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              hintText: "Search by name, license or date...",
              hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: kIndigo, size: 20),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E), size: 18),
                      onPressed: () => searchCtrl.clear())
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
          ),
        ),
      ),

      if (searchCtrl.text.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
          child: Row(children: [
            const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF9E9E9E)),
            const SizedBox(width: 5),
            Text("${filtered.length} result(s) found",
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
          ]),
        ),

      // List
      Expanded(
        child: filtered.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.history_toggle_off_rounded, size: 48, color: Color(0xFFBDBDBD))),
                const SizedBox(height: 14),
                Text(
                  searchCtrl.text.isNotEmpty ? "No matching records" : "No Inspection History",
                  style: const TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 14)),
              ]))
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item      = filtered[index];
                  final isMatched = item['overall_status'] == "MATCHED";
                  final sColor    = isMatched ? const Color(0xFF2E7D32) : Colors.redAccent;
                  final sBg       = isMatched ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEEF0F8)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.fromLTRB(14, 6, 12, 6),
                        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),

                        title: Text(item['target_user_name'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1A1A2E))),

                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 4),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("License: ${item['target_license_no'] ?? ''}",
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
                            const SizedBox(height: 5),
                            Row(children: [
                              // Date chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(6)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.calendar_today_rounded, size: 11, color: kIndigo),
                                  const SizedBox(width: 4),
                                  Text(item['audit_date'] ?? '',
                                    style: const TextStyle(fontSize: 11, color: kIndigo, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                              const SizedBox(width: 6),
                              // Status chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(6)),
                                child: Text(item['overall_status'] ?? '',
                                  style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ]),
                          ]),
                        ),

                        trailing: const Icon(Icons.expand_more_rounded, color: Color(0xFF9E9E9E), size: 22),

                        children: [
                          // Stock summary row
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFF8F9FF), borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              _summaryItem("Digital",   "${item['total_digital_stock']  ?? '—'}", kIndigo),
                              Container(width: 1, height: 34, color: const Color(0xFFE0E4F0)),
                              _summaryItem("Physical",  "${item['total_physical_stock'] ?? '—'}", const Color(0xFF00695C)),
                              Container(width: 1, height: 34, color: const Color(0xFFE0E4F0)),
                              _summaryItem("Inspector", item['inspector_name'] ?? '',            const Color(0xFF6B7280)),
                            ]),
                          ),
                          const SizedBox(height: 10),

                          // Drug rows
                          if (item['drugs'] != null)
                            ...((item['drugs'] as List).map((d) {
                              final dm = d['status'] == "MATCHED";
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: dm ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: dm ? const Color(0xFFBBF7D0) : const Color(0xFFFFCDD2)),
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                      color: dm ? const Color(0xFF2E7D32) : Colors.redAccent,
                                      borderRadius: BorderRadius.circular(9)),
                                    child: const Icon(Icons.medication_rounded, color: Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(d['drug_name'] ?? '', overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A2E))),
                                    const SizedBox(height: 2),
                                    Text("Batch: ${d['batch_no']}  ·  Digital: ${d['digital_stock']}  ·  Physical: ${d['physical_stock']}",
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
                                  ])),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: dm ? const Color(0xFFDCFCE7) : const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(6)),
                                    child: Text(d['status'] ?? '',
                                      style: TextStyle(color: dm ? const Color(0xFF2E7D32) : Colors.redAccent,
                                        fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ]),
                              );
                            }).toList()),

                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Color(0xFFEEF0F8)),
                          const SizedBox(height: 8),

                          // Compliance chips
                          Wrap(spacing: 8, runSpacing: 6, children: [
  _checkChip("License Verified",  toBool(item['license_verified'])),
  _checkChip("Stock Register",    toBool(item['stock_verified'])),
  _checkChip("Prescription",      toBool(item['prescription_checked'])),
  _checkChip("Storage OK",        toBool(item['storage_checked'])),
  _checkChip("Seizure Req.",      toBool(item['seizure_required'])),
                      ]),
                          ]
    ,
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  // ── SMALL HELPERS ─────────────────────────────────────────────────────────────

  Widget _summaryItem(String label, String value, Color color) {
    return Expanded(child: Column(children: [
      Text(label, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF9E9E9E))),
      const SizedBox(height: 3),
      Text(value, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
    ]));
  }

   Widget _checkChip(String label, bool value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: value ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: value ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
        width: 0.8,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          value ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 14,
          color: value ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: value ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
          ),
        ),
      ],
    ),
  );
}

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(children: [
        Container(width: 4, height: 16,
          decoration: BoxDecoration(color: kIndigo, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kIndigo, letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _styledDropdown<T>({
    required String label, required IconData icon, required T? value,
    required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value, isExpanded: true,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kIndigo, size: 20),
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        filled: true, fillColor: const Color(0xFFF8F9FF),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E4F0), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kIndigo, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items, onChanged: onChanged,
    );
  }

  Widget _styledTextField({
    required TextEditingController controller, required String label,
    required IconData icon, TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller, keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kIndigo, size: 20),
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        filled: true, fillColor: const Color(0xFFF8F9FF),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E4F0), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kIndigo, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _stockBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E4F0))),
        child: Column(children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: kIndigo)),
        ]),
      ),
    );
  }

  Widget _checkItem(String label, bool value, void Function(bool?) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFF0F2FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value ? const Color(0xFFE0E4F0) : const Color(0xFFF0F0F0)),
      ),
      child: CheckboxListTile(
        value: value, dense: true, activeColor: kIndigo,
        title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        drawer: _buildDrawer(),
        appBar: AppBar(
          backgroundColor: kIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text("Inspector Dashboard",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
          iconTheme: const IconThemeData(color: Colors.white),
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
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: kIndigo,
              child: const TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
                tabs: [
                  Tab(icon: Icon(Icons.fact_check_rounded, size: 18), text: "Inspection"),
                  Tab(icon: Icon(Icons.history_rounded,    size: 18), text: "History"),
                ],
              ),
            ),
          ),
        ),

        body: TabBarView(children: [

          // ── INSPECTION TAB ──────────────────────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // Gradient banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kIndigo, kIndigoLight],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: kIndigo.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.fact_check_rounded, color: Colors.white, size: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Field Inspection",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text("Inspector: ${widget.inspectorName}",
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ])),
                ]),
              ),
              const SizedBox(height: 18),

              _sectionLabel("TARGET SELECTION"),
              _styledDropdown<String>(
                label: "Select User Type", icon: Icons.people_rounded,
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: "Wholesaler", child: Text("Wholesaler")),
                  DropdownMenuItem(value: "Retailer",   child: Text("Retailer")),
                ],
                onChanged: (v) {
                  setState(() { selectedRole = v!; selectedUser = null; selectedDrug = null; inspectionDrugs.clear(); });
                  fetchUsers();
                },
              ),
              const SizedBox(height: 14),
              _styledDropdown(
                label: "Select User", icon: Icons.person_search_rounded,
                value: selectedUser,
                items: usersList.map((u) => DropdownMenuItem(value: u,
                  child: Text("${u['full_name']} (${u['drug_license_no']})", overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) {
                  setState(() { selectedUser = v; selectedDrug = null; inspectionDrugs.clear(); });
                  fetchStock();
                },
              ),

              if (selectedUser != null) ...[
                const SizedBox(height: 20),
                _sectionLabel("DRUG VERIFICATION"),

                if (loadingDrugs)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: kIndigo))
                else
                  _styledDropdown(
                    label: "Select Drug + Batch", icon: Icons.medication_rounded,
                    value: selectedDrug,
                    items: drugsList.map((d) => DropdownMenuItem(value: d,
                      child: Text("${d['drug_name']} (${d['batch_no']})", overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedDrug  = val;
                        digitalStock  = (val as Map<String, dynamic>)['total_qty'].toString();
                      });
                    },
                  ),

                const SizedBox(height: 14),
                Row(children: [
                  _stockBox("Digital Stock", digitalStock),
                  const SizedBox(width: 12),
                  Expanded(child: _styledTextField(controller: physicalCtrl, label: "Physical Stock",
                    icon: Icons.pin_outlined, keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: addDrug,
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                  label: const Text("ADD DRUG TO INSPECTION",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: kIndigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0),
                ),

                const SizedBox(height: 20),
                _sectionLabel("TOTAL STOCK SUMMARY"),
                Row(children: [
                  _stockBox("Total Digital", totalDigitalStock),
                  const SizedBox(width: 12),
                  Expanded(child: _styledTextField(controller: totalPhysicalCtrl, label: "Total Physical",
                    icon: Icons.inventory_2_outlined, keyboardType: TextInputType.number)),
                ]),

                if (inspectionDrugs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionLabel("ADDED DRUGS (${inspectionDrugs.length})"),
                  ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: inspectionDrugs.length,
                    itemBuilder: (context, i) {
                      final d       = inspectionDrugs[i];
                      final matched = d['status'] == "MATCHED";
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: matched ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: matched ? const Color(0xFFBBF7D0) : const Color(0xFFFFCDD2)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: matched ? const Color(0xFF2E7D32) : Colors.redAccent,
                              borderRadius: BorderRadius.circular(9)),
                            child: const Icon(Icons.medication_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d['drug_name'], overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1A1A2E))),
                            Text("Batch: ${d['batch_no']}  ·  Digital: ${d['digital_stock']}  ·  Physical: ${d['physical_stock']}",
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: matched ? const Color(0xFFDCFCE7) : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(6)),
                            child: Text(d['status'],
                              style: TextStyle(color: matched ? const Color(0xFF2E7D32) : Colors.redAccent,
                                fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ]),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 20),
                _sectionLabel("COMPLIANCE CHECKLIST"),
                _checkItem("License Verified",       licenseVerified,     (v) => setState(() => licenseVerified = v!)),
                _checkItem("Stock Register Verified", stockVerified,       (v) => setState(() => stockVerified = v!)),
                _checkItem("Prescription Checked",   prescriptionChecked, (v) => setState(() => prescriptionChecked = v!)),
                _checkItem("Storage Conditions OK",  storageChecked,      (v) => setState(() => storageChecked = v!)),
                _checkItem("Seizure Required",        seizureRequired,     (v) => setState(() => seizureRequired = v!)),

                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: submitInspection,
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  label: const Text("SUBMIT INSPECTION",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                ),
                const SizedBox(height: 24),
              ],
            ]),
          ),

          // ── HISTORY TAB ─────────────────────────────────────────────────────
          DefaultTabController(
            length: 2,
            child: Column(children: [
              Container(
                color: kIndigo,
                child: const TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  tabs: [Tab(text: "Wholesaler"), Tab(text: "Retailer")],
                ),
              ),
              Expanded(child: TabBarView(children: [
                buildHistory(wholesalerHistory, wholesalerSearchCtrl, "Wholesaler"),
                buildHistory(retailerHistory,   retailerSearchCtrl,   "Retailer"),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── DRAWER ────────────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF283593), kIndigo, kIndigoLight]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(
                widget.inspectorName.isNotEmpty ? widget.inspectorName[0].toUpperCase() : "I",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22))),
            ),
            const SizedBox(height: 14),
            Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.inspectorName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.inspectorEmail,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),

    const SizedBox(width: 8),

    IconButton(
      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
      onPressed: () async {
        final prefs = await SharedPreferences.getInstance();

        final userId = prefs.getInt('userId') ?? 0;
        final phone = prefs.getString('phone_no') ?? '';

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditProfilePage(
              userId: userId,
              name: widget.inspectorName,
              email: widget.inspectorEmail,
              phone: phone,
              license: " ",
               showLicense: false,
            ),
          ),
        );

        if (result == true) {
          setState(() {});
        }
      },
    ),
  ],
),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 13),
                const SizedBox(width: 5),
                Text(widget.inspectorRole,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(left: 8, bottom: 6, top: 4),
                child: Text("NAVIGATION",
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                    color: Color(0xFF9E9E9E), letterSpacing: 1.2))),
              _drawerItem(Icons.dashboard_rounded,  "Dashboard",         () => Navigator.pop(context)),
              _drawerItem(Icons.medication_rounded, "Drug Traceability", () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DrugTraceabilityPage()));
              }),
              _drawerItem(Icons.inventory_rounded,  "User Stock",        () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const UserStockPage()));
              }),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: Column(children: [
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            _drawerItem(Icons.logout_rounded, "Logout", () {
              Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
            }, isDestructive: true),
          ]),
        ),
      ]),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final Color c = isDestructive ? const Color(0xFFE53935) : kIndigo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 18, color: c)),
              const SizedBox(width: 14),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c)),
            ]),
          ),
        ),
      ),
    );
  }
}