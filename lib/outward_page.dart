import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OutwardPage extends StatefulWidget {
  final int ownerId;
  final String wholesalerName;
  final String wholesalerGstin;
  final String wholesalerLicense;
  const OutwardPage({
    super.key,
    required this.ownerId,
    required this.wholesalerName,
    required this.wholesalerGstin,
     required this.wholesalerLicense,
  });
  @override
  State<OutwardPage> createState() => _OutwardPageState();
}

class _OutwardPageState extends State<OutwardPage> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> retailers = [];
  List<dynamic> localStockList = [];
  List<String> uniqueDrugNames = [];
  List<dynamic> filteredBatches = [];

  String? selectedRetailer;
  String? selectedDrug;
  Map<String, dynamic>? selectedBatchData;

  final retailerLicenseCtrl = TextEditingController();
  final retailerShopCtrl = TextEditingController();
  final gtinCtrl = TextEditingController();
  final batchNoCtrl = TextEditingController();
  final expiryDateCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final saleDateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
 final historySearchCtrl = TextEditingController();
final stockSearchCtrl = TextEditingController();

String historySearch = '';
String stockSearch = '';
  // ─── COLORS ──────────────────────────────────────────────────────────────────
  static const Color kOrange = Color(0xFFE65100);
  static const Color kOrangeLight = Color(0xFFFF6D00);
  static const Color kBg = Color(0xFFFFF8F4);

  @override
  void initState() {
    super.initState();
    fetchRetailers();
    fetchLiveStockData();
  }

  @override
  void dispose() {
    retailerLicenseCtrl.dispose();
    retailerShopCtrl.dispose();
    gtinCtrl.dispose();
    batchNoCtrl.dispose();
    expiryDateCtrl.dispose();
    qtyCtrl.dispose();
    saleDateCtrl.dispose();
     historySearchCtrl.dispose();
  stockSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchRetailers() async {
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:5000/get-retailers'));
      if (res.statusCode == 200) {
        setState(() { retailers = jsonDecode(res.body); });
      }
    } catch (e) {
      debugPrint("Error fetching retailers: $e");
    }
  }

  Future<void> fetchLiveStockData() async {
    try {
      final res = await http.get(Uri.parse('http://10.0.2.2:5000/get-auditable-stock/${widget.ownerId}'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          localStockList = data;
          uniqueDrugNames = data
              .where((item) => (double.parse(item['total_qty'].toString())) > 0)
              .map((item) => item['drug_name'].toString())
              .toSet()
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching stock mapping: $e");
    }
  }

  Future<void> _fetchGtin(String drugName, String batchNo) async {
    try {
      final url = 'http://10.0.2.2:5000/get-gtin-by-batch/${Uri.encodeComponent(drugName)}/${Uri.encodeComponent(batchNo)}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() { gtinCtrl.text = data['gtin_code']?.toString() ?? ''; });
      }
    } catch (e) {
      debugPrint("GTIN Fetch Error: $e");
    }
  }

  void _onDrugChanged(String? drugName) {
    if (drugName == null) return;
    setState(() {
      selectedDrug = drugName;
      selectedBatchData = null;
      batchNoCtrl.clear();
      expiryDateCtrl.clear();
      gtinCtrl.clear();
      filteredBatches = localStockList
          .where((item) => item['drug_name'] == drugName && (double.parse(item['total_qty'].toString())) > 0)
          .toList();
    });
  }

  void _onBatchChanged(Map<String, dynamic>? batchData) {
    if (batchData == null) return;
    setState(() {
      selectedBatchData = batchData;
      batchNoCtrl.text = batchData['batch_no']?.toString() ?? '';
      if (batchData['expiry_date'] != null) {
        expiryDateCtrl.text = batchData['expiry_date'].toString().split('T')[0];
      } else {
        expiryDateCtrl.text = '';
      }
    });
    _fetchGtin(batchData['drug_name'], batchData['batch_no']);
  }

  Future<void> submitOutward() async {
    if (!_formKey.currentState!.validate()) return;
     
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/add-outward-transaction'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "wholesaler_id": widget.ownerId,
          "wholesaler_name": widget.wholesalerName,
          "wholesaler_gstin": widget.wholesalerGstin,
          "wholesaler_license": widget.wholesalerLicense,
          "retailer_name": selectedRetailer,
          "retailer_license": retailerLicenseCtrl.text,
          "shop_name": retailerShopCtrl.text,
          "drug_name": selectedDrug,
          "batch_no": batchNoCtrl.text,
          "quantity": int.parse(qtyCtrl.text),
          "sale_date": saleDateCtrl.text,
          "expiry_date": expiryDateCtrl.text,
          "gtin_code": gtinCtrl.text,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Stock Invoice Dispatched Successfully!"),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _formKey.currentState!.reset();
        qtyCtrl.clear();
        retailerLicenseCtrl.clear();
        gtinCtrl.clear();
        expiryDateCtrl.clear();
        setState(() {
          selectedRetailer = null;
          selectedDrug = null;
          selectedBatchData = null;
          filteredBatches = [];
        });
        fetchLiveStockData();
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _styledReadonlyField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kOrange, size: 20),
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFFFF3EE),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFCCB0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _styledDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    String? helperText,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      value: value,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kOrange, size: 20),
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        helperText: helperText,
        helperStyle: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFFFF8F4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFCCB0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0CC), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kOrange.withOpacity(0.06),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: const Border(bottom: BorderSide(color: Color(0xFFFFE0CC), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: kOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 17, color: kOrange),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  

  // ─── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          title: const Text("Outward Management", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 19)),
          backgroundColor: kOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: kOrange,
              child: const TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(icon: Icon(Icons.upload_file_rounded, size: 18), text: "Sell Drug"),
                  Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: "Sales History"),
                  Tab(icon: Icon(Icons.inventory_rounded, size: 18), text: "Live Stock"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildSellForm(),
            _buildSalesHistory(),
            _buildCurrentStock(),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: SELL FORM ─────────────────────────────────────────────────────────

  Widget _buildSellForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kOrange, kOrangeLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: kOrange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dispatch New Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 2),
                        Text("Fill details to generate outward invoice", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Retailer Details Card
            _sectionCard(
              title: "Retailer Details",
              icon: Icons.storefront_rounded,
              children: [
                _styledDropdownField<String>(
                  label: "Select Target Retailer",
                  icon: Icons.person_search_rounded,
                  value: selectedRetailer,
                  items: retailers.map((r) => DropdownMenuItem<String>(
                    value: r['full_name'].toString(),
                    child: Text(r['full_name'].toString()),
                    onTap: () {
                      setState(() {
                        retailerLicenseCtrl.text = r['drug_license_no']?.toString() ?? '';
                        retailerShopCtrl.text = r['shop_name']?.toString() ?? '';
                      });
                    },
                  )).toList(),
                  onChanged: (val) => setState(() => selectedRetailer = val),
                  validator: (value) => value == null ? 'Please select a retailer' : null,
                ),
                const SizedBox(height: 14),
                _styledReadonlyField(controller: retailerLicenseCtrl, label: "Retailer Drug License", icon: Icons.verified_user_outlined),
                const SizedBox(height: 14),
                _styledReadonlyField(controller: retailerShopCtrl, label: "Retailer Shop Name", icon: Icons.storefront_outlined),
              ],
            ),

            const SizedBox(height: 16),

            // Drug & Batch Card
            _sectionCard(
              title: "Drug & Batch Authentication",
              icon: Icons.medication_rounded,
              children: [
                _styledDropdownField<String>(
                  label: "Select Narcotic Drug",
                  icon: Icons.medication_outlined,
                  value: selectedDrug,
                  items: uniqueDrugNames.map((name) => DropdownMenuItem<String>(value: name, child: Text(name))).toList(),
                  onChanged: _onDrugChanged,
                  validator: (value) => value == null ? 'Please select a drug' : null,
                ),
                const SizedBox(height: 14),
                _styledDropdownField<Map<String, dynamic>>(
                  label: "Select Available Batch",
                  icon: Icons.layers_outlined,
                  value: selectedBatchData,
                  helperText: selectedBatchData != null ? "✅ Available Stock: ${selectedBatchData!['total_qty']} Units" : null,
                  items: filteredBatches.map((b) => DropdownMenuItem<Map<String, dynamic>>(
                    value: b as Map<String, dynamic>,
                    child: Text("Batch: ${b['batch_no']}  ·  Stock: ${b['total_qty']}"),
                  )).toList(),
                  onChanged: _onBatchChanged,
                  validator: (value) => value == null ? 'Please select a batch code' : null,
                ),
                const SizedBox(height: 14),
                // GTIN + Expiry side by side
                Row(
                  children: [
                    Expanded(
                      child: _styledReadonlyField(controller: gtinCtrl, label: "Drug GTIN", icon: Icons.qr_code_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _styledReadonlyField(controller: expiryDateCtrl, label: "Expiry Date", icon: Icons.event_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Quantity field
                TextFormField(
                  controller: qtyCtrl,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                  decoration: InputDecoration(
                    labelText: "Quantity to Dispatch",
                    prefixIcon: const Icon(Icons.unarchive_outlined, color: kOrange, size: 20),
                    labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFFFF8F4),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFCCB0), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kOrange, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter quantity';
                    final parsedQty = int.tryParse(value);
                    if (parsedQty == null || parsedQty <= 0) return 'Enter a valid positive number';
                    if (selectedBatchData != null) {
                      final currentLimit = double.parse(selectedBatchData!['total_qty'].toString()).toInt();
                      if (parsedQty > currentLimit) return 'Insufficient stock! Only $currentLimit left.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _styledReadonlyField(controller: saleDateCtrl, label: "Date of Dispatch", icon: Icons.calendar_today_outlined),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: submitOutward,
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              label: const Text("GENERATE & DISPATCH INVOICE", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                backgroundColor: kOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2: SALES HISTORY ─────────────────────────────────────────────────────

 Widget _buildSalesHistory() {
  return FutureBuilder<List<dynamic>>(
    future: http
        .get(Uri.parse(
            'http://10.0.2.2:5000/get-outward-history/${widget.ownerId}'))
        .then((res) => jsonDecode(res.body)),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: kOrange),
              SizedBox(height: 14),
              Text(
                "Loading sales history...",
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      List<dynamic> filteredHistory = snapshot.data == null
          ? []
          : snapshot.data!.where((item) {
              return item['drug_name']
                      .toString()
                      .toLowerCase()
                      .contains(historySearch.toLowerCase()) ||
                  item['batch_no']
                      .toString()
                      .toLowerCase()
                      .contains(historySearch.toLowerCase()) ||
                  item['retailer_name']
                      .toString()
                      .toLowerCase()
                      .contains(historySearch.toLowerCase()) ||
                  item['shop_name']
                      .toString()
                      .toLowerCase()
                      .contains(historySearch.toLowerCase()) ||
                  item['gtin_code']  
                        .toString()
    .toLowerCase()
    .contains(historySearch.toLowerCase()) ;
            }).toList();

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 52,
                  color: Color(0xFFBDBDBD),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "No Sales History Found",
                style: TextStyle(
                  color: Color(0xFF4A4A6A),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Dispatched orders will appear here.",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
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
                hintText: "Search Drug, Retailer, Shop, Batch or GTIN ...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              itemCount: filteredHistory.length,
              itemBuilder: (context, index) {
                var item = filteredHistory[index];

                bool isPending = item['status'] == 'Pending';

                final statusColor = isPending
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF16A34A);

                final statusBg = isPending
                    ? const Color(0xFFFFFBEB)
                    : const Color(0xFFF0FDF4);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFE0CC),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
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
                            color: isPending
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_shipping_rounded,
                            color: statusColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${item['drug_name']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item['status'],
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _salesRow(
                                Icons.storefront_outlined,
                                "To",
                                "${item['retailer_name']}",
                              ),
                              _salesRow(
                                Icons.store_outlined,
                                "Shop",
                                "${item['shop_name']}",
                              ),
                              _salesRow(
                                Icons.card_membership_outlined,
                                "License",
                                "${item['retailer_license']}",
                              ),
                              _salesRow(
  Icons.qr_code_rounded,
  "GTIN",
  "${item['gtin_code'] ?? 'N/A'}",
),
_salesRow(
  Icons.calendar_today_outlined,
  "Sale Date",
  item['sale_date'] != null
      ? item['sale_date'].toString().split('T')[0]
      : 'N/A',
),

_salesRow(
  Icons.event_outlined,
  "Expiry",
  item['expiry_date'] != null
      ? item['expiry_date'].toString().split('T')[0]
      : 'N/A',
),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _infoBadge(
                                    "Qty: ${item['quantity']}",
                                    const Color(0xFFFFF3EE),
                                    kOrange,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: _infoBadge(
                                      "Batch: ${item['batch_no']}",
                                      const Color(0xFFF0F2FF),
                                      const Color(0xFF3949AB),
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

  Widget _salesRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 5),
          Text("$label: ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF4A4A6A)), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _infoBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg), overflow: TextOverflow.ellipsis),
    );
  }

  // ─── TAB 3: LIVE STOCK ────────────────────────────────────────────────────────

  Widget _buildCurrentStock() {
    return FutureBuilder<List<dynamic>>(
      future: http.get(Uri.parse('http://10.0.2.2:5000/get-auditable-stock/${widget.ownerId}'))
          .then((res) => jsonDecode(res.body)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: kOrange),
                SizedBox(height: 14),
                Text("Loading inventory...", style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              ],
            ),
          );
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
                .contains(stockSearch.toLowerCase());
      }).toList();

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3EE), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.inventory_2_outlined, size: 52, color: Color(0xFFBDBDBD)),
                ),
                const SizedBox(height: 16),
                const Text("Inventory is Empty", style: TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text("Stock entries will appear here.", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kOrange, kOrangeLight]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: kOrange.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text("${snapshot.data!.length} SKUs Available",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Text("LIVE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ],
                ),
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
      hintText: "Search Drug or Batch...",
      prefixIcon: const Icon(Icons.search),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),
              // Card-based list (no DataTable, no horizontal scroll)
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredStock.length,
                  itemBuilder: (context, index) {
                    final item = filteredStock[index];
                    final int qty = double.parse(item['total_qty'].toString()).toInt();
                    final bool isLow = qty <= 10;
                    final Color qtyColor = isLow ? Colors.redAccent : (qty <= 50 ? kOrange : const Color(0xFF2E7D32));
                    final Color qtyBg = isLow ? const Color(0xFFFFEBEE) : (qty <= 50 ? const Color(0xFFFFF3EE) : const Color(0xFFE8F5E9));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLow ? const Color(0xFFFFCDD2) : const Color(0xFFFFE0CC),
                          width: 1,
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: isLow ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3EE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.medication_rounded, color: isLow ? Colors.redAccent : kOrange, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['drug_name'].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A2E)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.gavel_rounded, size: 12, color: Color(0xFF9E9E9E)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item['batch_no'].toString(),
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'monospace'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isLow) ...[
                                  const SizedBox(height: 4),
                                  const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, size: 12, color: Colors.redAccent),
                                      SizedBox(width: 4),
                                      Text("Low Stock Alert", style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: qtyBg, borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              children: [
                                Text(qty.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: qtyColor, fontSize: 18)),
                                Text("units", style: TextStyle(fontSize: 10, color: qtyColor, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}