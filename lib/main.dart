import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart'; // <--- 1. Login page file ko import kiya
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_dashboard.dart';
import 'wholesaler_dashboard.dart';
import 'retailer_dashboard.dart';
import 'inspector_page.dart';
import 'splash_screen.dart';
void main() {
  runApp(const MyApp());
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  

  @override
  Widget build(BuildContext context) {

    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),

      home: const SplashScreen(),
    );
  }
}
class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final licenseCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  String selectedRole = 'Wholesaler';
  List<String> roles = ['Admin', 'Wholesaler', 'Retailer', 'Inspector'];

  Future<void> registerUser() async {
    final url = Uri.parse('http://10.0.2.2:5000/register');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameCtrl.text,
          "email": emailCtrl.text,
          "password": passCtrl.text,
          "role": selectedRole,
          "license_no": licenseCtrl.text,
          "address": addressCtrl.text,
        }),
      );

      if (response.statusCode == 200) {
        // Success message aur fir Login page par bhej dena
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: Text("Success"),
                  content: Text("User Registered Successfully!"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                      },
                      child: Text("Go to Login"),
                    )
                  ],
                ));
      } else {
        print("Error: ${response.body}");
      }
    } catch (e) {
      print("Connection Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("CG Narcotics - Register")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // [cite: 11] Manufacturer's Name / Full Name
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Full Name")),
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: "Email ID")),
            TextField(controller: passCtrl, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 10),
            DropdownButtonFormField(
              value: selectedRole,
              items: roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
              onChanged: (val) => setState(() => selectedRole = val.toString()),
              decoration: InputDecoration(labelText: "Select User Role"),
            ),
            // [cite: 14, 27, 38] Har level ke liye Drug License No zaroori hai
            TextField(controller: licenseCtrl, decoration: InputDecoration(labelText: "Drug License No. (e.g. Form 20/21)")),
            // [cite: 12, 25, 36] Address field
            TextField(controller: addressCtrl, decoration: InputDecoration(labelText: "Full Address")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: registerUser,
              child: Text("Create Account"),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
            ),
            
            // <--- 2. Login Page par jane ke liye button add kiya
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
              },
              child: Text("Already have an account? Login here"),
            )
          ],
        ),
      ),
    );
  }
}
class AutoLoginScreen extends StatefulWidget {
  const AutoLoginScreen({super.key});

  @override
  State<AutoLoginScreen> createState() =>
      _AutoLoginScreenState();
}



class _AutoLoginScreenState extends State<AutoLoginScreen> {

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {

    final prefs = await SharedPreferences.getInstance();

    String role =
        prefs.getString('role') ?? '';

    String name =
        prefs.getString('userName') ?? '';

    String email =
        prefs.getString('email') ?? '';

    String gstin =
        prefs.getString('gstin') ?? '';

    String license =
        prefs.getString('drug_license_no') ?? '';

    String phone =
    prefs.getString('phone_no') ?? '';    

    int userId =
        prefs.getInt('userId') ?? 0;

    if (!mounted) return;

    if (role == 'Admin') {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboard(
            adminName: name,
            adminEmail: email,
          ),
        ),
      );

    } else if (role == 'Wholesaler') {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WholesalerDashboard(
            userId: userId,
            wholesalerName: name,
            wholesalerEmail: email,
            wholesalerGstin: gstin,
            wholesalerLicense: license,
            wholesalerPhone: phone,
          ),
        ),
      );

    } else if (role == 'Retailer') {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RetailerDashboard(
            retailerName: name,
            retailerEmail: email,
            retailerGstin: gstin,
            retailerLicense: license,
          ),
        ),
      );

    } else if (role == 'Inspector') {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InspectorPage(
            inspectorName: name,
            inspectorEmail: email,
            inspectorRole: role,
          ),
        ),
      );

    } else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}