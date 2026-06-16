import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RetailerOutwardPage extends StatefulWidget {
  final String retailerName;
  const RetailerOutwardPage({super.key, required this.retailerName});

  @override
  State<RetailerOutwardPage> createState() => _RetailerOutwardPageState();
}

class _RetailerOutwardPageState extends State<RetailerOutwardPage> {
  final _formKey = GlobalKey<FormState>();

  final custNameCtrl = TextEditingController();
  final custPhoneCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final docNameCtrl = TextEditingController();
  final dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  final expiryDateCtrl = TextEditingController();
  final gtinCtrl = TextEditingController();
  final abhaCtrl = TextEditingController();
  final historySearchCtrl = TextEditingController();
final stockSearchCtrl = TextEditingController();

String historySearch = '';
String stockSearch = '';

  List<dynamic> salesHistory = [];
  List<dynamic> liveStock = [];
  List<String> uniqueDrugNames = [];
  List<dynamic> filteredBatches = [];

  String? selectedDrug;
  Map<String, dynamic>? selectedBatchData;

  bool isLoadingHistory = false;
  bool isLoadingStock = false;

  static const Color kTeal = Color(0xFF00695C);
  static const Color kTealLight = Color(0xFF00897B);

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _fetchStock();
  }

  @override
  void dispose() {
    custNameCtrl.dispose(); custPhoneCtrl.dispose(); qtyCtrl.dispose();
    docNameCtrl.dispose(); dateCtrl.dispose(); expiryDateCtrl.dispose();
    gtinCtrl.dispose(); abhaCtrl.dispose();  historySearchCtrl.dispose();
  stockSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() => isLoadingHistory = true);
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:5000/get-retailer-sales-history/${Uri.encodeComponent(widget.retailerName)}'));
      if (res.statusCode == 200 && mounted) setState(() => salesHistory = jsonDecode(res.body));
    } catch (e) { debugPrint("History Error: $e"); }
    setState(() => isLoadingHistory = false);
  }

  Future<void> _fetchStock() async {
    setState(() => isLoadingStock = true);
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:5000/get-retailer-stock/${Uri.encodeComponent(widget.retailerName)}'));
      if (res.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          liveStock = data;
          uniqueDrugNames = data.map((item) => item['drug_name'].toString()).toSet().toList();
        });
      }
    } catch (e) { debugPrint("Stock Error: $e"); }
    setState(() => isLoadingStock = false);
  }

  void _onDrugChanged(String? val) {
    setState(() {
      selectedDrug = val;
      selectedBatchData = null;
      expiryDateCtrl.clear();
      gtinCtrl.clear();
      filteredBatches = liveStock.where((item) => item['drug_name'] == val).toList();
    });
  }

  void _onBatchChanged(Map<String, dynamic>? val) {
    setState(() {
      selectedBatchData = val;
      expiryDateCtrl.text = val?['expiry_date'] != null ? val!['expiry_date'].toString().split('T')[0] : 'N/A';
      gtinCtrl.text = val?['gtin_code']?.toString() ?? 'N/A';
    });
  }

  Future<void> sellDrug() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.parse(qtyCtrl.text);
    final availableStock = selectedBatchData != null ? double.parse(selectedBatchData!['total_qty'].toString()).toInt() : 0;
    if (qty > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Insufficient stock! Only $availableStock available."),
        backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      return;
    }
    if (gtinCtrl.text == 'N/A' || expiryDateCtrl.text == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Error: Batch details missing!"), behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/retailer-sell-drug'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "retailer_name": widget.retailerName,
          "customer_name": custNameCtrl.text,
          "customer_phone": custPhoneCtrl.text,
          "abha_id": abhaCtrl.text,
          "drug_name": selectedDrug,
          "batch_no": selectedBatchData?['batch_no'],
          "quantity": int.parse(qtyCtrl.text),
          "doctor_name": docNameCtrl.text,
          "expiry_date": expiryDateCtrl.text,
          "gtin_code": gtinCtrl.text,
          "sale_date": dateCtrl.text,
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Sold Successfully!"), backgroundColor: Color(0xFF2E7D32), behavior: SnackBarBehavior.floating));
        _formKey.currentState!.reset();
        setState(() { selectedDrug = null; selectedBatchData = null; expiryDateCtrl.clear(); gtinCtrl.clear(); });
        _fetchHistory(); _fetchStock();
      }
    } catch (e) { debugPrint("Sell Error: $e"); }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────────

  Widget _styledField({
    required TextEditingController controller, required String label, required IconData icon,
    TextInputType? keyboardType, bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller, readOnly: readOnly, keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kTeal, size: 20),
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF1F5F1) : const Color(0xFFF4FAF8),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1E8D3), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kTeal, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _styledDropdownField<T>({
    required String label, required IconData icon, required T? value,
    required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged,
    String? Function(T?)? validator, String? helperText,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true, value: value,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kTeal, size: 20),
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        helperText: helperText,
        helperStyle: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
        filled: true, fillColor: const Color(0xFFF4FAF8),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1E8D3), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kTeal, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items, onChanged: onChanged, validator: validator,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kTeal, letterSpacing: 0.8)),
      ]),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFFF1F5F1), borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, size: 52, color: const Color(0xFFBDBDBD))),
      const SizedBox(height: 16),
      Text(message, style: const TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 15)),
    ]));
  }

  Widget _infoBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg), overflow: TextOverflow.ellipsis),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          title: const Text("Outward Sales Ledger", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
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
                  Tab(icon: Icon(Icons.point_of_sale_rounded, size: 18), text: "Sell"),
                  Tab(icon: Icon(Icons.history_rounded, size: 18), text: "History"),
                  Tab(icon: Icon(Icons.inventory_rounded, size: 18), text: "Stock"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(children: [_buildSellDrugForm(), _buildSalesHistoryTab(), _buildLiveStockTab()]),
      ),
    );
  }

  // ─── TAB 1: SELL FORM ─────────────────────────────────────────────────────────

  Widget _buildSellDrugForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kTeal, kTealLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: kTeal.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Sell Narcotic Drug", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 2),
                Text("Fill patient & drug details to record sale", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ]),
          ),

          const SizedBox(height: 22),
          _sectionLabel("PATIENT INFORMATION"),
          _styledField(controller: custNameCtrl, label: "Patient / Customer Name", icon: Icons.person_outline_rounded,
            validator: (v) => v!.isEmpty ? "Required" : null),
          const SizedBox(height: 14),
          _styledField(controller: custPhoneCtrl, label: "Phone Number", icon: Icons.phone_outlined, keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.length != 10) ? "Enter 10 digit number" : null),
          const SizedBox(height: 14),
          _styledField(controller: docNameCtrl, label: "Prescribing Doctor Name", icon: Icons.medical_services_outlined,
            validator: (v) => v!.isEmpty ? "Required" : null),
          const SizedBox(height: 14),
          TextFormField(
            controller: abhaCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              labelText: "ABHA ID (14 digits)",
              prefixIcon: const Icon(Icons.badge_outlined, color: kTeal, size: 20),
              labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              filled: true, fillColor: const Color(0xFFF4FAF8),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1E8D3), width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kTeal, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return "ABHA ID Required";
              if (!RegExp(r'^\d{14}$').hasMatch(v)) return "ABHA ID must be 14 digits";
              return null;
            },
          ),

          const SizedBox(height: 20),
          _sectionLabel("DRUG & BATCH"),
          _styledDropdownField<String>(
            label: "Select Drug",
            icon: Icons.medication_outlined,
            value: selectedDrug,
            items: uniqueDrugNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
            onChanged: _onDrugChanged,
            validator: (v) => v == null ? "Required" : null,
          ),
          const SizedBox(height: 14),
          _styledDropdownField<Map<String, dynamic>>(
            label: "Select Batch",
            icon: Icons.layers_outlined,
            value: selectedBatchData,
            helperText: selectedBatchData != null ? "✅ Available Stock: ${selectedBatchData!['total_qty']} Units" : null,
            items: filteredBatches.map((b) => DropdownMenuItem(
              value: b as Map<String, dynamic>,
              child: Text("Batch: ${b['batch_no']}"),
            )).toList(),
            onChanged: _onBatchChanged,
            validator: (v) => v == null ? "Required" : null,
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _styledField(controller: expiryDateCtrl, label: "Expiry Date", icon: Icons.event_outlined, readOnly: true)),
            const SizedBox(width: 10),
            Expanded(child: _styledField(controller: gtinCtrl, label: "GTIN", icon: Icons.qr_code_rounded, readOnly: true)),
          ]),

          const SizedBox(height: 20),
          _sectionLabel("SALE DETAILS"),
          TextFormField(
            controller: qtyCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              labelText: "Quantity to Sell",
              prefixIcon: const Icon(Icons.pin_outlined, color: kTeal, size: 20),
              labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              filled: true, fillColor: const Color(0xFFF4FAF8),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1E8D3), width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kTeal, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Enter quantity";
              final parsedQty = int.tryParse(v);
              if (parsedQty == null || parsedQty <= 0) return "Enter valid quantity";
              if (selectedBatchData != null) {
                final available = double.parse(selectedBatchData!['total_qty'].toString()).toInt();
                if (parsedQty > available) return "Insufficient stock! Only $available left.";
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _styledField(controller: dateCtrl, label: "Date of Sale", icon: Icons.calendar_today_outlined, readOnly: true),

          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: sellDrug,
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            label: const Text("SUBMIT & SELL", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: kTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ─── TAB 2: SALES HISTORY ─────────────────────────────────────────────────────

  Widget _buildSalesHistoryTab() {
  List<dynamic> filteredHistory = salesHistory.where((item) {
    return (item['customer_name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(historySearch.toLowerCase()) ||

        (item['abha_id'] ?? '')
            .toString()
            .toLowerCase()
            .contains(historySearch.toLowerCase()) ||

        (item['doctor_name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(historySearch.toLowerCase()) ||

        (item['drug_name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(historySearch.toLowerCase()) ||

        (item['batch_no'] ?? '')
            .toString()
            .toLowerCase()
            .contains(historySearch.toLowerCase()) ||

        (item['gtin_code'] ?? '')
            .toString()
            .toLowerCase()
            .contains(historySearch.toLowerCase());
  }).toList();

  

  if (isLoadingHistory) {
    return const Center(
      child: CircularProgressIndicator(color: kTeal),
    );
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
            hintText:
                "Search Customer, ABHA, Doctor, Drug, Batch or GTIN...",
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
        child: filteredHistory.isEmpty
            ? _emptyState(
                Icons.search_off,
                "No matching records found",
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                              Icons.receipt_rounded,
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
                                  "${item['customer_name']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 5),

                                _saleRow(
                                  Icons.badge_outlined,
                                  "ABHA ID",
                                  "${item['abha_id']}",
                                ),
                                _saleRow(
                                  Icons.medical_services_outlined,
                                  "Doctor",
                                  "${item['doctor_name']}",
                                ),
                                _saleRow(
                                  Icons.medication_rounded,
                                  "Drug",
                                  "${item['drug_name']}",
                                ),
                                _saleRow(
                                  Icons.gavel_rounded,
                                  "Batch",
                                  "${item['batch_no']}",
                                ),
                                _saleRow(
                                  Icons.qr_code_rounded,
                                  "GTIN",
                                  "${item['gtin_code']}",
                                ),
                                _saleRow(
  Icons.calendar_today_outlined,
  "Sale Date",
  _fmtDate(item['sale_date']),
),

                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    _infoBadge(
                                      "Qty: ${item['quantity']}",
                                      const Color(0xFFE8F5E9),
                                      kTeal,
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
}

  Widget _saleRow(IconData icon, String label, String value) {
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

  String _fmtDate(dynamic raw) {
    if (raw == null) return 'N/A';
    final s = raw.toString();
    return s.contains('T') ? s.split('T')[0] : s;
  }

  // ─── TAB 3: LIVE STOCK ────────────────────────────────────────────────────────

  Widget _buildLiveStockTab() {
    List<dynamic> filteredStock = liveStock.where((item) {
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
    if (isLoadingStock) return const Center(child: CircularProgressIndicator(color: kTeal));
    if (liveStock.isEmpty) return _emptyState(Icons.inventory_2_outlined, "Inventory is Empty");

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
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
            Text("${liveStock.length} SKUs in Store",
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
  }
}