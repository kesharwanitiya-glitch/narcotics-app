import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'wholesaler_dashboard.dart'; 
import 'register_screen.dart'; 
import 'retailer_dashboard.dart'; 
import 'inspector_page.dart';
import 'admin_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl  = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading   = false;

  Future<void> loginUser() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('http://10.0.2.2:5000/login');
    try {
      final response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailCtrl.text.trim(), "password": passCtrl.text}));
      final data = jsonDecode(response.body);
      
      print(data);
      print("LICENSE = ${data['user']['drug_license_no']}");

      if (response.statusCode == 200) {
        String role    = data['user']['role'];
        String name    = data['user']['name'];
        String gstin   = data['user']['gstin'];
        String license = data['user']['drug_license_no'];
                 final prefs = await SharedPreferences.getInstance();

  await prefs.setBool('isLoggedIn', true);
  await prefs.setInt('userId', data['user']['id']);
  await prefs.setString('userName', name);
  await prefs.setString('role', role);
  await prefs.setString('email', data['user']['email']);
  await prefs.setString('gstin', gstin);
  await prefs.setString('drug_license_no', license);
  await prefs.setString(
  'phone_no',
  data['user']['phone_no'] ?? '',
);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Welcome back, $name! ($role)"),
          backgroundColor: const Color(0xFF3949AB), behavior: SnackBarBehavior.floating));

        if (role == 'Wholesaler') {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => WholesalerDashboard(
        userId: data['user']['id'],
        wholesalerName: name,
        wholesalerEmail: emailCtrl.text.trim(),
        wholesalerGstin: gstin,
        wholesalerLicense: license,
        wholesalerPhone: data['user']['phone_no'], // NEW
      ),
    ),
    (route) => false,
  );
} else if (role == 'Retailer') {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => RetailerDashboard(
        retailerName: name,
        retailerEmail: emailCtrl.text.trim(),
        retailerGstin: gstin,
        retailerLicense: license,
      ),
    ),
    (route) => false,
  );

        } else if (role == 'Inspector') {
          final userData = data['user'] ?? data;
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => InspectorPage(
              inspectorName:  userData['full_name'] ?? userData['name']       ?? "Inspector",
              inspectorEmail: userData['email']     ?? userData['user_email'] ?? "",
              inspectorRole:  userData['role']      ?? "Inspector")));
        } else if (role == 'Admin') {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
            builder: (context) => AdminDashboard(adminName: data['user']['name'], adminEmail: data['user']['email'])),
            (route) => false);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? "Invalid credentials!"),
          backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Connection Error! Check if Server is running."),
        backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() { emailCtrl.dispose(); passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo ──
                Center(
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: const Color(0xFF3949AB).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                    child: const Icon(Icons.security_rounded, size: 46, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Branding ──
                const Text("CG Narcotics Portal",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF3949AB), letterSpacing: 0.5),
                  textAlign: TextAlign.center),
                const SizedBox(height: 6),
                const Text("Sign in to access your dashboard safely",
                  style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
                  textAlign: TextAlign.center),
                const SizedBox(height: 36),

                // ── Card ──
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    // Email
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        hintText: "example@gmail.com",
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF3949AB), size: 20),
                        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        filled: true, fillColor: const Color(0xFFF8F9FF),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E4F0), width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3949AB), width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: passCtrl,
                      obscureText: _obscurePass,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF3949AB), size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF9E9E9E), size: 20),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass)),
                        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        filled: true, fillColor: const Color(0xFFF8F9FF),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E4F0), width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3949AB), width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
                    const SizedBox(height: 24),
Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ForgotPasswordPage(),
        ),
      );
    },
    child: const Text(
      "Forgot Password?",
      style: TextStyle(
        color: Color(0xFF3949AB),
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
),
                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : loginUser,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: const Color(0xFF3949AB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        elevation: 0),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text("LOG IN", style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ]),
                ),
                const SizedBox(height: 22),

                // ── Divider ──
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text("OR", style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold))),
                  Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                ]),
                const SizedBox(height: 14),

                // ── Register link ──
                OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Color(0xFF3949AB), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                  child: const Text("Don't have an account? Create One",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3949AB))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}