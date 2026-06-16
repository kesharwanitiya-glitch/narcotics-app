import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisteredPatientsPage extends StatefulWidget {
  final String retailerName;
  const RegisteredPatientsPage({super.key, required this.retailerName});

  @override
  State<RegisteredPatientsPage> createState() => _RegisteredPatientsPageState();
}

class _RegisteredPatientsPageState extends State<RegisteredPatientsPage> {
  List<dynamic> history = [];
  List<dynamic> filteredHistory = [];
  bool loading = true;

  final searchCtrl = TextEditingController();

  static const Color kOrange = Color(0xFFE65100);
  static const Color kOrangeLight = Color(0xFFFF6D00);

  @override
  void initState() {
    super.initState();
    fetchHistory();
    searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    searchCtrl.removeListener(_onSearch);
    searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredHistory = List.from(history);
      } else {
        filteredHistory = history.where((item) {
          final name = (item['customer_name'] ?? '').toString().toLowerCase();
          final abha = (item['abha_id'] ?? '').toString().toLowerCase();
          final drug = (item['drug_name'] ?? '').toString().toLowerCase();
          return name.contains(query) || abha.contains(query) || drug.contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchHistory() async {
    final res = await http.get(Uri.parse(
      'http://10.0.2.2:5000/get-retailer-sales-history/${Uri.encodeComponent(widget.retailerName)}'
    ));
    if (res.statusCode == 200) {
      setState(() {
        history = jsonDecode(res.body);
        filteredHistory = List.from(history);
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        title: const Text("Registered Patients", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
        backgroundColor: kOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : Column(children: [
              // ── Gradient Header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kOrange, kOrangeLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Stats row
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.people_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("${history.length} Patients Served",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text("Sales history of all patients", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ]),
                  const SizedBox(height: 16),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                      decoration: InputDecoration(
                        hintText: "Search by name, ABHA ID or drug...",
                        hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: kOrange, size: 22),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E), size: 20),
                                onPressed: () { searchCtrl.clear(); })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ]),
              ),

              // ── Results count ──
              if (!loading && searchCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(children: [
                    const Icon(Icons.filter_list_rounded, size: 15, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text("${filteredHistory.length} result(s) found",
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                  ]),
                ),

              // ── List ──
              Expanded(
                child: filteredHistory.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(color: const Color(0xFFFFF3EE), borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.person_search_rounded, size: 52, color: Color(0xFFBDBDBD)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchCtrl.text.isNotEmpty ? "No matching patients found" : "No Patients Registered",
                          style: const TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(
                          searchCtrl.text.isNotEmpty ? "Try a different search term" : "Sold drugs will appear here.",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ]))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final item = filteredHistory[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFFE0CC), width: 1),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: kOrange.withOpacity(0.1),
                                  child: Text(
                                    (item['customer_name'] ?? 'P').toString().substring(0, 1).toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kOrange),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Details
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  // Name
                                  Text("${item['customer_name']}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Color(0xFF1A1A2E)),
                                    overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 5),
                                  // ABHA ID
                                  _patientRow(Icons.badge_outlined, "ABHA ID", "${item['abha_id'] ?? 'N/A'}"),
                                  _patientRow(Icons.medication_rounded, "Drug", "${item['drug_name'] ?? 'N/A'}"),
                                  _patientRow(Icons.gavel_rounded, "Batch", "${item['batch_no'] ?? 'N/A'}"),
                                  const SizedBox(height: 7),
                                  // Qty badge
                                  Row(children: [
                                    _badge("Qty: ${item['quantity']}", const Color(0xFFFFF3EE), kOrange),
                                    if (item['sale_date'] != null) ...[
                                      const SizedBox(width: 6),
                                      Flexible(child: _badge("Date: ${_fmtDate(item['sale_date'])}", const Color(0xFFF0F2FF), const Color(0xFF3949AB))),
                                    ],
                                  ]),
                                ])),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ]),
    );
  }

  Widget _patientRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(children: [
        Icon(icon, size: 13, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 5),
        Text("$label: ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF4A4A6A)), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg), overflow: TextOverflow.ellipsis),
    );
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return 'N/A';
    final s = raw.toString();
    return s.contains('T') ? s.split('T')[0] : s;
  }
}