import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  final int userId;
  final String name;
  final String email;
  final String phone;
  final String license;
  final bool showLicense;

  const EditProfilePage({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.license,
     this.showLicense = true, 
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController licenseCtrl;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.name);
    emailCtrl = TextEditingController(text: widget.email);
    phoneCtrl = TextEditingController(text: widget.phone);
    licenseCtrl = TextEditingController(text: widget.license);
  }

  Future<void> updateProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:5000/update-user-profile"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": widget.userId,
          "full_name": nameCtrl.text.trim(),
          "email": emailCtrl.text.trim(),
          "phone_no": phoneCtrl.text.trim(),
          "drug_license_no": licenseCtrl.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', nameCtrl.text.trim());
        await prefs.setString('email', emailCtrl.text.trim());
        await prefs.setString('phone_no', phoneCtrl.text.trim());
        await prefs.setString('drug_license_no', licenseCtrl.text.trim());

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]),
            backgroundColor: const Color(0xFF3949AB),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Server Connection Error"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF7986CB)),
      prefixIcon: Icon(icon, color: const Color(0xFF3949AB), size: 20),
      filled: true,
      fillColor: const Color(0xFFF5F6FF),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D5F0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3949AB), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header banner with avatar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30, top: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF3949AB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person, size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Update your details",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

            // Form card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3949AB).withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3949AB),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameCtrl,
                      decoration: _inputDecoration("Full Name", Icons.person_outline),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration("Email", Icons.email_outlined),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration("Mobile Number", Icons.phone_outlined),
                    ),
                    const SizedBox(height: 14),

                    if (widget.showLicense) ...[
  TextField(
    controller: licenseCtrl,
    decoration: _inputDecoration("Drug License No", Icons.badge_outlined),
  ),
],

                    const SizedBox(height: 28),
                    

                    // Update button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3949AB),
                          disabledBackgroundColor: const Color(0xFF9FA8DA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          shadowColor: const Color(0xFF3949AB).withOpacity(0.4),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Save Changes",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}