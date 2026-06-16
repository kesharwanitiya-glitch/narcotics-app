import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user_drugs_page.dart';

class UserStockPage extends StatefulWidget {
  const UserStockPage({super.key});
  @override
  State<UserStockPage> createState() => _UserStockPageState();
}

class _UserStockPageState extends State<UserStockPage> {
  static const Color kIndigo = Color(0xFF3949AB);
  static const Color kIndigoLight = Color(0xFF5C6BC0);

  List wholesalers = [];
  List retailers   = [];
  List filteredWholesalers = [];
  List filteredRetailers   = [];

  final wholesalerSearchCtrl = TextEditingController();
  final retailerSearchCtrl   = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers("Wholesaler");
    fetchUsers("Retailer");
    wholesalerSearchCtrl.addListener(() => _onSearch("Wholesaler"));
    retailerSearchCtrl.addListener(()   => _onSearch("Retailer"));
  }

  @override
  void dispose() {
    wholesalerSearchCtrl.dispose();
    retailerSearchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String role) {
    final q   = role == "Wholesaler" ? wholesalerSearchCtrl.text.trim().toLowerCase() : retailerSearchCtrl.text.trim().toLowerCase();
    final src = role == "Wholesaler" ? wholesalers : retailers;
    final res = q.isEmpty ? List.from(src) : src.where((u) {
      final name  = (u['full_name']       ?? '').toString().toLowerCase();
      final lic   = (u['drug_license_no'] ?? '').toString().toLowerCase();
      final shop  = (u['shop_name']       ?? '').toString().toLowerCase();
      return name.contains(q) || lic.contains(q) || shop.contains(q);
    }).toList();
    setState(() { if (role == "Wholesaler") filteredWholesalers = res; else filteredRetailers = res; });
  }

  Future fetchUsers(String role) async {
    final res = await http.get(Uri.parse('http://10.0.2.2:5000/inspector/user-stock/$role'));
    print("ROLE = $role"); print(res.body);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        if (role == "Wholesaler") { wholesalers = data; filteredWholesalers = List.from(data); }
        else                      { retailers   = data; filteredRetailers   = List.from(data); }
      });
    }
  }

  Widget buildUserList(List users, List filtered, TextEditingController ctrl, String role) {
    return Column(children: [
      // ── Header + search ──
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [kIndigo, kIndigoLight], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(role == "Wholesaler" ? Icons.business_rounded : Icons.storefront_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${role}s", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text("${users.length} registered ${role.toLowerCase()}(s)", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
            child: TextField(
              controller: ctrl,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: "Search by name, license or shop...",
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: kIndigo, size: 22),
                suffixIcon: ctrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E), size: 20), onPressed: () => ctrl.clear())
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
            ),
          ),
        ]),
      ),

      if (ctrl.text.isNotEmpty)
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF9E9E9E)),
            const SizedBox(width: 6),
            Text("${filtered.length} result(s)", style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
          ])),

      Expanded(
        child: filtered.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.person_search_rounded, size: 52, color: Color(0xFFBDBDBD))),
                const SizedBox(height: 16),
                Text(ctrl.text.isNotEmpty ? "No matching ${role.toLowerCase()}s" : "No ${role}s Found",
                  style: const TextStyle(color: Color(0xFF4A4A6A), fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text(ctrl.text.isNotEmpty ? "Try a different search term" : "No records available.",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ]))
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final user = filtered[index];
                  return InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => UserDrugsPage(userName: user['full_name'], userEmail: user['email'], role: user['role'] ?? ''))),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEEF0F8), width: 1),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Row(children: [
                        CircleAvatar(radius: 22, backgroundColor: const Color(0xFFF0F2FF),
                          child: Text(
                            (user['full_name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kIndigo))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(user['full_name'] ?? '', overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E))),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.card_membership_outlined, size: 13, color: Color(0xFF9E9E9E)),
                            const SizedBox(width: 4),
                            Expanded(child: Text(user['drug_license_no'] ?? '',
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis)),
                          ]),
                          if ((user['shop_name'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.storefront_outlined, size: 13, color: Color(0xFF9E9E9E)),
                              const SizedBox(width: 4),
                              Expanded(child: Text(user['shop_name'] ?? '',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis)),
                            ]),
                          ],
                        ])),
                        Container(padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.arrow_forward_ios_rounded, color: kIndigo, size: 14)),
                      ]),
                    ),
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
          title: const Text("User Stock", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
          backgroundColor: kIndigo, foregroundColor: Colors.white, elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Container(color: kIndigo,
              child: const TabBar(
                indicatorColor: Colors.white, indicatorWeight: 3, indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white, unselectedLabelColor: Colors.white60,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
                tabs: [
                  Tab(icon: Icon(Icons.business_rounded, size: 17), text: "Wholesaler"),
                  Tab(icon: Icon(Icons.storefront_rounded, size: 17), text: "Retailer"),
                ]))),
        ),
        body: TabBarView(children: [
          buildUserList(wholesalers, filteredWholesalers, wholesalerSearchCtrl, "Wholesaler"),
          buildUserList(retailers,   filteredRetailers,   retailerSearchCtrl,   "Retailer"),
        ]),
      ),
    );
  }
}