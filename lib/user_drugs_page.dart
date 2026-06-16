import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserDrugsPage extends StatefulWidget {
  final String userName;
   final String userEmail;
  final String role;
  const UserDrugsPage({super.key, required this.userName, required this.userEmail, required this.role});
  @override
  State<UserDrugsPage> createState() => _UserDrugsPageState();
}

class _UserDrugsPageState extends State<UserDrugsPage> {
  static const Color kIndigo = Color(0xFF3949AB);
  static const Color kIndigoLight = Color(0xFF5C6BC0);

  List drugs = [];
  List filteredDrugs = [];
  bool loading = true;
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchStock();
    searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = searchCtrl.text.trim().toLowerCase();
    setState(() {
      filteredDrugs = q.isEmpty ? List.from(drugs) : drugs.where((d) {
        final name  = (d['drug_name'] ?? '').toString().toLowerCase();
        final batch = (d['batch_no']  ?? '').toString().toLowerCase();
        return name.contains(q) || batch.contains(q);
      }).toList();
    });
  }

  Future fetchStock() async {

  String url = "";

  if (widget.role == "Wholesaler") {

    url =
        "http://10.0.2.2:5000/get-wholesaler-stock/${Uri.encodeComponent(widget.userEmail)}";

  } else {

    url =
        "http://10.0.2.2:5000/get-retailer-stock/${Uri.encodeComponent(widget.userName)}";
  }

  final res = await http.get(Uri.parse(url));

  if (res.statusCode == 200) {

    final data = jsonDecode(res.body);

    setState(() {
      drugs = data;
      filteredDrugs = List.from(data);
      loading = false;
    });

  } else {

    setState(() {
      loading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    // Total units
    int totalUnits = 0;
    for (var d in drugs) { totalUnits += int.tryParse(d['total_qty'].toString()) ?? 0; }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), overflow: TextOverflow.ellipsis),
          Text(widget.role, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: kIndigo, foregroundColor: Colors.white, elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kIndigo))
          : Column(children: [
              // ── Header + search ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [kIndigo, kIndigoLight], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Column(children: [
                  // Stats row
                  Row(children: [
                    Expanded(child: _statPill(Icons.medication_rounded, "${drugs.length} SKUs")),
                    const SizedBox(width: 10),
                    Expanded(child: _statPill(Icons.stacked_bar_chart_rounded, "$totalUnits Units Total")),
                  ]),
                  const SizedBox(height: 12),
                  // Search bar
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
                    child: TextField(
                      controller: searchCtrl,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                      decoration: InputDecoration(
                        hintText: "Search by drug name or batch...",
                        hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: kIndigo, size: 22),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E), size: 20), onPressed: () => searchCtrl.clear())
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                    ),
                  ),
                ]),
              ),

              if (searchCtrl.text.isNotEmpty)
                Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(children: [
                    const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 6),
                    Text("${filteredDrugs.length} result(s)", style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                  ])),

              Expanded(
                child: filteredDrugs.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.inventory_2_outlined, size: 52, color: Color(0xFFBDBDBD))),
                        const SizedBox(height: 16),
                        Text(searchCtrl.text.isNotEmpty ? "No matching drugs" : "No Stock Found",
                          style: const TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(searchCtrl.text.isNotEmpty ? "Try a different search term" : "This user has no stock.",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ]))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                        itemCount: filteredDrugs.length,
                        itemBuilder: (context, index) {
                          final drug = filteredDrugs[index];
                          final int qty = int.tryParse(drug['total_qty'].toString()) ?? 0;
                          final bool isLow  = qty <= 10;
                          final Color qtyColor = isLow ? Colors.redAccent : (qty <= 50 ? const Color(0xFFE65100) : kIndigo);
                          final Color qtyBg   = isLow ? const Color(0xFFFFEBEE) : (qty <= 50 ? const Color(0xFFFFF3E0) : const Color(0xFFF0F2FF));

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isLow ? const Color(0xFFFFCDD2) : const Color(0xFFEEF0F8), width: 1),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                            child: Row(children: [
                              Container(width: 46, height: 46,
                                decoration: BoxDecoration(
                                  color: isLow ? const Color(0xFFFFEBEE) : const Color(0xFFF0F2FF),
                                  borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.medication_rounded, color: isLow ? Colors.redAccent : kIndigo, size: 24)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(drug['drug_name'] ?? '', overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.gavel_rounded, size: 13, color: Color(0xFF9E9E9E)),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(drug['batch_no'] ?? '',
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontFamily: 'monospace'),
                                    overflow: TextOverflow.ellipsis)),
                                ]),
                                if (isLow) ...[
                                  const SizedBox(height: 4),
                                  const Row(children: [
                                    Icon(Icons.warning_amber_rounded, size: 13, color: Colors.redAccent),
                                    SizedBox(width: 4),
                                    Text("Low Stock Alert", style: TextStyle(fontSize: 11.5, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                                  ]),
                                ],
                              ])),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: qtyBg, borderRadius: BorderRadius.circular(10)),
                                child: Column(children: [
                                  Text(qty.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: qtyColor, fontSize: 18)),
                                  Text("units", style: TextStyle(fontSize: 10, color: qtyColor, fontWeight: FontWeight.w500)),
                                ]),
                              ),
                            ]),
                          );
                        }),
              ),
            ]),
    );
  }

  Widget _statPill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 15),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
    ]));
}