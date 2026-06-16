import 'package:flutter/material.dart';
import 'login_screen.dart'; 
import 'retailer_inward.dart';
import 'retailer_outward.dart'; 
import 'view_drugs.dart';
import 'registered_patients.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_page.dart';

class RetailerDashboard extends StatefulWidget {
  final String retailerName;
  final String retailerEmail;
  final String retailerGstin;
  final String retailerLicense;

  const RetailerDashboard({
    super.key,
    required this.retailerName,
    required this.retailerEmail,
    required this.retailerGstin,
    required this.retailerLicense,
  });

  @override
  State<RetailerDashboard> createState() =>
      _RetailerDashboardState();
}

class _RetailerDashboardState
    extends State<RetailerDashboard> {
 late String retailerName;
  late String retailerEmail;
  late String retailerLicense;
  late String retailerGstin;
  late String retailerPhone;
  
  // ─── COLORS ──────────────────────────────────────────────────────────────────
  static const Color kTeal = Color(0xFF00695C);
  static const Color kTealLight = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text("Retailer Portal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
  IconButton(
    icon: const Icon(Icons.logout),
    onPressed: () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (route) => false,
      );
    },
  ),
],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF004D40), kTeal, kTealLight],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      "Hello, ${widget.retailerName.split(' ').first} 👋",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text("Retailer Management Portal", style: TextStyle(color: Colors.white60, fontSize: 13)),
                  ])),
                ]),
                const SizedBox(height: 16),
                Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_outlined,
            color: Colors.white70,
            size: 13,
          ),
          const SizedBox(width: 6),
          Text(
            widget.retailerLicense,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),

    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: Colors.white70,
            size: 13,
          ),
          const SizedBox(width: 6),
          Text(
            widget.retailerGstin,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  ],
),
              ]),
            ),

            // ── Operations Section ──
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 22, 18, 12),
              child: Text("Store Operations", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                _buildLargeNavButton(
                  context,
                  title: "INWARD",
                  subtitle: "Stock-In",
                  description: "Receive and record incoming drug stock from wholesaler",
                  icon: Icons.downloading_rounded,
                  gradientColors: [kTeal, kTealLight],
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => RetailerInwardPage(retailerName: widget.retailerName)));
                  },
                ),
                const SizedBox(height: 12),
                _buildLargeNavButton(
                  context,
                  title: "OUTWARD",
                  subtitle: "Sales Dispatch",
                  description: "Record drug sales and dispatch to patients",
                  icon: Icons.upload_file_rounded,
                  gradientColors: [const Color(0xFFE65100), const Color(0xFFFF6D00)],
                  onTap: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    await Future.delayed(const Duration(milliseconds: 200));
                    if (!context.mounted) return;
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => RetailerOutwardPage(retailerName: widget.retailerName)));
                  },
                ),
              ]),
            ),

            // ── Quick Access Section ──
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 24, 18, 12),
              child: Text("Quick Access", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
              child: Row(children: [
                Expanded(child: _quickCard(
                  context, Icons.medication_rounded, "View\nDrugs", kTeal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ViewDrugsPage(retailerName: widget.retailerName))),
                )),
                const SizedBox(width: 10),
                Expanded(child: _quickCard(
                  context, Icons.people_rounded, "Registered\nPatients", const Color(0xFF6A1B9A),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => RegisteredPatientsPage(retailerName: widget.retailerName))),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DRAWER ───────────────────────────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF004D40), kTeal, kTealLight],
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.storefront_rounded, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 14),
            
            const SizedBox(height: 12),
            Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.retailerName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.white,
              )),
          const SizedBox(height: 6),
          Text(widget.retailerEmail,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              )),
              const SizedBox(height: 8),
        ],
      ),
    ),

    // 👇 ONLY THIS IS NEW (ADD)
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
              name: widget.retailerName,
              email: widget.retailerEmail,
              phone: phone,
              license: widget.retailerLicense,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 13),
                SizedBox(width: 6),
                Text("Verified Retailer", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),

        // Nav items
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 6, top: 4),
                child: Text("NAVIGATION", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF9E9E9E), letterSpacing: 1.2)),
              ),
              _drawerItem(context,
                icon: Icons.medication_rounded, label: "View Drugs",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ViewDrugsPage(retailerName: widget.retailerName)));
                },
              ),
              _drawerItem(context,
                icon: Icons.people_rounded, label: "Registered Patients",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => RegisteredPatientsPage(retailerName: widget.retailerName)));
                },
              ),
             
            ]),
          ),
        ),

        // Footer logout
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: Column(children: [
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            _drawerItem(context,
              icon: Icons.logout_rounded, label: "Logout", isDestructive: true,
              onTap: () {
                Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
              },
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _drawerItem(BuildContext context, {
    required IconData icon, required String label, required VoidCallback onTap, bool isDestructive = false,
  }) {
    final Color activeColor = kTeal;
    final Color destructiveColor = const Color(0xFFE53935);
    final Color itemColor = isDestructive ? destructiveColor : activeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDestructive ? destructiveColor.withOpacity(0.08) : activeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: itemColor),
              ),
              const SizedBox(width: 14),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: itemColor)),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── LARGE NAV BUTTON ─────────────────────────────────────────────────────────

  Widget _buildLargeNavButton(BuildContext context, {
    required String title, required String subtitle, required String description,
    required IconData icon, required List<Color> gradientColors, required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
            Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text(description, style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 15),
          ),
        ]),
      ),
    );
  }

  // ─── QUICK ACCESS CARD ────────────────────────────────────────────────────────

  Widget _quickCard(BuildContext context, IconData icon, String label, Color color, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 9),
          Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color, height: 1.3),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}