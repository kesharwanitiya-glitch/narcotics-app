import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DrugHoldersPage extends StatefulWidget {
  final String drugName;
  final String batchNo;
  const DrugHoldersPage({super.key, required this.drugName, required this.batchNo});

  @override
  State<DrugHoldersPage> createState() => _DrugHoldersPageState();
}

class _DrugHoldersPageState extends State<DrugHoldersPage> {

  static const Color kIndigo = Color(0xFF3949AB);
  static const Color kIndigoLight = Color(0xFF5C6BC0);

  List wholesalers = [];
  List retailers = [];
  bool loading = true;

  // Separate search controllers for each tab
  final wholesalerSearchCtrl = TextEditingController();
  final retailerSearchCtrl   = TextEditingController();

  List filteredWholesalers = [];
  List filteredRetailers   = [];

  @override
  void initState() {
    super.initState();
    fetchData();
    wholesalerSearchCtrl.addListener(() => _onSearch("wholesaler"));
    retailerSearchCtrl.addListener(()   => _onSearch("retailer"));
  }

  @override
  void dispose() {
    wholesalerSearchCtrl.dispose();
    retailerSearchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String type) {
    final q   = type == "wholesaler" ? wholesalerSearchCtrl.text.trim().toLowerCase() : retailerSearchCtrl.text.trim().toLowerCase();
    final src = type == "wholesaler" ? wholesalers : retailers;
    final res = q.isEmpty ? List.from(src) : src.where((item) {
      final name    = (item['full_name']       ?? '').toString().toLowerCase();
      final license = (item['drug_license_no'] ?? '').toString().toLowerCase();
      return name.contains(q) || license.contains(q);
    }).toList();
    setState(() { if (type == "wholesaler") filteredWholesalers = res; else filteredRetailers = res; });
  }

  Future fetchData() async {
    final res = await http.get(Uri.parse(
        'http://10.0.2.2:5000/inspector/drug-holders/${Uri.encodeComponent(widget.drugName)}/${widget.batchNo}'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        wholesalers         = data['wholesalers'] ?? [];
        retailers           = data['retailers']   ?? [];
        filteredWholesalers = List.from(wholesalers);
        filteredRetailers   = List.from(retailers);
        loading = false;
      });
    } else {
      setState(() { loading = false; });
    }
  }

  Widget buildList(List data, List filtered, TextEditingController ctrl, String type) {
    final Color accent = kIndigo;

    return Column(children: [
      // ── Header banner ──
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kIndigo, kIndigoLight],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(type == "wholesaler" ? Icons.business_rounded : Icons.storefront_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(type == "wholesaler" ? "Wholesaler Holders" : "Retailer Holders",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text("${data.length} holder(s) for this batch",
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 12),
          // Search bar
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
            child: TextField(
              controller: ctrl,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: "Search by name or license...",
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: accent, size: 22),
                suffixIcon: ctrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E), size: 20), onPressed: () => ctrl.clear())
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
            ),
          ),
        ]),
      ),

      // ── Results count ──
      if (ctrl.text.isNotEmpty)
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF9E9E9E)),
            const SizedBox(width: 6),
            Text("${filtered.length} result(s)", style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
          ])),

      // ── List ──
      Expanded(
        child: loading
            ? Center(child: CircularProgressIndicator(color: accent))
            : filtered.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(color: accent.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
                      child: Icon(Icons.person_search_rounded, size: 52, color: Colors.grey.shade300)),
                    const SizedBox(height: 16),
                    Text(ctrl.text.isNotEmpty ? "No matching holders" : "No Records Found",
                      style: const TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(ctrl.text.isNotEmpty ? "Try a different search term" : "No holders for this batch.",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ]))
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final qty  = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
                      final bool isLow = qty <= 10;
                      final Color qtyColor = isLow ? Colors.redAccent : accent;
                      final Color qtyBg   = isLow ? const Color(0xFFFFEBEE) : accent.withOpacity(0.08);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEEF0F8), width: 1),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                        child: Row(children: [
                          // Avatar
                          CircleAvatar(radius: 22, backgroundColor: accent.withOpacity(0.1),
                            child: Text(
                              (item['full_name'] ?? 'H').toString().substring(0, 1).toUpperCase(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accent))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item['full_name'] ?? '', overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.card_membership_outlined, size: 13, color: Color(0xFF9E9E9E)),
                              const SizedBox(width: 4),
                              Expanded(child: Text(item['drug_license_no'] ?? '',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis)),
                            ]),
                          ])),
                          const SizedBox(width: 10),
                          // Qty badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: qtyBg, borderRadius: BorderRadius.circular(10)),
                            child: Column(children: [
                              Text(qty.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: qtyColor, fontSize: 17)),
                              Text("units", style: TextStyle(fontSize: 10, color: qtyColor, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        ]),
                      );
                    }),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
  toolbarHeight: 80,
  titleSpacing: 0,
  title: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.drugName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        "Batch: ${widget.batchNo}",
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white70,
        ),
      ),
    ],
  ),
          backgroundColor: kIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Container(color: kIndigo,
              child: const TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
                tabs: [
                  Tab(icon: Icon(Icons.business_rounded, size: 17), text: "Wholesaler"),
                  Tab(icon: Icon(Icons.storefront_rounded, size: 17), text: "Retailer"),
                ],
              )),
          ),
        ),
        body: TabBarView(children: [
          buildList(wholesalers, filteredWholesalers, wholesalerSearchCtrl, "wholesaler"),
          buildList(retailers,   filteredRetailers,   retailerSearchCtrl,   "retailer"),
        ]),
      ),
    );
  }
}