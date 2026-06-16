import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class InwardPage extends StatefulWidget {
  
  final int ownerId;
  final String userEmail;
  const InwardPage({super.key, required this.ownerId, required this.userEmail});
  

  @override
  State<InwardPage> createState() => _InwardPageState();
}

class _InwardPageState extends State<InwardPage> {
  final drugNameCtrl = TextEditingController();
  final batchNoCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final expiryCtrl = TextEditingController();
  final gtinCtrl = TextEditingController();
  final mfgNameCtrl = TextEditingController();
  final mfgLicenseCtrl = TextEditingController();
  final receivedDateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
String historySearch = '';
String stockSearch = '';

final TextEditingController historySearchCtrl = TextEditingController();
final TextEditingController stockSearchCtrl = TextEditingController();
  List<dynamic> rawDrugsList = [];
  List<dynamic> rawMfgList = [];
  String? selectedDrugName;
  String? selectedMfgName;
  bool isDropdownLoading = false;

  static const Color kGreen = Color(0xFF2E7D32);
  static const Color kGreenLight = Color(0xFF43A047);
  static const Color kBg = Color(0xFFF4F7F4);

  @override
  void initState() {
    super.initState();
    _loadAutomationData();
  }

  Future<void> _loadAutomationData() async {
    setState(() => isDropdownLoading = true);
    try {
      final drugRes = await http.get(Uri.parse('http://10.0.2.2:5000/get-all-drugs'));
      final mfgRes = await http.get(Uri.parse('http://10.0.2.2:5000/get-all-manufacturers'));
      if (drugRes.statusCode == 200) rawDrugsList = jsonDecode(drugRes.body);
      if (mfgRes.statusCode == 200) rawMfgList = jsonDecode(mfgRes.body);
    } catch (e) {
      debugPrint("Dropdown lookup error: \$e");
    } finally {
      setState(() => isDropdownLoading = false);
    }
  }

