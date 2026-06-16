import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewDrugsPage extends StatefulWidget {
  final String retailerName;
  const ViewDrugsPage({super.key, required this.retailerName});

  @override
  State<ViewDrugsPage> createState() => _ViewDrugsPageState();
}

class _ViewDrugsPageState extends State<ViewDrugsPage> {
  List<dynamic> stock = [];
  List<dynamic> filteredStock = [];
  bool loading = true;

  final searchCtrl = TextEditingController();

  static const Color kTeal = Color(0xFF00695C);
  static const Color kTealLight = Color(0xFF00897B);

  @override
  void initState() {
    super.initState();
    fetchStock();
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
        filteredStock = List.from(stock);
      } else {
        filteredStock = stock.where((item) {
          final drug = (item['drug_name'] ?? '').toString().toLowerCase();
          final batch = (item['batch_no'] ?? '').toString().toLowerCase();
          return drug.contains(query) || batch.contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchStock() async {
    final res = await http.get(Uri.parse(
      'http://10.0.2.2:5000/get-retailer-stock/${Uri.encodeComponent(widget.retailerName)}'
    ));
    if (res.statusCode == 200) {
      setState(() {
        stock = jsonDecode(res.body);
        filteredStock = List.from(stock);
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Count low stock items
    final int lowStockCount = stock.where((item) {
      final qty = int.tryParse(item['total_qty'].toString()) ?? 0;
      return qty <= 10;
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Drug Stock", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kTeal))
          : Column(children: [
              // ── Gradient Header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kTeal, kTealLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Stats row
                  Row(children: [
                    Expanded(child: _statPill(Icons.inventory_rounded, "${stock.length} SKUs Total", Colors.white.withOpacity(0.15))),
                    const SizedBox(width: 10),
                    if (lowStockCount > 0)
                      _statPill(Icons.warning_amber_rounded, "$lowStockCount Low", Colors.redAccent.withOpacity(0.3), textColor: Colors.red.shade100),
                  ]),
                  const SizedBox(height: 14),
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
                        hintText: "Search by drug name or batch no...",
                        hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: kTeal, size: 22),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E), size: 20),
                                onPressed: () => searchCtrl.clear())
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ]),
              ),

              // ── Results count when searching ──
              if (searchCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(children: [
                    const Icon(Icons.filter_list_rounded, size: 15, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text("${filteredStock.length} result(s) found",
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                  ]),
                ),

              // ── Drug List ──
              Expanded(
                child: filteredStock.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F1), borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.medication_outlined, size: 52, color: Color(0xFFBDBDBD)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchCtrl.text.isNotEmpty ? "No matching drugs found" : "Inventory is Empty",
                          style: const TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(
                          searchCtrl.text.isNotEmpty ? "Try a different search term" : "Accepted invoices will appear here.",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ]))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                        itemCount: filteredStock.length,
                        itemBuilder: (context, index) {
                          final item = filteredStock[index];
                          final int qty = int.tryParse(item['total_qty'].toString()) ?? 0;
                          final bool isLow = qty <= 10;
                          final Color qtyColor = isLow ? Colors.redAccent : (qty <= 50 ? const Color(0xFFE65100) : kTeal);
                          final Color qtyBg = isLow ? const Color(0xFFFFEBEE) : (qty <= 50 ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9));

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isLow ? const Color(0xFFFFCDD2) : const Color(0xFFD1E8D3),
                                width: 1,
                              ),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                // Icon
                                Container(
                                  width: 46, height: 46,
                                  decoration: BoxDecoration(
                                    color: isLow ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.medication_rounded,
                                    color: isLow ? Colors.redAccent : kTeal, size: 24),
                                ),
                                const SizedBox(width: 12),

                                // Details
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(item['drug_name'].toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E)),
                                    overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 5),
                                  Row(children: [
                                    const Icon(Icons.gavel_rounded, size: 13, color: Color(0xFF9E9E9E)),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(item['batch_no'].toString(),
                                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontFamily: 'monospace'),
                                      overflow: TextOverflow.ellipsis)),
                                  ]),
                                  if (isLow) ...[
                                    const SizedBox(height: 5),
                                    const Row(children: [
                                      Icon(Icons.warning_amber_rounded, size: 13, color: Colors.redAccent),
                                      SizedBox(width: 4),
                                      Text("Low Stock — Reorder Soon",
                                        style: TextStyle(fontSize: 11.5, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                                    ]),
                                  ],
                                ])),

                                // Qty badge
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(color: qtyBg, borderRadius: BorderRadius.circular(10)),
                                  child: Column(children: [
                                    Text(qty.toString(),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: qtyColor, fontSize: 18)),
                                    Text("units",
                                      style: TextStyle(fontSize: 10, color: qtyColor, fontWeight: FontWeight.w500)),
                                  ]),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ]),
    );
  }

  Widget _statPill(IconData icon, String text, Color bg, {Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: textColor, size: 15),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: textColor, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}