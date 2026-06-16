import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'drug_holders_page.dart';

class DrugTraceabilityPage extends StatefulWidget {
  const DrugTraceabilityPage({super.key});

  @override
  State<DrugTraceabilityPage> createState() => _DrugTraceabilityPageState();
}

class _DrugTraceabilityPageState extends State<DrugTraceabilityPage> {

  static const Color kIndigo = Color(0xFF3949AB);
  static const Color kIndigoLight = Color(0xFF5C6BC0);

  List drugs = [];
  List filteredDrugs = [];
  bool loading = true;
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDrugs();
    searchCtrl.addListener(() => searchDrug(searchCtrl.text));
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future fetchDrugs() async {
    final res = await http.get(Uri.parse('http://10.0.2.2:5000/inspector/drug-traceability'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() { drugs = data; filteredDrugs = data; loading = false; });
    } else {
      setState(() { loading = false; });
    }
  }

  void searchDrug(String value) {
    setState(() {
      filteredDrugs = drugs.where((d) =>
        d['drug_name'].toString().toLowerCase().contains(value.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Drug Traceability", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
        backgroundColor: kIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(children: [
        // ── Gradient header + search ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [kIndigo, kIndigoLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Column(children: [
            // Stats row
            Row(children: [
              Container(padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Drug Traceability", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text("${drugs.length} drugs tracked in system", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 14),
            // Search bar
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
              child: TextField(
                controller: searchCtrl,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                decoration: InputDecoration(
                  hintText: "Search drug by name...",
                  hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: kIndigo, size: 22),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E), size: 20), onPressed: () { searchCtrl.clear(); searchDrug(''); })
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              ),
            ),
          ]),
        ),

        // ── Results count ──
        if (searchCtrl.text.isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(children: [
              const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 6),
              Text("${filteredDrugs.length} result(s) found", style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            ])),

        // ── List ──
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: kIndigo))
              : filteredDrugs.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.medication_outlined, size: 52, color: Color(0xFFBDBDBD))),
                      const SizedBox(height: 16),
                      Text(searchCtrl.text.isNotEmpty ? "No matching drugs found" : "No Drugs Available",
                        style: const TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(searchCtrl.text.isNotEmpty ? "Try a different search term" : "Drugs will appear here.",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ]))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                      itemCount: filteredDrugs.length,
                      itemBuilder: (context, index) {
                        final drug = filteredDrugs[index];
                        return InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => DrugHoldersPage(drugName: drug['drug_name'], batchNo: drug['batch_no']))),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFEEF0F8), width: 1),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                            child: Row(children: [
                              Container(width: 46, height: 46,
                                decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.medication_rounded, color: kIndigo, size: 24)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(drug['drug_name'], overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.gavel_rounded, size: 13, color: Color(0xFF9E9E9E)),
                                  const SizedBox(width: 4),
                                  Text("Batch: ${drug['batch_no']}",
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontFamily: 'monospace')),
                                ]),
                              ])),
                              Container(padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(9)),
                                child: const Icon(Icons.arrow_forward_ios_rounded, color: kIndigo, size: 14)),
                            ]),
                          ),
                        );
                      }),
        ),
      ]),
    );
  }
}