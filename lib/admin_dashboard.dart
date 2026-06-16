import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'inspector_visit_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

class AdminDashboard extends StatefulWidget {
  final String adminName;
  final String adminEmail;

  const AdminDashboard({
    super.key,
    required this.adminName,
    required this.adminEmail,
  });
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color kIndigo = Color(0xFF3949AB);
  static const Color kIndigoLight = Color(0xFF5C6BC0);

  Map<String, dynamic> stats = {"total_users": 0, "total_audits": 0};
  int riskCount = 0;
  bool isLoading = true;
  String searchQuery = "";

  // Tab index tracking for drawer highlight
  int _currentTab = 0;
  

  @override
  void initState() {
    super.initState();
    fetchStats();
    fetchRiskCount();
  }

  Future<void> fetchRiskCount() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/admin/high-risk-count'));
      if (response.statusCode == 200) setState(() { riskCount = jsonDecode(response.body)['risk_count']; });
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _showRiskListDialog() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/admin/high-risk-list'));
      if (response.statusCode == 200) {
        List riskUsers = jsonDecode(response.body);
        showDialog(context: context, builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFB71C1C), Color(0xFFE53935)]),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
                child: Row(children: [
                  const CircleAvatar(radius: 18, backgroundColor: Colors.white24, child: Icon(Icons.warning_rounded, color: Colors.white, size: 20)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("High Risk Users", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("${riskUsers.length} flagged", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ])),
              SizedBox(height: 300, child: ListView.builder(
                padding: const EdgeInsets.all(12),
                shrinkWrap: true,
                itemCount: riskUsers.length,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFCDD2))),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(riskUsers[index]['target_user_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1A1A2E))),
                      Text("Compliance: ${riskUsers[index]['compliance_score']}%", style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                    ])),
                  ]),
                ),
              )),
              Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: kIndigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                  child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
            ]),
          ),
        ));
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  Future<void> _generateComplianceReport(List data) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) => pw.Column(children: [
      pw.Text("Compliance Summary Report", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 20),
      pw.Table.fromTextArray(
        headers: ['Name', 'Role', 'Score %'],
        data: data.map((i) => [i['target_user_name'], i['target_role'], "${i['compliance_score']}%"]).toList()),
    ])));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> fetchStats() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/admin/stats'));
      if (response.statusCode == 200) setState(() { stats = jsonDecode(response.body); isLoading = false; });
    } catch (e) { debugPrint("Error: $e"); }
  }

  Future<void> toggleUserStatus(dynamic userId, String newStatus, String userName) async {
    if (userId == null || userId == 0) return;
    try {
      final response = await http.post(Uri.parse('http://10.0.2.2:5000/api/admin/toggle-user-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': userId, 'status': newStatus}));
      if (response.statusCode == 200) {
        await http.post(Uri.parse('http://10.0.2.2:5000/api/admin/log-action'),
          headers: {'Content-Type': 'application/json'},
         body: jsonEncode({
  'admin_email': widget.adminEmail,
  'action': 'Status set to $newStatus',
  'target_user': userName
}));
        fetchRiskCount(); setState(() {});
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  // ── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _searchBar({required String hint, required void Function(String) onChanged}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E4F0), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: kIndigo, size: 20),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13)),
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(20)),
      child: Icon(icon, size: 52, color: const Color(0xFFBDBDBD))),
    const SizedBox(height: 16),
    Text(msg, style: const TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 15)),
  ]));

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4, left: 14),
    child: Row(children: [
      Container(width: 4, height: 16, decoration: BoxDecoration(color: kIndigo, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kIndigo, letterSpacing: 0.5)),
    ]));

  // ── STATS ─────────────────────────────────────────────────────────────────

  Widget _buildStatsView() {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: kIndigo));
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kIndigo, kIndigoLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: kIndigo.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28)),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Admin Control Panel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 3),
              Text("Narcotic Drug Tracking System", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ])),
        const SizedBox(height: 22),
        _sectionLabel("OVERVIEW"),
        Row(children: [
          Expanded(child: _statCard("Total Users", stats['total_users'].toString(), Icons.people_rounded, kIndigo, const Color(0xFFF0F2FF))),
          const SizedBox(width: 12),
          Expanded(child: _statCard("Total Audits", stats['total_audits'].toString(), Icons.assignment_rounded, const Color(0xFF2E7D32), const Color(0xFFE8F5E9))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statCard("High Risk", riskCount.toString(), Icons.warning_rounded, const Color(0xFFB71C1C), const Color(0xFFFFEBEE))),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: _showRiskListDialog,
            child: _statCard("View Alerts", "Tap", Icons.notifications_active_rounded, const Color(0xFFE65100), const Color(0xFFFFF3E0)))),
        ]),
      ]),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 22, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
        ])),
      ]),
    );
  }

  // ── USERS ─────────────────────────────────────────────────────────────────

  Widget _buildUserView() {
    return DefaultTabController(length: 2, child: Column(children: [
      Container(color: kIndigo, child: const TabBar(indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
        tabs: [Tab(icon: Icon(Icons.business_rounded, size: 16), text: "Wholesalers"), Tab(icon: Icon(Icons.storefront_rounded, size: 16), text: "Retailers")])),
      Expanded(child: TabBarView(children: [
        _listBuilder('http://10.0.2.2:5000/api/admin/users-list', 'Wholesaler'),
        _listBuilder('http://10.0.2.2:5000/api/admin/users-list', 'Retailer'),
      ])),
    ]));
  }

  // ── AUDITS ────────────────────────────────────────────────────────────────

  Widget _buildAuditView() {
    return DefaultTabController(length: 2, child: Column(children: [
      Container(color: kIndigo, child: const TabBar(indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
        tabs: [Tab(icon: Icon(Icons.business_rounded, size: 16), text: "Wholesaler Audits"), Tab(icon: Icon(Icons.storefront_rounded, size: 16), text: "Retailer Audits")])),
      Expanded(child: TabBarView(children: [
        _listBuilder('http://10.0.2.2:5000/api/admin/all-audits', 'Wholesaler', isAudit: true),
        _listBuilder('http://10.0.2.2:5000/api/admin/all-audits', 'Retailer', isAudit: true),
      ])),
    ]));
  }

  Widget _listBuilder(String apiUrl, String roleFilter, {bool isAudit = false}) {
    String localSearch = "";
    return StatefulBuilder(builder: (context, setSt) => Column(children: [
      _searchBar(hint: "Search ${isAudit ? 'audits' : 'users'}...", onChanged: (v) => setSt(() => localSearch = v.toLowerCase())),
      Expanded(child: FutureBuilder(
        future: http.get(Uri.parse(apiUrl)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kIndigo));
          var data = jsonDecode((snapshot.data as http.Response).body) as List;
          var filtered = data.where((item) {
            String name = isAudit ? (item['target_user_name'] ?? '') : (item['full_name'] ?? '');
            bool matchRole = isAudit ? (item['target_role'] == roleFilter) : (item['role'] == roleFilter);
            return matchRole && name.toLowerCase().contains(localSearch);
          }).toList();
          if (filtered.isEmpty) return _emptyState(Icons.search_off_rounded, "No records found");
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              String status = item['status'] ?? 'Active';
              bool isBlocked = status == 'Blocked';
              bool isMatched = (item['overall_status'] ?? '') == 'MATCHED';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFEEF0F8)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 7, offset: const Offset(0, 2))]),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(radius: 20, backgroundColor: kIndigo.withOpacity(0.1),
                    child: Text((isAudit ? (item['target_user_name'] ?? 'A') : (item['full_name'] ?? 'U')).substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kIndigo))),
                  title: Text(isAudit ? item['target_user_name'] : item['full_name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1A1A2E))),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 3),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAudit ? (isMatched ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE)) : (isBlocked ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9)),
                          borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          isAudit ? (item['overall_status'] ?? '') : status,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: isAudit ? (isMatched ? const Color(0xFF2E7D32) : Colors.redAccent) : (isBlocked ? Colors.redAccent : const Color(0xFF2E7D32))))),
                    ])),
                  trailing: !isAudit
                      ? GestureDetector(
                          onTap: () => toggleUserStatus(item['id'], isBlocked ? 'Active' : 'Blocked', item['full_name']),
                          child: Container(padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(color: isBlocked ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(9)),
                            child: Icon(isBlocked ? Icons.lock_rounded : Icons.lock_open_rounded, color: isBlocked ? Colors.redAccent : const Color(0xFF2E7D32), size: 18)))
                      : const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9E9E9E), size: 14),
                  onTap: isAudit ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => AuditDetailScreen(visitId: item['id']))) : null,
                ),
              );
            },
          );
        },
      )),
    ]));
  }

  // ── INSPECTORS ────────────────────────────────────────────────────────────

  Widget _buildInspectorView() {
    String localSearch = "";
    return StatefulBuilder(builder: (context, setSt) => Column(children: [
      _searchBar(hint: "Search inspectors...", onChanged: (v) => setSt(() => localSearch = v.toLowerCase())),
      Expanded(child: FutureBuilder(
        future: http.get(Uri.parse('http://10.0.2.2:5000/api/admin/inspector-performance')),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kIndigo));
          var data = jsonDecode((snapshot.data as http.Response).body) as List;
          var filtered = data.where((i) => (i['inspector_name'] ?? '').toString().toLowerCase().contains(localSearch)).toList();
          if (filtered.isEmpty) return _emptyState(Icons.search_off_rounded, "No inspectors found");
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFEEF0F8)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 7, offset: const Offset(0, 2))]),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(radius: 20, backgroundColor: kIndigo.withOpacity(0.1),
                    child: Text((item['inspector_name'] ?? 'I').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kIndigo))),
                  title: Text(item['inspector_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1A1A2E))),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 3),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(6)),
                        child: Text("${item['total_visits']} visits", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kIndigo))),
                    ])),
                  trailing: Container(padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.arrow_forward_ios_rounded, color: kIndigo, size: 14)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InspectorVisitDetails(inspectorName: item['inspector_name']))),
                ),
              );
            },
          );
        },
      )),
    ]));
  }

  // ── COMPLIANCE ────────────────────────────────────────────────────────────

  Widget _buildComplianceView() {
    String localSearch = "";
    return StatefulBuilder(builder: (context, setSt) => Column(children: [
      Row(children: [
        Expanded(child: _searchBar(hint: "Search compliance...", onChanged: (v) => setSt(() => localSearch = v.toLowerCase()))),
        Padding(padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () async {
              var response = await http.get(Uri.parse('http://10.0.2.2:5000/api/admin/compliance-scorecard'));
              _generateComplianceReport(jsonDecode(response.body));
            },
            child: Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFCDD2))),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 22)))),
      ]),
      Expanded(child: FutureBuilder(
        future: http.get(Uri.parse('http://10.0.2.2:5000/api/admin/compliance-scorecard')),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kIndigo));
          var data = jsonDecode((snapshot.data as http.Response).body) as List;
          var filtered = data.where((i) => i['target_user_name'].toString().toLowerCase().contains(localSearch)).toList();
          if (filtered.isEmpty) return _emptyState(Icons.shield_outlined, "No compliance data");
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              double score = double.tryParse(item['compliance_score'].toString()) ?? 0.0;
              bool isHighRisk = score <= 60;
              final Color scoreColor = score >= 80 ? const Color(0xFF2E7D32) : (score >= 60 ? const Color(0xFFE65100) : Colors.redAccent);
              final Color scoreBg = score >= 80 ? const Color(0xFFE8F5E9) : (score >= 60 ? const Color(0xFFFFF3E0) : const Color(0xFFFFEBEE));
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: isHighRisk ? const Color(0xFFFFCDD2) : const Color(0xFFEEF0F8)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 7, offset: const Offset(0, 2))]),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(radius: 20, backgroundColor: scoreBg,
                    child: Icon(isHighRisk ? Icons.warning_rounded : Icons.verified_rounded, color: scoreColor, size: 20)),
                  title: Text(item['target_user_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1A1A2E))),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 3),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(6)),
                        child: Text(item['target_role'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kIndigo))),
                      const SizedBox(width: 6),
                      Text("${item['total_audits']} audits", style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
                    ])),
                  trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: scoreBg, borderRadius: BorderRadius.circular(8)),
                    child: Text("$score%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: scoreColor))),
                  onTap: isHighRisk ? () => showDialog(context: context, builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFB71C1C), Color(0xFFE53935)]),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
                          child: Row(children: [
                            const Icon(Icons.warning_rounded, color: Colors.white, size: 22), const SizedBox(width: 10),
                            const Text("Urgent Action Required", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ])),
                        Padding(padding: const EdgeInsets.all(18),
                          child: Text("${item['target_user_name']} has only $score% compliance score.\nImmediate action recommended.",
                            style: const TextStyle(fontSize: 13.5, color: Color(0xFF1A1A2E)), textAlign: TextAlign.center)),
                        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(children: [
                            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: kIndigo), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              child: const Text("Later", style: TextStyle(color: kIndigo, fontWeight: FontWeight.bold)))),
                            const SizedBox(width: 10),
                            Expanded(child: ElevatedButton(
                              onPressed: () { toggleUserStatus(item['target_user_id'], 'Blocked', item['target_user_name']); Navigator.pop(context); },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                              child: const Text("Block User", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                          ])),
                      ])),
                  )) : null,
                ),
              );
            },
          );
        },
      )),
    ]));
  }

  // ── LOGS ──────────────────────────────────────────────────────────────────

  Widget _buildLogsView() {
    String localSearch = "";
    return StatefulBuilder(builder: (context, setSt) => Column(children: [
      _searchBar(hint: "Search logs by user...", onChanged: (v) => setSt(() => localSearch = v.toLowerCase())),
      Expanded(child: FutureBuilder(
        future: http.get(Uri.parse('http://10.0.2.2:5000/api/admin/get-logs')),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kIndigo));
          var data = jsonDecode((snapshot.data as http.Response).body) as List;
          var filtered = data.where((i) => i['target_user'].toString().toLowerCase().contains(localSearch)).toList();
          if (filtered.isEmpty) return _emptyState(Icons.history_toggle_off_rounded, "No logs found");
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final log = filtered[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFEEF0F8)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 7, offset: const Offset(0, 2))]),
                child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.history_rounded, color: kIndigo, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("${log['action']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1A1A2E)), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text("User: ${log['target_user']}", style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    Text("Time: ${log['timestamp']}", style: const TextStyle(fontSize: 11.5, color: Color(0xFF9E9E9E))),
                  ])),
                ]),
              );
            },
          );
        },
      )),
    ]));
  }

  // ── GLOBAL INVENTORY ──────────────────────────────────────────────────────

  Widget _buildGlobalInventory() {
    String localSearch = "";
    return StatefulBuilder(builder: (context, setSt) => Column(children: [
      _searchBar(hint: "Search drug name...", onChanged: (v) => setSt(() => localSearch = v.toLowerCase())),
      Expanded(child: FutureBuilder(
        future: http.get(Uri.parse('http://10.0.2.2:5000/api/admin/global-inventory')),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kIndigo));
          var data = (jsonDecode((snapshot.data as http.Response).body) as List)
              .where((d) => d['drug_name'].toString().toLowerCase().contains(localSearch)).toList();
          if (data.isEmpty) return _emptyState(Icons.medication_outlined, "No drugs found");
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final drug = data[index];
              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BatchListScreen(drugName: drug['drug_name']))),
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFEEF0F8)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 7, offset: const Offset(0, 2))]),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.medication_rounded, color: kIndigo, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(drug['drug_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1A1A2E)), overflow: TextOverflow.ellipsis)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(8)),
                      child: Text("${drug['total_quantity']} units", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: kIndigo))),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9E9E9E), size: 14),
                  ]),
                ),
              );
            },
          );
        },
      )),
    ]));
  }

  // ── USER STOCK (TABS) ─────────────────────────────────────────────────────

  Widget _buildUserStockView() {
    return DefaultTabController(length: 2, child: Column(children: [
      Container(color: kIndigo, child: const TabBar(indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
        labelStyle: TextStyle(fontWeight: FontWeight.bold),
        tabs: [Tab(icon: Icon(Icons.business_rounded, size: 16), text: "Wholesalers"), Tab(icon: Icon(Icons.storefront_rounded, size: 16), text: "Retailers")])),
      Expanded(child: TabBarView(children: [_buildUserListForStock('Wholesaler'), _buildUserListForStock('Retailer')])),
    ]));
  }

  Widget _buildUserListForStock(String role) {
    String localSearch = "";
    return StatefulBuilder(builder: (context, setSt) => Column(children: [
      _searchBar(hint: "Search ${role.toLowerCase()}s...", onChanged: (v) => setSt(() => localSearch = v.toLowerCase())),
      Expanded(child: FutureBuilder(
        future: http.get(Uri.parse('http://10.0.2.2:5000/api/admin/users-list')),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kIndigo));
          var users = (jsonDecode((snapshot.data as http.Response).body) as List)
              .where((u) => u['role'] == role && (u['full_name'] ?? '').toString().toLowerCase().contains(localSearch)).toList();
          if (users.isEmpty) return _emptyState(Icons.person_search_rounded, "No ${role.toLowerCase()}s found");
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];
              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserStockScreen(userId: u['id'], userName: u['full_name']))),
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFEEF0F8)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 7, offset: const Offset(0, 2))]),
                  child: Row(children: [
                    CircleAvatar(radius: 20, backgroundColor: const Color(0xFFF0F2FF),
                      child: Text((u['full_name'] ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: kIndigo))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u['full_name'] ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1A1A2E))),
                      Text(u['role'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ])),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF9E9E9E), size: 14),
                  ]),
                ),
              );
            },
          );
        },
      )),
    ]));
  }

  // ── DRAWER ────────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    final List<_DrawerEntry> entries = [
      _DrawerEntry(Icons.dashboard_rounded,    "Stats & Overview",   0),
      _DrawerEntry(Icons.people_rounded,       "User Management",    1),
      _DrawerEntry(Icons.assignment_rounded,   "Audit Records",      2),
      _DrawerEntry(Icons.badge_rounded,        "Inspector Reports",  3),
      _DrawerEntry(Icons.shield_rounded,       "Compliance",         4),
      _DrawerEntry(Icons.history_rounded,      "Activity Logs",      5),
      _DrawerEntry(Icons.medication_rounded,   "Stock Master",       6),
      _DrawerEntry(Icons.inventory_2_rounded,  "User Stock",         7),
    ];
    return Drawer(backgroundColor: Colors.white,
      child: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A237E), kIndigo, kIndigoLight])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28))),
            const SizedBox(height: 14),
            Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.adminName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            widget.adminEmail,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),

    IconButton(
      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
      onPressed: () async {
        final prefs = await SharedPreferences.getInstance();

        final userId = prefs.getInt('userId') ?? 0;
        final phone = prefs.getString('phone_no') ?? '';

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditProfilePage(
              userId: userId,
              name: widget.adminName,
              email: widget.adminEmail,
              phone: phone,
              license: "",
              showLicense: false,
            ),
          ),
        );

        if (result == true) {
          setState(() {});
        }
      },
    ),
  ],
),
            
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white30)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 13),
                SizedBox(width: 5),
                Text("Super Admin", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ])),
          ])),
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(left: 8, bottom: 6, top: 4),
              child: Text("NAVIGATION", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF9E9E9E), letterSpacing: 1.2))),
            ...entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 2),
              child: Material(color: _currentTab == e.tab ? kIndigo.withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(12),
                child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () { setState(() => _currentTab = e.tab); Navigator.pop(context); },
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(color: _currentTab == e.tab ? kIndigo.withOpacity(0.12) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(9)),
                        child: Icon(e.icon, size: 17, color: _currentTab == e.tab ? kIndigo : const Color(0xFF4A4A6A))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.label, style: TextStyle(fontSize: 13.5, fontWeight: _currentTab == e.tab ? FontWeight.w700 : FontWeight.w500, color: _currentTab == e.tab ? kIndigo : const Color(0xFF4A4A6A)))),
                      if (_currentTab == e.tab) Container(width: 6, height: 6, decoration: const BoxDecoration(color: kIndigo, shape: BoxShape.circle)),
                    ]))))),
            ),
          ]))),
        Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: Column(children: [
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
              child: InkWell(borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.logout_rounded, size: 17, color: Color(0xFFE53935))),
                    const SizedBox(width: 12),
                    const Text("Logout", style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: Color(0xFFE53935))),
                  ])))),
          ])),
      ]));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  // Map drawer tab to body widget
  Widget _bodyForTab(int tab) {
    switch (tab) {
      case 0: return _buildStatsView();
      case 1: return _buildUserView();
      case 2: return _buildAuditView();
      case 3: return _buildInspectorView();
      case 4: return _buildComplianceView();
      case 5: return _buildLogsView();
      case 6: return _buildGlobalInventory();
      case 7: return _buildUserStockView();
      default: return _buildStatsView();
    }
  }

  final List<String> _tabTitles = ["Stats & Overview","User Management","Audit Records","Inspector Reports","Compliance","Activity Logs","Stock Master","User Stock"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text(_tabTitles[_currentTab], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
        backgroundColor: kIndigo, foregroundColor: Colors.white, elevation: 0,
        actions: [
          Stack(children: [
            IconButton(icon: const Icon(Icons.notifications_rounded), onPressed: _showRiskListDialog),
            if (riskCount > 0) Positioned(right: 8, top: 8,
              child: Container(padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text('$riskCount', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center))),
          ]),
          IconButton(icon: const Icon(Icons.logout_rounded),
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false)),
        ],
      ),
      body: _bodyForTab(_currentTab),
    );
  }
}

