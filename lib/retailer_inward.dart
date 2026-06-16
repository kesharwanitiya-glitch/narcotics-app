import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RetailerInwardPage extends StatefulWidget {
  final String retailerName; 
  const RetailerInwardPage({super.key, required this.retailerName});

  @override
  State<RetailerInwardPage> createState() => _RetailerInwardPageState();
}

class _RetailerInwardPageState extends State<RetailerInwardPage> {
  final historySearchCtrl = TextEditingController();
final stockSearchCtrl = TextEditingController();

String historySearch = '';
String stockSearch = '';
  static const Color kTeal = Color(0xFF00695C);
  static const Color kTealLight = Color(0xFF00897B);

  Future<void> acceptInvoice(var item) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/accept-invoice'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "transaction_id": item['id'],
        "drug_name": item['drug_name'],
        "batch_no": item['batch_no'],
        "quantity": item['quantity'],
        "retailer_name": widget.retailerName,
         "received_date": item['received_date'],
      }),
    );
     print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");
    if (response.statusCode == 200) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Accepted! Stock Updated."), backgroundColor: Color(0xFF2E7D32), behavior: SnackBarBehavior.floating));
    }
  }
  @override
void dispose() {
  historySearchCtrl.dispose();
  stockSearchCtrl.dispose();
  super.dispose();
}

  // ─── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          title: const Text("Inward Supply Ledger", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
          backgroundColor: kTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: kTeal,
              child: const TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(icon: Icon(Icons.pending_actions_rounded, size: 18), text: "Incoming"),
                  Tab(icon: Icon(Icons.history_rounded, size: 18), text: "History"),
                  Tab(icon: Icon(Icons.inventory_rounded, size: 18), text: "Live Stock"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [_buildIncomingTab(), _buildHistoryTab(), _buildStockTab()],
        ),
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────────

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F1), borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, size: 52, color: const Color(0xFFBDBDBD)),
        ),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
    );
  }

  // ─── TAB 1: INCOMING ─────────────────────────────────────────────────────────

  Widget _buildIncomingTab() {
    return FutureBuilder<List<dynamic>>(
      future: http.get(Uri.parse('http://10.0.2.2:5000/get-pending-invoices/${widget.retailerName}'))
          .then((res) => jsonDecode(res.body)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kTeal));
        }
        List<dynamic> filteredHistory = snapshot.data == null
    ? []
    : snapshot.data!.where((item) {
        return item['drug_name']
                .toString()
                .toLowerCase()
                .contains(historySearch.toLowerCase()) ||

            (item['batch_no'] ?? '')
                .toString()
                .toLowerCase()
                .contains(historySearch.toLowerCase()) ||

            (item['wholesaler_name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(historySearch.toLowerCase()) ||

            (item['gtin_code'] ?? '')
                .toString()
                .toLowerCase()
                .contains(historySearch.toLowerCase());
      }).toList();
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _emptyState(Icons.inbox_outlined, "No Pending Invoices");
        }

        return Column(
         
          children: [
             Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: historySearchCtrl,
        onChanged: (value) {
          setState(() {
            historySearch = value;
          });
        },
        decoration: InputDecoration(
          hintText: "Search Drug, Batch, Wholesaler or GTIN...",
          prefixIcon: const Icon(
            Icons.search,
            color: kTeal,
          ),
          suffixIcon: historySearch.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    historySearchCtrl.clear();
                    setState(() {
                      historySearch = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),


          // Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kTeal, kTealLight]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: kTeal.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              const Icon(Icons.pending_actions_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text("${snapshot.data!.length} Pending Invoice(s)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: const Text("PENDING", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ]),
          ),

          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                var item = filteredHistory[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD1E8D3), width: 1),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.local_shipping_rounded, color: kTeal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("${item['drug_name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 4),
                        Row(children: [
                          _infoBadge("Batch: ${item['batch_no']}", const Color(0xFFEEF2FF), const Color(0xFF3949AB)),
                          const SizedBox(width: 6),
                          _infoBadge("Qty: ${item['quantity']}", const Color(0xFFE8F5E9), kTeal),
                        ]),
                      ])),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => acceptInvoice(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kTeal,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text("ACCEPT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]);
      },
    );
  }

  // ─── TAB 2: HISTORY ───────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
  return FutureBuilder<List<dynamic>>(
    future: http
        .get(
          Uri.parse(
              'http://10.0.2.2:5000/get-accepted-history/${widget.retailerName}'),
        )
        .then((res) => jsonDecode(res.body)),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(color: kTeal),
        );
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return _emptyState(
          Icons.history_toggle_off_rounded,
          "No History Found",
        );
      }

      List<dynamic> filteredHistory = snapshot.data!.where((item) {
        return item['drug_name']
                .toString()
                .toLowerCase()
                .contains(historySearch.toLowerCase()) ||

            (item['batch_no'] ?? '')
                .toString()
                .toLowerCase()
                .contains(historySearch.toLowerCase()) ||

            (item['wholesaler_name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(historySearch.toLowerCase()) ||

            (item['gtin_code'] ?? '')
                .toString()
                .toLowerCase()
                .contains(historySearch.toLowerCase());
      }).toList();

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: historySearchCtrl,
              onChanged: (value) {
                setState(() {
                  historySearch = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search Drug, Batch, Wholesaler or GTIN...",
                prefixIcon: const Icon(
                  Icons.search,
                  color: kTeal,
                ),
                suffixIcon: historySearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          historySearchCtrl.clear();
                          setState(() {
                            historySearch = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                var item = filteredHistory[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFD1E8D3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in_rounded,
                            color: kTeal,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${item['drug_name']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 6),

                              _histRow(
                                Icons.business_outlined,
                                "Wholesaler",
                                "${item['wholesaler_name'] ?? 'N/A'}",
                              ),

                              _histRow(
                                Icons.card_membership_outlined,
                                "License",
                                "${item['wholesaler_license'] ?? 'N/A'}",
                              ),

                              _histRow(
                                Icons.gavel_rounded,
                                "Batch",
                                "${item['batch_no'] ?? 'N/A'}",
                              ),

                              _histRow(
                                Icons.qr_code_rounded,
                                "GTIN",
                                "${item['gtin_code'] ?? 'N/A'}",
                              ),

                              _histRow(
  Icons.calendar_today,
  "Received",
  _fmtDate(item['received_date']),
),

                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  Flexible(
                                    child: _infoBadge(
                                      "Qty: ${item['quantity']}",
                                      const Color(0xFFE8F5E9),
                                      kTeal,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: _infoBadge(
                                      "Exp: ${_fmtDate(item['expiry_date'])}",
                                      const Color(0xFFFFF3E0),
                                      const Color(0xFFE65100),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

  // ─── TAB 3: STOCK ─────────────────────────────────────────────────────────────

  Widget _buildStockTab() {
    return FutureBuilder<List<dynamic>>(
      future: http.get(Uri.parse('http://10.0.2.2:5000/get-retailer-stock/${widget.retailerName}'))
          .then((res) => jsonDecode(res.body)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kTeal));
        }
        List<dynamic> filteredStock = snapshot.data == null
    ? []
    : snapshot.data!.where((item) {
        return item['drug_name']
                .toString()
                .toLowerCase()
                .contains(stockSearch.toLowerCase()) ||

            item['batch_no']
                .toString()
                .toLowerCase()
                .contains(stockSearch.toLowerCase()) ||

            (item['gtin_code'] ?? '')
                .toString()
                .toLowerCase()
                .contains(stockSearch.toLowerCase());
      }).toList();
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _emptyState(Icons.inventory_2_outlined, "Inventory is Empty");
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Stats banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kTeal, kTealLight]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: kTeal.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(children: [
                const Icon(Icons.inventory_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text("${snapshot.data!.length} SKUs in Store",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextField(
    controller: stockSearchCtrl,
    onChanged: (value) {
      setState(() {
        stockSearch = value;
      });
    },
    decoration: InputDecoration(
      hintText: "Search Drug, Batch or GTIN...",
      prefixIcon: const Icon(
        Icons.search,
        color: kTeal,
      ),
      suffixIcon: stockSearch.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                stockSearchCtrl.clear();
                setState(() {
                  stockSearch = '';
                });
              },
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: filteredStock.length,
                itemBuilder: (context, index) {
                  final item = filteredStock[index];
                  final int qty = int.tryParse(item['total_qty'].toString()) ?? 0;
                  final bool isLow = qty <= 10;
                  final Color qtyColor = isLow ? Colors.redAccent : (qty <= 50 ? const Color(0xFFE65100) : kTeal);
                  final Color qtyBg = isLow ? const Color(0xFFFFEBEE) : (qty <= 50 ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isLow ? const Color(0xFFFFCDD2) : const Color(0xFFD1E8D3), width: 1),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: isLow ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.medication_rounded, color: isLow ? Colors.redAccent : kTeal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item['drug_name'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A2E)),
                          overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.gavel_rounded, size: 12, color: Color(0xFF9E9E9E)),
                          const SizedBox(width: 4),
                          Expanded(child: Text(item['batch_no'].toString(),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'monospace'),
                            overflow: TextOverflow.ellipsis)),
                        ]),
                        if (isLow) ...[
                          const SizedBox(height: 4),
                          const Row(children: [
                            Icon(Icons.warning_amber_rounded, size: 12, color: Colors.redAccent),
                            SizedBox(width: 4),
                            Text("Low Stock Alert", style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                          ]),
                        ],
                      ])),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: qtyBg, borderRadius: BorderRadius.circular(10)),
                        child: Column(children: [
                          Text(qty.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: qtyColor, fontSize: 18)),
                          Text("units", style: TextStyle(fontSize: 10, color: qtyColor, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────────

  String _fmtDate(dynamic raw) {
    if (raw == null) return 'N/A';
    final s = raw.toString();
    return s.contains('T') ? s.split('T')[0] : s;
  }

  Widget _histRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        Icon(icon, size: 13, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 5),
        Text("$label: ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF4A4A6A)), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _infoBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg), overflow: TextOverflow.ellipsis),
    );
  }
}