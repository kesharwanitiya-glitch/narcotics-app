import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InspectorVisitDetails extends StatefulWidget {
  final String inspectorName;
  const InspectorVisitDetails({super.key, required this.inspectorName});

  @override
  State<InspectorVisitDetails> createState() => _InspectorVisitDetailsState();
}

class _InspectorVisitDetailsState extends State<InspectorVisitDetails> {
  static const Color kIndigo = Color(0xFF3949AB);
  static const Color kIndigoLight = Color(0xFF5C6BC0);

  List allData = [];
  List filteredData = [];
  bool loading = true;
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
    searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/admin/inspector-visits/${widget.inspectorName}'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        allData = data;
        filteredData = List.from(data);
        loading = false;
      });
    } else {
      setState(() { loading = false; });
    }
  }

  void _onSearch() {
    final q = searchCtrl.text.trim().toLowerCase();
    setState(() {
      filteredData = q.isEmpty
          ? List.from(allData)
          : allData.where((item) {
              final name    = (item['target_user_name']  ?? '').toString().toLowerCase();
              final license = (item['target_license_no'] ?? '').toString().toLowerCase();
              final role    = (item['target_role']       ?? '').toString().toLowerCase();
              final date    = (item['audit_date']        ?? '').toString().toLowerCase();
              return name.contains(q) || license.contains(q) || role.contains(q) || date.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final int matchedCount   = allData.where((i) => i['overall_status'].toString().toUpperCase() == "MATCHED").length;
    final int unmatchedCount = allData.length - matchedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.inspectorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), overflow: TextOverflow.ellipsis),
          const Text("Visit Records", style: TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: kIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kIndigo))
          : Column(children: [
              // ── Gradient header + stats + search ──────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [kIndigo, kIndigoLight],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: _statPill(Icons.check_circle_rounded,  "$matchedCount Matched",    isGreen: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _statPill(Icons.cancel_rounded,        "$unmatchedCount Unmatched", isRed: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _statPill(Icons.list_alt_rounded,      "${allData.length} Total")),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: TextField(
                      controller: searchCtrl,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                      decoration: InputDecoration(
                        hintText: "Search by name, license, role or date...",
                        hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: kIndigo, size: 22),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E), size: 20),
                                onPressed: () => searchCtrl.clear())
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                    ),
                  ),
                ]),
              ),

              // ── Results count ──────────────────────────────────────────
              if (searchCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(children: [
                    const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 6),
                    Text("${filteredData.length} result(s) found",
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                  ])),

              // ── List ──────────────────────────────────────────────────
              Expanded(
                child: filteredData.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.history_toggle_off_rounded, size: 52, color: Color(0xFFBDBDBD))),
                        const SizedBox(height: 16),
                        Text(searchCtrl.text.isNotEmpty ? "No matching visits" : "No Visit Records",
                          style: const TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(
                          searchCtrl.text.isNotEmpty ? "Try a different search term" : "No inspection records found.",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ]))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          final item    = filteredData[index];
                          final matched = item['overall_status'].toString().toUpperCase() == "MATCHED";
                          final Color sColor = matched ? const Color(0xFF2E7D32) : Colors.redAccent;
                          final Color sBg    = matched ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: matched ? const Color(0xFFBBF7D0) : const Color(0xFFFFCDD2), width: 1),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(width: 44, height: 44,
                                decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(12)),
                                child: Icon(matched ? Icons.verified_rounded : Icons.warning_rounded, color: sColor, size: 22)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item['target_user_name'] ?? '', overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Color(0xFF1A1A2E))),
                                const SizedBox(height: 6),
                                _infoRow(Icons.card_membership_outlined, "License", "${item['target_license_no'] ?? 'N/A'}"),
                                _infoRow(
                                  item['target_role'] == 'Wholesaler' ? Icons.business_rounded : Icons.storefront_rounded,
                                  "Role", "${item['target_role'] ?? 'N/A'}"),
                                _infoRow(Icons.calendar_today_rounded, "Date", "${item['audit_date'] ?? 'N/A'}"),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: sColor.withOpacity(0.3))),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(matched ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 13, color: sColor),
                                    const SizedBox(width: 5),
                                    Text(item['overall_status'] ?? '',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sColor)),
                                  ])),
                              ])),
                            ]),
                          );
                        }),
              ),
            ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        Icon(icon, size: 13, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 5),
        Text("$label: ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF4A4A6A)), overflow: TextOverflow.ellipsis)),
      ]));
  }

  Widget _statPill(IconData icon, String text, {bool isGreen = false, bool isRed = false}) {
    final Color bg = isGreen
        ? Colors.white.withOpacity(0.15)
        : isRed
            ? Colors.white.withOpacity(0.12)
            : Colors.white.withOpacity(0.1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 5),
        Flexible(child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis)),
      ]));
  }
}