class _DrawerEntry {
  final IconData icon; final String label; final int tab;
  const _DrawerEntry(this.icon, this.label, this.tab);
}

// ─────────────────────────────────────────────────────────────────────────────
// BATCH LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class BatchListScreen extends StatelessWidget {
  final String drugName;
  const BatchListScreen({super.key, required this.drugName});

  @override
  Widget build(BuildContext context) {
    const Color kIndigo = Color(0xFF3949AB);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: Text("Batches: $drugName", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kIndigo, foregroundColor: Colors.white, elevation: 0),
      body: FutureBuilder(
        future: http.get(Uri.parse('http://10.0.2.2:5000/api/admin/drug-batches/$drugName')),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kIndigo));
          var batches = jsonDecode((snapshot.data as http.Response).body) as List;
          if (batches.isEmpty) return const Center(child: Text("No batches found", style: TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold)));
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(14),
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final b = batches[index];
              final int qty = int.tryParse(b['total_qty'].toString()) ?? 0;
              final bool isLow = qty <= 10;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: isLow ? const Color(0xFFFFCDD2) : const Color(0xFFEEF0F8)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 7, offset: const Offset(0, 2))]),
                child: Row(children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.inventory_2_rounded, color: kIndigo, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Batch: ${b['batch_no']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 3),
                    Text("Expiry: ${b['expiry_date'] ?? 'N/A'}", style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: isLow ? const Color(0xFFFFEBEE) : const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(9)),
                    child: Column(children: [
                      Text(qty.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLow ? Colors.redAccent : kIndigo)),
                      Text("units", style: TextStyle(fontSize: 10, color: isLow ? Colors.redAccent : kIndigo, fontWeight: FontWeight.w500)),
                    ])),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER STOCK SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class UserStockScreen extends StatefulWidget {
  final int userId;
  final String userName;
  const UserStockScreen({super.key, required this.userId, required this.userName});
  @override
  State<UserStockScreen> createState() => _UserStockScreenState();
}

