import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'wholesaler_dashboard.dart';
import 'retailer_dashboard.dart';
import 'inspector_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();

    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(),
        ),
      );
      return;
    }

    String role = prefs.getString('role') ?? '';
    String name = prefs.getString('userName') ?? '';
    String email = prefs.getString('email') ?? '';
    String gstin = prefs.getString('gstin') ?? '';
    String license = prefs.getString('drug_license_no') ?? '';
    String phone = prefs.getString('phone_no') ?? '';
    int userId = prefs.getInt('userId') ?? 0;

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
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A237E),
              Color(0xFF3949AB),
              Color(0xFF5C6BC0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              "Narcotic Drug Tracking System",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}