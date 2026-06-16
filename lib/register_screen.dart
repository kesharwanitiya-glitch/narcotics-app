import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color kIndigo = Color(0xFF3949AB);
  static const Color kIndigoLight = Color(0xFF5C6BC0);

  final nameCtrl        = TextEditingController();
  final emailCtrl       = TextEditingController();
  final passCtrl        = TextEditingController();
  final licenseCtrl     = TextEditingController();
  final gtinCtrl        = TextEditingController();
  final shopNameCtrl    = TextEditingController();
  final addressCtrl     = TextEditingController();
  final phoneCtrl       = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  String selectedRole  = 'Retailer';
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;

  Future<void> registerUser() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('http://10.0.2.2:5000/register');

    final String cleanName      = nameCtrl.text.trim();
    final String cleanEmail     = emailCtrl.text.trim();
    final String cleanPhone     = phoneCtrl.text.trim();
    final String cleanPass      = passCtrl.text;
    final String cleanConfirmPass = confirmPassCtrl.text;
    final String cleanAddress   = addressCtrl.text.trim();
    final String cleanLicense   = licenseCtrl.text.trim().toUpperCase();
    final String cleanGtin      = gtinCtrl.text.trim().toUpperCase();
    final String cleanShopName  = shopNameCtrl.text.trim();

    if (cleanName.isEmpty || cleanEmail.isEmpty || cleanPhone.isEmpty || cleanAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ All standard fields are required!"), behavior: SnackBarBehavior.floating));
      setState(() => _isLoading = false); return;
    }
    if ((selectedRole == 'Wholesaler' || selectedRole == 'Retailer') && cleanShopName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Shop Name is required!"), behavior: SnackBarBehavior.floating));
      setState(() => _isLoading = false); return;
    }
    final RegExp gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    if (!gmailRegex.hasMatch(cleanEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Only '@gmail.com' accounts are allowed."), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      setState(() => _isLoading = false); return;
    }
    if (cleanPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Mobile number must be exactly 10 digits!"), behavior: SnackBarBehavior.floating));
      setState(() => _isLoading = false); return;
    }
    if (cleanPass.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Password must be exactly 8 characters!"), behavior: SnackBarBehavior.floating));
      setState(() => _isLoading = false); return;
    }
    if (cleanPass != cleanConfirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Passwords do not match!"), behavior: SnackBarBehavior.floating));
      setState(() => _isLoading = false); return;
    }
    if (selectedRole == 'Wholesaler' || selectedRole == 'Retailer') {
      if (cleanLicense.isEmpty || cleanGtin.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ License and GSTIN cannot be empty!"), behavior: SnackBarBehavior.floating));
        setState(() => _isLoading = false); return;
      }
      final RegExp licenseRegex = RegExp(r'^[A-Z]{2}-\d{4,6}[-/]\d{2,4}$');
      if (!licenseRegex.hasMatch(cleanLicense)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Invalid License Format! (e.g., CG-12345-26)"), behavior: SnackBarBehavior.floating));
        setState(() => _isLoading = false); return;
      }
      final RegExp gtinRegex = RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$');
      if (!gtinRegex.hasMatch(cleanGtin)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Invalid GSTIN Format!"), behavior: SnackBarBehavior.floating));
        setState(() => _isLoading = false); return;
      }
    }

    try {
      final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": cleanName, "email": cleanEmail, "phone": cleanPhone,
          "password": cleanPass, "role": selectedRole,
          "license_no": (selectedRole == 'Wholesaler' || selectedRole == 'Retailer') ? cleanLicense : null,
          "gtin": (selectedRole == 'Wholesaler' || selectedRole == 'Retailer') ? cleanGtin : null,
          "shop_name": (selectedRole == 'Wholesaler' || selectedRole == 'Retailer') ? cleanShopName : null,
          "address": cleanAddress,
        }));
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("🎉 Registered Successfully!"), backgroundColor: Color(0xFF2E7D32), behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      } else {
        print("Server Error: ${response.body}");
      }
    } catch (e) {
      print("Network Error: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    nameCtrl.dispose(); emailCtrl.dispose(); phoneCtrl.dispose(); passCtrl.dispose();
    confirmPassCtrl.dispose(); licenseCtrl.dispose(); gtinCtrl.dispose();
    shopNameCtrl.dispose(); addressCtrl.dispose(); super.dispose();
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────

  Widget _field({required TextEditingController ctrl, required String label, required IconData icon,
    String? hint, String? helper, TextInputType? keyboardType, bool obscure = false,
    VoidCallback? onToggleObscure, bool isObscured = false, int maxLines = 1,
    List<TextInputFormatter>? formatters, String? prefixText}) {
    return TextField(
      controller: ctrl, keyboardType: keyboardType, obscureText: obscure,
      maxLines: maxLines, inputFormatters: formatters,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label, hintText: hint, helperText: helper, prefixText: prefixText,
        prefixIcon: Icon(icon, color: kIndigo, size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF9E9E9E), size: 20), onPressed: onToggleObscure)
            : null,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        helperStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF9E9E9E)),
        filled: true, fillColor: const Color(0xFFF8F9FF),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E4F0), width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kIndigo, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
  }

  Widget _sectionLabel(String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 14),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: kIndigo.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: kIndigo)),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: kIndigo, letterSpacing: 0.3)),
    ]));

  Widget _sectionCard({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
        backgroundColor: kIndigo, foregroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // ── Branding header ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kIndigo, kIndigoLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: kIndigo.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 26)),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Join Portal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 3),
                Text("Enter valid details to register securely", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ])),
          const SizedBox(height: 20),

          // ── Section 1: Personal Info ──
          _sectionLabel("Personal Information", Icons.person_outline_rounded),
          _sectionCard(children: [
            _field(ctrl: nameCtrl, label: "Full Name", icon: Icons.person_outline_rounded, hint: "Enter your full name"),
            const SizedBox(height: 14),
            _field(ctrl: emailCtrl, label: "Email Address", icon: Icons.email_outlined, hint: "example@gmail.com", keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _field(ctrl: phoneCtrl, label: "Mobile Number", icon: Icons.phone_outlined, prefixText: "+91 ",
              keyboardType: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
            const SizedBox(height: 14),
            _field(ctrl: addressCtrl, label: "Full Address", icon: Icons.location_on_outlined, maxLines: 2),
          ]),
          const SizedBox(height: 16),

          // ── Section 2: Security ──
          _sectionLabel("Security", Icons.lock_outline_rounded),
          _sectionCard(children: [
            _field(ctrl: passCtrl, label: "Password (Exact 8 characters)", icon: Icons.lock_outline_rounded,
              obscure: _obscurePass, isObscured: _obscurePass, onToggleObscure: () => setState(() => _obscurePass = !_obscurePass)),
            const SizedBox(height: 14),
            _field(ctrl: confirmPassCtrl, label: "Confirm Password", icon: Icons.lock_reset_rounded,
              obscure: _obscureConfirm, isObscured: _obscureConfirm, onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm)),
          ]),
          const SizedBox(height: 16),

          // ── Section 3: Role ──
          _sectionLabel("User Role", Icons.assignment_ind_outlined),
          _sectionCard(children: [
            DropdownButtonFormField<String>(
              value: selectedRole,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                labelText: "Select User Role", prefixIcon: const Icon(Icons.assignment_ind_outlined, color: kIndigo, size: 20),
                labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                filled: true, fillColor: const Color(0xFFF8F9FF),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E4F0), width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kIndigo, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              items: ['Admin', 'Inspector', 'Wholesaler', 'Retailer']
                  .map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
              onChanged: (val) => setState(() => selectedRole = val!)),
          ]),
          const SizedBox(height: 16),

          // ── Section 4: Business (conditional) ──
          if (selectedRole == 'Wholesaler' || selectedRole == 'Retailer') ...[
            _sectionLabel("Business Details", Icons.storefront_outlined),
            _sectionCard(children: [
              _field(ctrl: shopNameCtrl, label: "Shop Name", icon: Icons.store_outlined, hint: "Enter Medical Store Name"),
              const SizedBox(height: 14),
              _field(ctrl: licenseCtrl, label: "Drug License No.", icon: Icons.verified_outlined,
                hint: "e.g., CG-12345-26", helper: "Format Required: State-Number-Year"),
              const SizedBox(height: 14),
              _field(ctrl: gtinCtrl, label: "GSTIN Number", icon: Icons.receipt_long_outlined,
                hint: "e.g., 22AAAAA0000A1Z5", helper: "Format: 15 Alphanumeric Characters",
                formatters: [LengthLimitingTextInputFormatter(15)]),
            ]),
            const SizedBox(height: 16),
          ],

          // ── Register button ──
          ElevatedButton(
            onPressed: _isLoading ? null : registerUser,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: kIndigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0),
            child: _isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text("REGISTER NOW", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}