  Future<List<dynamic>> getHistory() async {
    final res = await http.get(Uri.parse('http://10.0.2.2:5000/get-inward-history/${widget.ownerId}'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  Future<List<dynamic>> getStock() async {
    final res = await http.get(Uri.parse('http://10.0.2.2:5000/get-auditable-stock/${widget.ownerId}'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  Future<void> submitInwardData() async {
    if (drugNameCtrl.text.isEmpty || qtyCtrl.text.isEmpty || batchNoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all mandatory fields!"), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating)
      );
      return;
    }

    final url = Uri.parse('http://10.0.2.2:5000/add-inward-stock');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "drug_name": drugNameCtrl.text,
          "batch_no": batchNoCtrl.text,
          "expiry_date": expiryCtrl.text,
          "quantity": int.parse(qtyCtrl.text),
          "owner_id": widget.ownerId,
           "owner_email": widget.userEmail,
          "gtin_code": gtinCtrl.text,
          "manufacturer_name": mfgNameCtrl.text,
          "mfg_license_no": mfgLicenseCtrl.text,
          "received_date": receivedDateCtrl.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎉 Stock Added Successfully!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating)
        );
        drugNameCtrl.clear(); batchNoCtrl.clear(); qtyCtrl.clear();
        expiryCtrl.clear(); gtinCtrl.clear(); mfgNameCtrl.clear(); mfgLicenseCtrl.clear();
        setState(() { selectedDrugName = null; selectedMfgName = null; });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server Error: ${response.body}"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating)
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection Error!"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating)
      );
    }
  }

  Future<void> _selectDatePicker(BuildContext context, TextEditingController targetController) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kGreen, onPrimary: Colors.white, onSurface: Colors.black)
          ),
          child: child!
        );
      }
    );
    if (picked != null) {
      setState(() { targetController.text = picked.toString().split(' ')[0]; });
    }
  }

  // Trims ISO date "2026-06-30T07:00:00.000Z" → "2026-06-30"
  String _formatDate(dynamic raw) {
    if (raw == null) return 'N/A';
    final s = raw.toString();
    if (s.contains('T')) return s.split('T')[0];
    return s;
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────────

  Widget _styledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool filled = false,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: capitalization,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kGreen, size: 20),
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        filled: true,
        fillColor: filled ? const Color(0xFFF1F5F1) : const Color(0xFFF8FBF8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1E4D1), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _styledDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kGreen, size: 20),
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8FBF8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1E4D1), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 6),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kGreen, letterSpacing: 0.8)),
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
          title: const Text("Inward Supply Ledger", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
          backgroundColor: kGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: kGreen,
              child: const TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(icon: Icon(Icons.add_box_rounded, size: 18), text: "Inventory"),
                  Tab(icon: Icon(Icons.history_rounded, size: 18), text: "History"),
                  Tab(icon: Icon(Icons.inventory_rounded, size: 18), text: "Stock"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildForm(),
            _buildHistoryTab(),
            _buildStockTab(),
          ],
        ),
      ),
    );
  }

  // ─── TAB 1: INVENTORY FORM ────────────────────────────────────────────────────

  Widget _buildForm() {
    if (isDropdownLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kGreen),
            SizedBox(height: 14),
            Text("Loading catalog data...", style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kGreen, kGreenLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: kGreen.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.downloading_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Receive New Shipment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(height: 2),
                      Text("Fill details to log incoming stock", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          _sectionLabel("DRUG & MANUFACTURER"),

          _styledDropdown<String>(
            label: "Select Drug Name",
            icon: Icons.medication_rounded,
            value: selectedDrugName,
            items: rawDrugsList.map<DropdownMenuItem<String>>((dynamic item) {
              String name = item['drug_name'] ?? item['brand_name'] ?? 'Unknown';
              return DropdownMenuItem<String>(value: name, child: Text(name));
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedDrugName = newValue;
                drugNameCtrl.text = newValue ?? '';
                var matchingDrug = rawDrugsList.firstWhere(
                  (d) => (d['drug_name'] ?? d['brand_name']) == newValue, orElse: () => null);
                if (matchingDrug != null) gtinCtrl.text = matchingDrug['gtin'] ?? '';
              });
            },
          ),

          const SizedBox(height: 14),

          _styledDropdown<String>(
            label: "Select Manufacturer",
            icon: Icons.factory_outlined,
            value: selectedMfgName,
            items: rawMfgList.map<DropdownMenuItem<String>>((dynamic item) {
              String mfgName = item['name'] ?? 'Unknown';
              return DropdownMenuItem<String>(value: mfgName, child: Text(mfgName));
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedMfgName = newValue;
                mfgNameCtrl.text = newValue ?? '';
                var matchingMfg = rawMfgList.firstWhere((m) => m['name'] == newValue, orElse: () => null);
                if (matchingMfg != null) mfgLicenseCtrl.text = matchingMfg['license_no'] ?? '';
              });
            },
          ),

          const SizedBox(height: 14),

          _styledTextField(
            controller: mfgLicenseCtrl,
            label: "Manufacturer License No.",
            icon: Icons.card_membership_rounded,
            readOnly: true,
            filled: true,
          ),

          const SizedBox(height: 20),
          _sectionLabel("BATCH & QUANTITY"),

          _styledTextField(
            controller: batchNoCtrl,
            label: "Batch Number",
            hint: "e.g., B-NARC901",
            icon: Icons.gavel_rounded,
            capitalization: TextCapitalization.characters,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-\/]'))],
          ),

          const SizedBox(height: 14),

          _styledTextField(
            controller: qtyCtrl,
            label: "Quantity",
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 20),
          _sectionLabel("DATES & TRACKING"),

          _styledTextField(
            controller: expiryCtrl,
            label: "Expiry Date",
            hint: "Tap to select",
            icon: Icons.calendar_month_outlined,
            readOnly: true,
            onTap: () => _selectDatePicker(context, expiryCtrl),
          ),

          const SizedBox(height: 14),

          _styledTextField(
            controller: receivedDateCtrl,
            label: "Received Date",
            icon: Icons.today_rounded,
            readOnly: true,
            onTap: () => _selectDatePicker(context, receivedDateCtrl),
          ),

          const SizedBox(height: 14),

          _styledTextField(
            controller: gtinCtrl,
            label: "GTIN / Serial Code",
            icon: Icons.qr_code_rounded,
            readOnly: true,
            filled: true,
          ),

          const SizedBox(height: 28),

          ElevatedButton.icon(
            onPressed: submitInwardData,
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            label: const Text("SUBMIT TO REGISTER", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: kGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── TAB 2: HISTORY ───────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
  return FutureBuilder<List<dynamic>>(
    future: getHistory(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: kGreen),
              SizedBox(height: 14),
              Text(
                "Loading history...",
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.history_toggle_off_rounded,
                  size: 52,
                  color: Color(0xFFBDBDBD),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "No Inward History Found",
                style: TextStyle(
                  color: Color(0xFF4A4A6A),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Submitted entries will appear here.",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      List<dynamic> filteredHistory = snapshot.data!
          .where((item) =>
              item['drug_name']
                  .toString()
                  .toLowerCase()
                  .contains(historySearch.toLowerCase()) ||

              item['batch_no']
                  .toString()
                  .toLowerCase()
                  .contains(historySearch.toLowerCase()) ||

              (item['manufacturer_name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(historySearch.toLowerCase()) ||

              (item['gtin_code'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(historySearch.toLowerCase()))
          .toList();

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
                    "Search Drug, Batch, Manufacturer or GTIN...",
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

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE8F5E9),
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
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in_rounded,
                            color: kGreen,
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
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              _historyRow(
                                Icons.gavel_rounded,
                                "Batch",
                                "${item['batch_no']}  ·  Qty: ${item['quantity']}",
                              ),
                              _historyRow(
                                Icons.factory_outlined,
                                "Manufacturer",
                                "${item['manufacturer_name'] ?? 'N/A'}",
                              ),
                              _historyRow(
                                Icons.card_membership_rounded,
                                "License",
                                "${item['mfg_license_no'] ?? 'N/A'}",
                              ),
                              _historyRow(
                                Icons.qr_code_rounded,
                                "GTIN",
                                "${item['gtin_code'] ?? 'N/A'}",
                              ),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Flexible(
                                    child: _dateBadge(
                                      Icons.calendar_today_rounded,
                                      "Exp: ${_formatDate(item['expiry_date'])}",
                                      const Color(0xFFFFF3E0),
                                      const Color(0xFFE65100),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: _dateBadge(
                                      Icons.check_circle_outline_rounded,
                                      "Rcvd: ${_formatDate(item['received_date'])}",
                                      const Color(0xFFE8F5E9),
                                      kGreen,
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

  Widget _historyRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 5),
          Text("$label: ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF4A4A6A)), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _dateBadge(IconData icon, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 3: STOCK STATUS ──────────────────────────────────────────────────────

  Widget _buildStockTab() {
    return FutureBuilder<List<dynamic>>(
      future: getStock(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: kGreen),
                SizedBox(height: 14),
                Text("Loading stock data...", style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F1), borderRadius: BorderRadius.circular(20)),
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
List<dynamic> filteredStock = snapshot.data!
    .where((item) =>
        item['drug_name']
            .toString()
            .toLowerCase()
            .contains(stockSearch.toLowerCase()) ||

        item['batch_no']
            .toString()
            .toLowerCase()
            .contains(stockSearch.toLowerCase()))
    .toList();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kGreen, kGreenLight]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: kGreen.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text("${snapshot.data!.length} SKUs in Warehouse",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Text("LIVE STOCK", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
TextField(
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

const SizedBox(height: 12),
              // FIX: Card-based ListView instead of DataTable to avoid horizontal scroll & full-screen overflow
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredStock.length,
                  itemBuilder: (context, index) {
                    final item = filteredStock[index];
                    final int qty = int.tryParse(item['total_qty'].toString()) ?? 0;
                    final Color qtyColor = qty < 10
                        ? Colors.redAccent
                        : (qty < 50 ? const Color(0xFFE65100) : kGreen);
                    final Color qtyBg = qty < 10
                        ? const Color(0xFFFFEBEE)
                        : (qty < 50 ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8F5E9), width: 1),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.medication_rounded, color: kGreen, size: 20),
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: qtyBg, borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              children: [
                                Text(item['total_qty'].toString(),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: qtyColor, fontSize: 18)),
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