class _UserStockScreenState extends State<UserStockScreen> {
  static const Color kIndigo = Color(0xFF3949AB);
  static const Color kIndigoLight = Color(0xFF5C6BC0);

  String searchQuery = "";
  List fullStockList = [];

  Future<void> _generateUserStockPDF(List data) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) => pw.Column(children: [
      pw.Text("${widget.userName}'s Inventory Report", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 20),
      pw.Table.fromTextArray(headers: ['Drug Name', 'Batch', 'Qty'],
        data: data.map((i) => [i['drug_name'], i['batch_no'], i['quantity'].toString()]).toList()),
    ])));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), overflow: TextOverflow.ellipsis),
          const Text("Inventory Details", style: TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: kIndigo, foregroundColor: Colors.white, elevation: 0,
      ),
      body: Column(children: [
        // Header + search + PDF
        Container(padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [kIndigo, kIndigoLight], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Column(children: [
            Row(children: [
              Expanded(child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
                child: TextField(
                  onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                  decoration: const InputDecoration(hintText: "Search medicine...", hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: kIndigo, size: 22),
                    border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
              )),
              const SizedBox(width: 10),
              GestureDetector(onTap: () => _generateUserStockPDF(fullStockList),
                child: Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(11), border: Border.all(color: Colors.white30)),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22))),
            ]),
          ])),
        Expanded(child: FutureBuilder(
          future: http.get(Uri.parse('http://10.0.2.2:5000/api/admin/user-inventory/${widget.userId}')),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: kIndigo));
            var response = jsonDecode((snapshot.data as http.Response).body);
            fullStockList = (response is List) ? response : [];
            var filtered = fullStockList.where((i) => i['drug_name'].toString().toLowerCase().contains(searchQuery)).toList();
            if (filtered.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.inventory_2_outlined, size: 52, color: Color(0xFFBDBDBD))),
              const SizedBox(height: 16),
              const Text("No Stock Found", style: TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 15)),
            ]));
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final int qty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
                final bool isLow = qty <= 10;
                final Color qtyColor = isLow ? Colors.redAccent : kIndigo;
                final Color qtyBg = isLow ? const Color(0xFFFFEBEE) : const Color(0xFFF0F2FF);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: isLow ? const Color(0xFFFFCDD2) : const Color(0xFFEEF0F8)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 7, offset: const Offset(0, 2))]),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: isLow ? const Color(0xFFFFEBEE) : const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(11)),
                      child: Icon(Icons.medication_rounded, color: isLow ? Colors.redAccent : kIndigo, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['drug_name'] ?? 'Unknown', overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.gavel_rounded, size: 12, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(item['batch_no'] ?? 'N/A', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                      ]),
                      if (isLow) ...[const SizedBox(height: 3),
                        const Row(children: [Icon(Icons.warning_amber_rounded, size: 12, color: Colors.redAccent), SizedBox(width: 4), Text("Low Stock", style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.w600))])],
                    ])),
                    const SizedBox(width: 10),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: qtyBg, borderRadius: BorderRadius.circular(9)),
                      child: Column(children: [
                        Text(qty.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: qtyColor)),
                        Text("units", style: TextStyle(fontSize: 10, color: qtyColor, fontWeight: FontWeight.w500)),
                      ])),
                  ]),
                );
              },
            );
          },
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUDIT DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AuditDetailScreen extends StatelessWidget {
  final int visitId;
  const AuditDetailScreen({super.key, required this.visitId});
  static const Color kIndigo = Color(0xFF3949AB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text("Audit Details"), backgroundColor: kIndigo),
      body: FutureBuilder(
        // Yahan naya API endpoint use karein jo humne banaya tha
        future: http.get(Uri.parse('http://10.0.2.2:5000/api/admin/audit-full-details/$visitId')),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var fullData = jsonDecode((snapshot.data as http.Response).body);
          var header = fullData['header']; // Inspector/User details
          var drugs = fullData['drugs'] as List; // Drug list

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // --- 1. HEADER SECTION (Inspector info, Status, etc.) ---
              _buildHeaderSection(header),
              const SizedBox(height: 16),
              
              // --- 2. DRUG LIST SECTION ---
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: drugs.length,
                itemBuilder: (context, index) {
                  final drug = drugs[index];
                  // Yahan aapka purana drug card ka logic aayega
                  return _buildDrugCard(drug); 
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Header ke liye alag widget
  Widget _buildHeaderSection(Map header) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header['target_user_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text("License: ${header['target_license_no']}"),
          const SizedBox(height: 10),
          // Yahan wo "Chips" (License Verified, etc.) add karein
          Wrap(
            spacing: 8,
            children: [
               if(header['license_verified'] == 1) _buildChip("License Verified"),
               if(header['stock_verified'] == 1) _buildChip("Stock Register"),
               // ...baaki conditions
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Chip(label: Text(label, style: const TextStyle(fontSize: 11)), backgroundColor: const Color(0xFFE8F5E9));
  }
}
// AuditDetailScreen class ke andar ye method add karein
Widget _buildDrugCard(Map drug) {
  final int mismatch = int.tryParse(drug['mismatch'].toString()) ?? 0;
  final bool matched = mismatch == 0;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: matched ? const Color(0xFFBBF7D0) : const Color(0xFFFFCDD2)),
    ),
    child: Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: matched ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(11)
        ),
        child: Icon(Icons.medication_rounded, color: matched ? const Color(0xFF2E7D32) : Colors.redAccent, size: 22)
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(drug['drug_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
        Text("Batch: ${drug['batch_no']}", style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: matched ? const Color(0xFFDCFCE7) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
        child: Text(matched ? "Matched" : "Mismatch: $mismatch", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: matched ? const Color(0xFF2E7D32) : Colors.redAccent)),
      ),
    ]),
  );
}