import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:lottie/lottie.dart'; // 🔥 add at top अगर नहीं है
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:table_calendar/table_calendar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:convert';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

Future<void> sendEmail({
  required String toEmail,
  required String subject,
  required String body,
}) async {
  const String apiKey =
      "YOUR_BREVO_API_KEY";

  final response = await http.post(
    Uri.parse("https://api.brevo.com/v3/smtp/email"),
    headers: {
      "accept": "application/json",
      "api-key": apiKey,
      "content-type": "application/json",
    },
    body: jsonEncode({
      "sender": {"name": "BVGM School", "email": "infopushpraj343@gmail.com"},
      "to": [
        {"email": toEmail}
      ],
      "subject": subject,
      "htmlContent": """
  
        <html>
  
          <body>
  
            <h3>$subject</h3>
  
            <p>${body.replaceAll('\n', '<br>')}</p>
  
          </body>
  
        </html>
  
        """
    }),
  );

  print(response.body);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBuuDYNQY-7Qqlrp_v_VkHs4cfmPBKG5BE",
      authDomain: "chatbot-1c143.firebaseapp.com",
      databaseURL: "https://chatbot-1c143-default-rtdb.firebaseio.com",
      projectId: "chatbot-1c143",
      storageBucket: "chatbot-1c143.firebasestorage.app",
      messagingSenderId: "321361304297",
      appId: "1:321361304297:web:17719f07253c87a316ee78",
    ),
  );
  await FirebaseMessaging.instance.requestPermission();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("Notification: ${message.notification?.title}");
  });
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const MyApp());
}

enum UserRole { admin, teacher, student }

class UserSession {
  static String? currentUserId;
  static String? currentRole; // "admin", "teacher", "student"
  static String? currentEmail;
  static String? currentName;
  static String? selectedYear; // 🔥 ACADEMIC YEAR (e.g. "2026")
  static Map<String, dynamic>? userData;

  static CollectionReference<Map<String, dynamic>> yearColl(String collectionName) {
    final year = selectedYear ?? DateTime.now().year.toString();
    return FirebaseFirestore.instance
        .collection('years')
        .doc(year)
        .collection(collectionName);
  }

  static DocumentReference<Map<String, dynamic>> yearDoc(String collectionName, String docId) {
    return yearColl(collectionName).doc(docId);
  }

  static Future<void> saveSession({
    required String uid,
    required String role,
    required String email,
    required String name,
    required String year,
    Map<String, dynamic>? extraData,
  }) async {
    currentUserId = uid;
    currentRole = role;
    currentEmail = email;
    currentName = name;
    selectedYear = year;
    userData = extraData;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', uid);
    await prefs.setString('user_role', role);
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', name);
    await prefs.setString('selected_year', year);
  }

  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('user_id');
    currentRole = prefs.getString('user_role');
    currentEmail = prefs.getString('user_email');
    currentName = prefs.getString('user_name');
    selectedYear = prefs.getString('selected_year') ?? DateTime.now().year.toString();
    return currentUserId != null && currentUserId!.isNotEmpty;
  }

  static Future<void> clearSession() async {
    currentUserId = null;
    currentRole = null;
    currentEmail = null;
    currentName = null;
    selectedYear = null;
    userData = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static String get collectionName {
    if (currentRole == 'admin') return 'admins';
    if (currentRole == 'teacher') return 'teachers';
    return 'students';
  }

  static UserRole get roleEnum {
    if (currentRole == 'admin') return UserRole.admin;
    if (currentRole == 'teacher') return UserRole.teacher;
    return UserRole.student;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BVGM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff6f9ff),
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff6c8cff),
          brightness: Brightness.light,
        ),
      ),
      home: const AuthCheck(),
    );
  }
}

class AppColors {
  static const Color primary = Color(0xff6c8cff);
  static const Color secondary = Color(0xff8f9fff);
  static const Color accent = Color(0xff5dd6ff);
  static const Color dark = Color(0xff1e2a52);
  static const Color text = Color(0xff24345a);
  static const Color subText = Color(0xff6f7c9b);
  static const Color card = Colors.white;
  static const Color bg = Color(0xfff6f9ff);
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserSession.loadSession(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.data == true && UserSession.currentUserId != null) {
          return HomeShell(
            role: UserSession.roleEnum,
          );
        }

        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  String selectedYear = DateTime.now().year.toString();
  bool hidePass = true;
  bool loading = false;

  late AnimationController _entranceController;
  late AnimationController _floatController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    _entranceController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final input = userCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (input.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID/Email aur password dijiye')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      UserSession.selectedYear = selectedYear;

      // 1. Check ADMINS collection in selected year
      final adminSnap = await UserSession.yearColl('admins').get();

      for (var doc in adminSnap.docs) {
        final d = doc.data();
        final email = (d['email'] ?? "").toString().trim();
        final mobile = (d['mobile'] ?? "").toString().trim();
        final pass = (d['password'] ?? "").toString().trim();
        final name = (d['name'] ?? "Admin").toString();

        if ((email.toLowerCase() == input.toLowerCase() ||
                mobile == input ||
                input.toLowerCase() == "admin" ||
                name.toLowerCase() == input.toLowerCase()) &&
            pass == password) {
          await UserSession.saveSession(
            uid: doc.id,
            role: "admin",
            email: email.isEmpty ? "admin@school.com" : email,
            name: name,
            year: selectedYear,
            extraData: d,
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const HomeShell(role: UserRole.admin),
              ),
            );
          }
          return;
        }
      }

      // Hardcoded Admin Bootstrap if admin user inputs admin / 1234
      if ((input.toLowerCase() == "admin" || input.toLowerCase() == "admin@gmail.com") && password == "1234") {
        final newAdminDoc = UserSession.yearColl('admins').doc();
        final adminData = {
          'name': 'Admin',
          'email': 'admin@gmail.com',
          'password': '1234',
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
        };
        await newAdminDoc.set(adminData);
        await UserSession.saveSession(
          uid: newAdminDoc.id,
          role: "admin",
          email: "admin@gmail.com",
          name: "Admin",
          year: selectedYear,
          extraData: adminData,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeShell(role: UserRole.admin),
            ),
          );
        }
        return;
      }

      // 2. Check TEACHERS collection in selected year
      final teacherSnap = await UserSession.yearColl('teachers').get();

      for (var doc in teacherSnap.docs) {
        final d = doc.data();
        final email = (d['email'] ?? "").toString().trim();
        final mobile = (d['mobile'] ?? "").toString().trim();
        final pass = (d['password'] ?? "").toString().trim();
        final name = (d['name'] ?? "Teacher").toString();

        if ((email.toLowerCase() == input.toLowerCase() ||
                mobile == input ||
                name.toLowerCase() == input.toLowerCase()) &&
            pass == password) {
          await UserSession.saveSession(
            uid: doc.id,
            role: "teacher",
            email: email,
            name: name,
            year: selectedYear,
            extraData: d,
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const HomeShell(role: UserRole.teacher),
              ),
            );
          }
          return;
        }
      }

      // 3. Check STUDENTS collection in selected year
      final studentSnap = await UserSession.yearColl('students').get();

      for (var doc in studentSnap.docs) {
        final d = doc.data();
        final email = (d['email'] ?? "").toString().trim();
        final rollNo = (d['rollNo'] ?? "").toString().trim();
        final mobile = (d['mobile'] ?? "").toString().trim();
        final pass = (d['password'] ?? "").toString().trim();
        final name = (d['name'] ?? "Student").toString();

        if ((email.toLowerCase() == input.toLowerCase() ||
                rollNo == input ||
                mobile == input ||
                name.toLowerCase() == input.toLowerCase()) &&
            pass == password) {
          await UserSession.saveSession(
            uid: doc.id,
            role: "student",
            email: email,
            name: name,
            year: selectedYear,
            extraData: d,
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const HomeShell(role: UserRole.student),
              ),
            );
          }
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Galat Mobile/Email/ID ya Password ($selectedYear me account nahi mila)")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 🔷 1. ANIMATED TOP HERO GRADIENT HEADER
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Container(
                height: 280,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF2563EB),
                      Color(0xFF3B82F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Floating Glowing Circle 1
                    Positioned(
                      top: -40 + (_floatAnimation.value * 1.5),
                      right: -30,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    // Floating Glowing Circle 2
                    Positioned(
                      bottom: 20 - (_floatAnimation.value * 1.2),
                      left: -50,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    // Sparkle Icon 1
                    Positioned(
                      top: 40 + _floatAnimation.value,
                      left: 40,
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white.withOpacity(0.4),
                        size: 20,
                      ),
                    ),
                    // Sparkle Icon 2
                    Positioned(
                      top: 80 - _floatAnimation.value,
                      right: 50,
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.amberAccent.withOpacity(0.6),
                        size: 16,
                      ),
                    ),

                    // 🔷 SCHOOL BRANDING HEADER CONTENT
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          children: [
                            const SizedBox(height: 6),
                            // 1. Logo Badge (Centered)
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Image.asset(
                                    "assets/logo.png",
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.school_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 34,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 2. BVGM BOLD
                            const Text(
                              "BVGM",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // 3. PARAGRAPH WITH HIGHLIGHTED SCHOOL NAME
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.92),
                                  height: 1.3,
                                ),
                                children: const [
                                  TextSpan(text: "Welcome To "),
                                  TextSpan(
                                    text: "Bal Vikash Gyan Mandir",
                                    style: TextStyle(
                                      color: Color(0xFFFDE047), // ✨ Golden Yellow Highlight!
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  TextSpan(text: ", Raniganj"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 🔷 2. MAIN LOGIN FORM SHEET CARD WITH PEEKING STUDENT BOY
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 195, left: 12, right: 12, bottom: 20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 🔷 WHITE CARD CONTAINER
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 35),
                        padding: const EdgeInsets.only(top: 28, left: 10, right: 10, bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withOpacity(0.10),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        // Card Header
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Select Session Year & enter credentials to continue',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 🔷 ACADEMIC SESSION YEAR SELECTOR (FULL WIDTH NEAR EDGES)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF2563EB)),
                              const SizedBox(width: 10),
                              const Text(
                                "Session Year:",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const Spacer(),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedYear,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB)),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2563EB),
                                  ),
                                  items: ["2024", "2025", "2026", "2027", "2028", "2029", "2030"]
                                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => selectedYear = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 🔷 INPUT FIELDS (COMPACT HEIGHT & WIDE FIT)
                        buildField(
                          controller: userCtrl,
                          hint: 'Mobile / Email / User ID',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 10),
                        buildField(
                          controller: passCtrl,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: hidePass,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                hidePass = !hidePass;
                              });
                            },
                            icon: Icon(
                              hidePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF64748B),
                              size: 20,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 🔷 GRADIENT LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: loading ? null : _login,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withOpacity(0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Sign In',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 🔷 FORGOT PASSWORD
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const ForgotPasswordDialog(),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // 🔷 INFO ALERT BOX
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 17),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Use registered User ID, Email, or Mobile to login.',
                                  style: TextStyle(
                                    color: Color(0xFF1E40AF),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🔷 PEEKING STUDENT BOY ILLUSTRATION OVER TOP EDGE OF WHITE CARD
                  Positioned(
                    top: -38,
                    right: 28,
                    child: Container(
                      height: 76,
                      width: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          "assets/student_peeking.png",
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
  }

  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
          ),
        ),
      ),
    );
  }
}

class _AnimatedWelcomeIllustration extends StatelessWidget {
  final AnimationController floatController;
  final Animation<double> floatAnimation;
  final Animation<double> pulseAnimation;

  const _AnimatedWelcomeIllustration({
    required this.floatController,
    required this.floatAnimation,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 🔷 Floating Confetti Squares (Royal Blue & Cyan)
              Positioned(
                top: 25 + floatAnimation.value,
                left: 30,
                child: Transform.rotate(
                  angle: 0.4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 30 - floatAnimation.value,
                left: 55,
                child: Transform.rotate(
                  angle: -0.3,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 35 - floatAnimation.value,
                right: 45,
                child: Transform.rotate(
                  angle: 0.6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.75),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 35 + floatAnimation.value,
                right: 35,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // 🔷 MAIN WELCOME CARD ENVELOPE / BOARD (Center)
              Transform.translate(
                offset: Offset(0, floatAnimation.value * 0.7),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar / Logo Circle
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              "assets/logo.png",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Hello! 👋",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "BAL VIKASH GYAN MANDIR",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔷 Floating Mini Widget 1: Bar Chart Card (Left Bottom)
              Positioned(
                bottom: 15 - floatAnimation.value,
                left: 18,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB), size: 18),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 22, height: 4, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 3),
                          Container(width: 14, height: 4, decoration: BoxDecoration(color: const Color(0xFF93C5FD), borderRadius: BorderRadius.circular(2))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 🔷 Floating Mini Widget 2: Report Donut Card (Right Bottom)
              Positioned(
                bottom: 15 + floatAnimation.value,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF4F46E5), size: 18),
                  ),
                ),
              ),

              // 🔷 Floating Mini Widget 3: Verified Badge (Right Top)
              Positioned(
                top: 18 - floatAnimation.value,
                right: 22,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0284C7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF0284C7),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CurvedNotchPainter extends CustomPainter {
  final double activeX;
  final Color color;

  CurvedNotchPainter({required this.activeX, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);

    const double notchRadius = 32;
    final double left = (activeX - notchRadius - 12).clamp(0.0, size.width);
    final double right = (activeX + notchRadius + 12).clamp(0.0, size.width);

    path.lineTo(left, 0);
    path.cubicTo(
      activeX - notchRadius + 4, 0,
      activeX - notchRadius + 4, 30,
      activeX, 30,
    );
    path.cubicTo(
      activeX + notchRadius - 4, 30,
      activeX + notchRadius - 4, 0,
      right, 0,
    );
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.35), 8, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CurvedNotchPainter oldDelegate) {
    return oldDelegate.activeX != activeX || oldDelegate.color != color;
  }
}

class HomeShell extends StatefulWidget {
  final UserRole role;

  const HomeShell({super.key, required this.role});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int currentIndex = 0;

  List<String> get tabs {
    switch (widget.role) {
      case UserRole.admin:
        return ['Home', 'Students', 'Add', 'Notices', 'Profile'];
      case UserRole.teacher:
        return ['Home', 'Attendance', 'Homework', 'Notices', 'Profile'];
      case UserRole.student:
        return ['Home', 'Fees', 'Results', 'Notices', 'Profile'];
    }
  }

  IconData getNavIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return widget.role == UserRole.student
            ? Icons.account_balance_wallet_rounded
            : Icons.assignment_rounded;
      case 2:
        return Icons.add_circle_rounded;
      case 3:
        return Icons.notifications_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Future<void> _logout() async {
    await UserSession.clearSession();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final pages = [
      DashboardPage(role: widget.role, onLogout: _logout),
      widget.role == UserRole.student
          ? const StudentFeesPage()
          : SecondPage(role: widget.role, title: tabs[1]),
      ThirdPage(role: widget.role, title: tabs[2]),
      NoticesPage(role: widget.role),
      ProfilePage(role: widget.role),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        // 1. If on any other tab (not Home), switch back to Home tab (index 0) step-by-step!
        if (currentIndex != 0) {
          setState(() {
            currentIndex = 0;
          });
          return;
        }

        // 2. If already on Home tab (index 0), show Exit Confirmation Popup!
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 28),
                SizedBox(width: 10),
                Text(
                  "Exit App?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            content: const Text(
              "Kya aap Bal Vikash Gyan Mandir App se bahar nikalna chahte hain?",
              style: TextStyle(fontSize: 14, color: AppColors.text, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Yes, Exit",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      drawer: isDesktop
          ? Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text(
                "Menu",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...List.generate(
              tabs.length,
                  (index) {
                return ListTile(
                  leading: Icon(getNavIcon(index)),
                  title: Text(tabs[index]),
                  onTap: () {
                    Navigator.pop(context);

                    setState(() {
                      currentIndex = index;
                    });
                  },
                );
              },
            ),
          ],
        ),
      )
          : null,
      body: Column(
        children: [
          if (isDesktop)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    },
                  ),
                  Text(
                    tabs[currentIndex],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: pages[currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              color: Colors.transparent,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 76,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;
                      final int itemCount = widget.role == UserRole.student ? 4 : 5;
                      final double tabWidth = width / itemCount;

                      int visualActiveIndex = currentIndex;
                      if (widget.role == UserRole.student && currentIndex >= 3) {
                        visualActiveIndex = currentIndex - 1;
                      }

                      final double activeX = (visualActiveIndex + 0.5) * tabWidth;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 1. CURVED NOTCH CANVAS BACKGROUND
                          Positioned.fill(
                            top: 14,
                            child: CustomPaint(
                              painter: CurvedNotchPainter(
                                activeX: activeX,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),

                          // 2. ANIMATED FLOATING WHITE BUBBLE FOR ACTIVE TAB
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            left: activeX - 26,
                            top: -4,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  getNavIcon(currentIndex),
                                  color: const Color(0xFF0284C7),
                                  size: 26,
                                ),
                              ),
                            ),
                          ),

                          // 3. TAB ITEMS ROW (ICONS & LABELS)
                          Positioned.fill(
                            top: 14,
                            child: Row(
                              children: List.generate(itemCount, (index) {
                                int actualIndex = index;
                                if (widget.role == UserRole.student && index >= 2) {
                                  actualIndex = index + 1;
                                }

                                final bool isSelected = currentIndex == actualIndex;

                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (index == 2 && widget.role == UserRole.admin) {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AddUserDialog(),
                                        );
                                        return;
                                      }
                                      setState(() {
                                        currentIndex = actualIndex;
                                      });
                                    },
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isSelected) ...[
                                          const SizedBox(height: 24),
                                          Text(
                                            tabs[actualIndex],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ] else ...[
                                          Stack(
                                            children: [
                                              Icon(
                                                getNavIcon(actualIndex),
                                                size: 22,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                              if (actualIndex == 3)
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: StreamBuilder<QuerySnapshot>(
                                                    stream: UserSession.yearColl('notices')
                                                        .where(
                                                      Filter.or(
                                                        Filter(
                                                          'role',
                                                          isEqualTo: widget.role.name,
                                                        ),
                                                        Filter(
                                                          'studentId',
                                                          isEqualTo: UserSession.currentUserId,
                                                        ),
                                                      ),
                                                    )
                                                        .snapshots(),
                                                    builder: (context, snap) {
                                                      if (!snap.hasData) return const SizedBox();
                                                      final uid = UserSession.currentUserId;
                                                      int unread = 0;
                                                      for (var doc in snap.data!.docs) {
                                                        final data = doc.data() as Map<String, dynamic>;
                                                        List seenBy = data['seenBy'] ?? [];
                                                        if (!seenBy.contains(uid)) unread++;
                                                      }
                                                      if (unread == 0) return const SizedBox();
                                                      return Container(
                                                        padding: const EdgeInsets.all(3),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.red,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Text(
                                                          unread.toString(),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 8.5,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            tabs[actualIndex],
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
    ),
);
  }
}

class DashboardPage extends StatefulWidget {
  final UserRole role;
  final Future<void> Function() onLogout;

  const DashboardPage({
    super.key,
    required this.role,
    required this.onLogout,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  late PageController _controller;
  int _current = 0;

  List<Color> _activeHeaderGradient = const [
    Color(0xFF0F172A),
    Color(0xFF0369A1),
    Color(0xFF0284C7),
  ];
  Color _activeHeaderAccent = const Color(0xFF38BDF8);

  Color getIconBgColor(String title) {
    switch (title) {
    // 🔷 OVERVIEW
      case "Students":
        return Colors.blue.withOpacity(0.15);

      case "Teachers":
        return Colors.green.withOpacity(0.15);

      case "Admins":
        return Colors.purple.withOpacity(0.15);

      case "Fees Paid":
      case "Fees Due":
        return Colors.orange.withOpacity(0.15);

      case "Notices":
        return Colors.red.withOpacity(0.15);

    // 🔷 COMMON
      case "Attendance":
      case "My Attendance":
        return Colors.green.withOpacity(0.15);

      case "Results":
      case "Exams & Results":
        return Colors.pink.withOpacity(0.15);

      case "Homework":
        return Colors.indigo.withOpacity(0.15);

    // 🔷 MAIN FEATURES (NEW ADD)
      case "Student Management":
        return Colors.blue.withOpacity(0.15);

      case "Teacher Management":
        return Colors.green.withOpacity(0.15);

      case "Class & Section":
        return Colors.indigo.withOpacity(0.15);

      case "Timetable":
        return Colors.orange.withOpacity(0.15);

      case "Fees":
        return Colors.red.withOpacity(0.15);

      case "Transport":
        return Colors.teal.withOpacity(0.15);

      case "Library":
        return Colors.deepPurple.withOpacity(0.15);

      case "Gallery":
        return Colors.pink.withOpacity(0.15);

      default:
        return Colors.grey.withOpacity(0.15);
    }
  }

  Color getIconColor(String title) {
    switch (title) {
      case "Students":
        return Colors.blue;

      case "Teachers":
        return Colors.green;

      case "Admins":
        return Colors.purple;

      case "Fees Paid":
      case "Fees Due":
        return Colors.orange;

      case "Notices":
        return Colors.red;

      case "Attendance":
      case "My Attendance":
        return Colors.green;

      case "Results":
      case "Exams & Results":
        return Colors.pink;

      case "Homework":
        return Colors.indigo;

      case "Student Management":
        return Colors.blue;

      case "Teacher Management":
        return Colors.green;

      case "Class & Section":
        return Colors.indigo;

      case "Timetable":
        return Colors.orange;

      case "Fees":
        return Colors.red;

      case "Transport":
        return Colors.teal;

      case "Library":
        return Colors.deepPurple;

      case "Gallery":
        return Colors.pink;

      default:
        return AppColors.primary;
    }
  }

  Color getActivityBgColor(String title) {
    switch (title) {
      case "Qualified Teachers":
        return Colors.blue.withOpacity(0.15);

      case "Strong Education":
        return Colors.green.withOpacity(0.15);

      case "Good Discipline":
        return Colors.purple.withOpacity(0.15);

      case "Sports Activities":
        return Colors.orange.withOpacity(0.15);

      case "Parent Connect App":
        return Colors.pink.withOpacity(0.15);

      default:
        return Colors.grey.withOpacity(0.15);
    }
  }

  Color getActivityIconColor(String title) {
    switch (title) {
      case "Qualified Teachers":
        return Colors.blue;

      case "Strong Education":
        return Colors.green;

      case "Good Discipline":
        return Colors.purple;

      case "Sports Activities":
        return Colors.orange;

      case "Parent Connect App":
        return Colors.pink;

      default:
        return Colors.black;
    }
  }

  String get roleName {
    switch (widget.role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    autoSlide();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void autoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      _current = (_current + 1) % 3;

      if (_controller.hasClients) {
        _controller.animateToPage(
          _current,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

      autoSlide();
    });
  }

  List<Map<String, dynamic>> get stats {
    switch (widget.role) {
      case UserRole.admin:
        return [
          {
            'title': 'Students',
            'value': 'LIVE',
            'icon': Icons.groups_2_outlined
          },
          {'title': 'Teachers', 'value': 'LIVE', 'icon': Icons.badge_outlined},
          {
            'title': 'Admins',
            'value': '0',
            'icon': Icons.admin_panel_settings_outlined
          },
          {
            'title': 'Fees Paid',
            'value': '₹4.8L',
            'icon': Icons.payments_outlined
          },
          {'title': 'Notices', 'value': '24', 'icon': Icons.campaign_outlined},
        ];
      case UserRole.teacher:
        return [
          {'title': 'My Classes', 'value': '8', 'icon': Icons.class_outlined},
          {'title': 'Students', 'value': '320', 'icon': Icons.groups_outlined},
          {
            'title': 'Homework',
            'value': '14',
            'icon': Icons.assignment_outlined
          },
          {
            'title': 'Attendance',
            'value': '92%',
            'icon': Icons.fact_check_outlined
          },
        ];
      case UserRole.student:
        return [
          {'title': 'Present', 'value': '', 'icon': Icons.check_circle},
          {'title': 'Absent', 'value': '', 'icon': Icons.cancel},
          {'title': 'Fees Due', 'value': '', 'icon': Icons.payments_outlined},
          {'title': 'Class', 'value': 'Loading...', 'icon': Icons.school},
        ];
    }
  }

  List<Map<String, dynamic>> get features {
    switch (widget.role) {
      case UserRole.admin:
        return [
          {'title': 'Class & Section', 'icon': Icons.apartment_outlined},
          {'title': 'Timetable', 'icon': Icons.calendar_month_outlined},
          {'title': 'Attendance', 'icon': Icons.fact_check_outlined},
          {'title': 'Fees', 'icon': Icons.account_balance_wallet_outlined},
          {'title': 'Exams & Results', 'icon': Icons.school_outlined},
          {'title': 'Report', 'icon': Icons.bar_chart_rounded},
          {'title': 'Library', 'icon': Icons.local_library_outlined},
          {'title': 'Gallery', 'icon': Icons.photo_library_outlined},
        ];
      case UserRole.teacher:
        return [
          {'title': 'Attendance', 'icon': Icons.fact_check_outlined},
          {'title': 'Timetable', 'icon': Icons.calendar_today_outlined},
          {'title': 'Gallery', 'icon': Icons.photo_library_outlined},
        ];
      case UserRole.student:
        return [
          {'title': 'My Attendance', 'icon': Icons.fact_check_outlined},
          {'title': 'Fee Status', 'icon': Icons.payments_outlined},
          {'title': 'Results', 'icon': Icons.workspace_premium_outlined},
          {'title': 'Homework', 'icon': Icons.assignment_outlined},
          {'title': 'Notices', 'icon': Icons.notifications_outlined},
          {'title': 'Profile', 'icon': Icons.person_outline_rounded},
          {'title': 'Library', 'icon': Icons.local_library_outlined},
          {'title': 'Gallery', 'icon': Icons.photo_library_outlined},
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    final isTablet = width > 600;
    return Scaffold(
        backgroundColor: const Color(0xffeef3fb),
        floatingActionButton: null,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xffedf4ff),
                Color(0xfff6f8ff),
                Color(0xffeef2ff),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width > 900
                      ? 1180
                      : double.infinity,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 900 ? 18 : 0,
                  vertical: MediaQuery.of(context).size.width > 900 ? 18 : 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(
                    MediaQuery.of(context).size.width > 900 ? 34 : 0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  slivers: [
                    // 📌 PINNED SLIVER BANNER (HEADER + SLIDER INTEGRATED SINGLE CARD)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _MasterpieceBannerHeaderDelegate(
                        roleName: roleName,
                        onLogout: widget.onLogout,
                        activeGradient: _activeHeaderGradient,
                        activeAccent: _activeHeaderAccent,
                        topInset: MediaQuery.of(context).padding.top,
                        onStoryChanged: (gradient, accent) {
                          if (mounted) {
                            setState(() {
                              _activeHeaderGradient = gradient;
                              _activeHeaderAccent = accent;
                            });
                          }
                        },
                      ),
                    ),

                    // 📜 SCROLLABLE DASHBOARD BODY
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                              if (widget.role == UserRole.student)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // YEAR
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 0),
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade300),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ],
                                      ),
                                      child: DropdownButton<int>(
                                        value: selectedYear,
                                        underline: const SizedBox(),
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                            size: 16),
                                        items: List.generate(5, (i) {
                                          int year = DateTime.now().year - i;
                                          return DropdownMenuItem(
                                            value: year,
                                            child: Text(year.toString()),
                                          );
                                        }),
                                        onChanged: (v) {
                                          setState(() {
                                            selectedYear = v!;
                                          });
                                        },
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // MONTH
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 0),
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade300),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ],
                                      ),
                                      child: DropdownButton<int>(
                                        value: selectedMonth,
                                        underline: const SizedBox(),
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                            size: 16),
                                        items: List.generate(12, (i) {
                                          List<String> months = [
                                            "Jan",
                                            "Feb",
                                            "Mar",
                                            "Apr",
                                            "May",
                                            "Jun",
                                            "Jul",
                                            "Aug",
                                            "Sep",
                                            "Oct",
                                            "Nov",
                                            "Dec"
                                          ];
                                          return DropdownMenuItem(
                                            value: i + 1,
                                            child: Text(months[i]),
                                          );
                                        }),
                                        onChanged: (v) {
                                          setState(() {
                                            selectedMonth = v!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      itemCount: stats.length,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop
                            ? 4
                            : isTablet
                            ? 3
                            : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: isDesktop ? 1.35 : 1.1,
                      ),
                      itemBuilder: (context, index) {
                        final item = stats[index];
                        if (item['title'] == 'Students') {
                          return StreamBuilder(
                            stream: UserSession.yearColl('students')
                                .snapshots(),
                            builder: (context, snap) {
                              return statCard(
                                "Students",
                                snap.hasData
                                    ? snap.data!.docs.length.toString()
                                    : "0",
                                item['icon'],
                              );
                            },
                          );
                        }

                        if (item['title'] == 'Teachers') {
                          return StreamBuilder(
                            stream: UserSession.yearColl('teachers')
                                .snapshots(),
                            builder: (context, snap) {
                              return statCard(
                                "Teachers",
                                snap.hasData
                                    ? snap.data!.docs.length.toString()
                                    : "0",
                                item['icon'],
                              );
                            },
                          );
                        }

                        if (item['title'] == 'Admins') {
                          return StreamBuilder(
                            stream: UserSession.yearColl('admins')
                                .snapshots(),
                            builder: (context, snap) {
                              return statCard(
                                "Admins",
                                snap.hasData
                                    ? snap.data!.docs.length.toString()
                                    : "0",
                                item['icon'],
                              );
                            },
                          );
                        }
                        if (item['title'] == 'Class') {
                          return StreamBuilder(
                            stream: UserSession.yearColl(UserSession.collectionName)
                                .doc(UserSession.currentUserId ?? "")
                                .snapshots(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return statCard("Class", "...", item['icon']);
                              }

                              final data =
                              snap.data!.data() as Map<String, dynamic>;

                              return statCard(
                                "Class",
                                data['classSection'] ?? "-",
                                item['icon'],
                              );
                            },
                          );
                        }
                        if (item['title'] == 'Fees Paid') {
                          return StreamBuilder<QuerySnapshot>(
                            stream: UserSession.yearColl('fees')
                                .snapshots(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return statCard("Fees Paid", "₹0", item['icon']);
                              }

                              double totalAdd = 0;
                              double totalReceived = 0;

                              for (var doc in snap.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;

                                final double amount = double.tryParse(
                                    data['amount']?.toString() ?? "0") ??
                                    0;

                                final String type = (data['type'] ?? "")
                                    .toString()
                                    .toLowerCase()
                                    .trim();

                                final String status = (data['status'] ?? "")
                                    .toString()
                                    .toLowerCase()
                                    .trim();

                                // ✅ ONLY ADD
                                if (type == "add") {
                                  totalAdd += amount;
                                }

                                // ✅ RECEIVED
                                if (type == "received" ||
                                    type == "receive" ||
                                    status == "paid") {
                                  totalReceived += amount;
                                }
                              }

                              // 🔥 FINAL BALANCE
                              double finalAmount = totalAdd - totalReceived;

                              return statCard(
                                "Fees Due",
                                "₹${finalAmount.toStringAsFixed(0)}",
                                item['icon'],
                              );
                            },
                          );
                        }

                        if (item['title'] == 'Notices') {
                          return StreamBuilder(
                            stream: UserSession.yearColl('notices')
                                .snapshots(),
                            builder: (context, snap) {
                              return statCard(
                                "Notices",
                                snap.hasData
                                    ? snap.data!.docs.length.toString()
                                    : "0",
                                item['icon'],
                              );
                            },
                          );
                        }
                        if (item['title'] == 'Fees Due') {
                          final uid = UserSession.currentUserId ?? "";

                          return StreamBuilder(
                            stream: UserSession.yearColl('fees')
                                .where('studentId', isEqualTo: uid)
                                .snapshots(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return statCard("Fees Due", "₹0", item['icon']);
                              }

                              double totalAdd = 0;
                              double totalReceived = 0;

                              for (var doc in snap.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;

                                double amount = double.tryParse(
                                    data['amount']?.toString() ?? "0") ??
                                    0;

                                String type = (data['type'] ?? "")
                                    .toString()
                                    .toLowerCase()
                                    .trim();

                                String status = (data['status'] ?? "")
                                    .toString()
                                    .toLowerCase()
                                    .trim();

                                // ✅ ADD
                                if (type == "add") {
                                  totalAdd += amount;
                                }

                                // ✅ RECEIVED (FULL FIX)
                                if (type == "received" ||
                                    type == "receive" ||
                                    status == "paid") {
                                  totalReceived += amount;
                                }
                              }

                              double finalAmount = totalAdd - totalReceived;

                              return statCard(
                                "Fees Due",
                                "₹${finalAmount.toStringAsFixed(0)}",
                                item['icon'],
                              );
                            },
                          );
                        }

                        return statCard(
                          item['title'],
                          item['value'],
                          item['icon'],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Main Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      itemCount: features.length,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop
                            ? 4
                            : isTablet
                            ? 3
                            : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: isDesktop
                            ? 1.35
                            : isTablet
                            ? 1.15
                            : 1.12,
                      ),
                      itemBuilder: (context, index) {
                        final item = features[index];
                        return featureCard(item['title'], item['icon']);
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    activityTile(
                      'Qualified Teachers',
                      'Anubhavi teachers har student par dhyaan dete hain',
                      Icons.school_rounded,
                    ),
                    activityTile(
                      'Strong Education',
                      'Basic concepts par majboot pakad banai jati',
                      Icons.menu_book_rounded,
                    ),
                    activityTile(
                      'Good Discipline',
                      'Bachchon ko achhe sanskar aur discipline sikhaye',
                      Icons.verified_rounded,
                    ),
                    activityTile(
                      'Sports Activities',
                      'Regular khel se sharirik vikas hota hai',
                      Icons.sports_soccer_rounded,
                    ),
                    activityTile(
                      'Parent Connect App',
                      'Parents ko sab jankari ek jagah milti',
                      Icons.phone_android_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
);
  }

  Widget header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0369A1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🎨 LOGO WITH GLOW BORDER
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                "assets/logo.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 🏷️ SCHOOL NAME & ROLE DASHBOARD
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 👨‍💼 ROLE DASHBOARD PILL
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Text(
                    '$roleName Dashboard'.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // 🏫 SCHOOL NAME (HIGH-CONTRAST WHITE)
                const Text(
                  'BAL VIKASH GYAN MANDIR',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'RANIGANJ',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFBBF24),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // 🔘 ACTION BUTTON (LOGOUT)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onLogout,
            child: Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget premiumBanner() {
    return MasterpieceStudentBanner(
      roleName: roleName,
      onLogout: widget.onLogout,
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    // 🟢 PRESENT CARD
    if (title == "Present") {
      return attendanceCard(
        isPresent: true,
        selectedYear: selectedYear,
        selectedMonth: selectedMonth,
      );
    }

    if (title == "Absent") {
      return attendanceCard(
        isPresent: false,
        selectedYear: selectedYear,
        selectedMonth: selectedMonth,
      );
    }

    // 🔽 NORMAL CARD (Icon attached flush at top-left corner)
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xffe7edff)),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 🎨 FADED WATERMARK BACKGROUND ICON
            Positioned(
              right: -10,
              top: 6,
              child: Icon(
                icon,
                size: 72,
                color: getIconColor(title).withOpacity(0.08),
              ),
            ),
            // 📍 CIRCULAR ICON ATTACHED AT TOP-LEFT CORNER
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: getIconBgColor(title),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: getIconColor(title), size: 22),
              ),
            ),
            // 📝 CARD VALUE & TITLE
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 48, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.subText,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget featureCard(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        // ✅ Attendance
        if (title == "Attendance" || title == "My Attendance") {
          if (widget.role == UserRole.student) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StudentAttendancePage()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AttendancePage()),
            );
          }
        } else if (title == "Fees") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FeesPage(),
            ),
          );
        } else if (title == "Library") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LibraryPage()),
          );
        } else if (title == "Gallery") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GalleryPage(),
            ),
          );
        } else if (title == "Fee Status") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentFeesPage(), // 👈 NEW PAGE
            ),
          );
        }

        // ✅ Notices
        else if (title == "Notices") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoticesPage(role: widget.role),
            ),
          );
        }

        // ✅ Profile
        else if (title == "Profile") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfilePage(role: widget.role),
            ),
          );
        } else if (title == "Class & Section") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassAllocationPage(),
            ),
          );
        } else if (title == "Exams & Results" || title == "Results") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExamsPage(),
            ),
          );
        } else if (title == "Report") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentReportPage(),
            ),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: premiumCardDecoration(),
          child: Stack(
            children: [
              // 🎨 FADED WATERMARK BACKGROUND ICON
              Positioned(
                right: -10,
                top: 6,
                child: Icon(
                  icon,
                  size: 76,
                  color: getIconColor(title).withOpacity(0.08),
                ),
              ),

              // 📍 CIRCULAR ICON ATTACHED AT TOP-LEFT CORNER
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: getIconBgColor(title),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: getIconColor(title), size: 22),
                ),
              ),

              // 🔘 MICRO ACTION ARROW BADGE
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: getIconColor(title).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: getIconColor(title),
                  ),
                ),
              ),

              // 📝 CARD TITLE & DESCRIPTIVE SUBTITLE
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 48, 36, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        getFeatureSubtitle(title),
                        style: TextStyle(
                          color: getIconColor(title),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getFeatureSubtitle(String title) {
    switch (title) {
      case "Attendance":
      case "My Attendance":
        return "Daily Mark & View";
      case "Fees":
      case "Fee Status":
        return "Receipts & Dues";
      case "Exams & Results":
      case "Results":
        return "Marksheet & Rank";
      case "Report":
        return "Student Analytics";
      case "Timetable":
        return "Class Schedule";
      case "Class & Section":
        return "Manage Batches";
      case "Library":
        return "Books & Issue";
      case "Gallery":
        return "School Memories";
      case "Notices":
        return "Circulars & Alerts";
      case "Homework":
        return "Daily Tasks";
      case "Profile":
        return "Personal Info";
      default:
        return "Open Module";
    }
  }

  Widget activityTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: premiumCardDecoration(),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: getActivityBgColor(title), // ✅ CHANGE
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: getActivityIconColor(title)), // ✅ CHANGE
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.subText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    );
  }

  BoxDecoration premiumCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffe7edff)),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class _MasterpieceBannerHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String roleName;
  final Future<void> Function()? onLogout;
  final List<Color> activeGradient;
  final Color activeAccent;
  final Function(List<Color> gradient, Color accent) onStoryChanged;
  final double topInset;

  _MasterpieceBannerHeaderDelegate({
    required this.roleName,
    this.onLogout,
    required this.activeGradient,
    required this.activeAccent,
    required this.onStoryChanged,
    required this.topInset,
  });

  @override
  double get minExtent => topInset + 54.0;

  @override
  double get maxExtent => topInset + 245.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: activeGradient.first.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: activeGradient,
            ),
          ),
          child: OverflowBox(
            minHeight: maxExtent,
            maxHeight: maxExtent,
            alignment: Alignment.topCenter,
            child: MasterpieceStudentBanner(
              roleName: roleName,
              onLogout: onLogout,
              onStoryChanged: onStoryChanged,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MasterpieceBannerHeaderDelegate oldDelegate) {
    return oldDelegate.roleName != roleName ||
        oldDelegate.activeGradient != activeGradient ||
        oldDelegate.activeAccent != activeAccent ||
        oldDelegate.topInset != topInset;
  }
}

class MasterpieceStudentBanner extends StatefulWidget {
  final String roleName;
  final VoidCallback? onLogout;
  final Function(List<Color> gradient, Color accent)? onStoryChanged;

  const MasterpieceStudentBanner({
    super.key,
    this.roleName = 'Student',
    this.onLogout,
    this.onStoryChanged,
  });

  @override
  State<MasterpieceStudentBanner> createState() => _MasterpieceStudentBannerState();
}

class _MasterpieceStudentBannerState extends State<MasterpieceStudentBanner> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  Timer? _autoTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;

  late AnimationController _cloudController;
  late Animation<double> _cloudAnimation;

  final List<Map<String, dynamic>> _bannerStories = [
    {
      "step": "STEP 1 OF 3",
      "tag": "🚌 School Bus Journey",
      "title": "Subah Ki Nayi Shuruat",
      "desc": "Ghar se nikal kar surakshit school bus me dosto ke sath gyaan paane ka safar!",
      "gradient": [const Color(0xFF0F172A), const Color(0xFF0369A1), const Color(0xFF0284C7)],
      "accent": const Color(0xFF38BDF8),
      "avatar": "👦🏻🎒",
      "badge1": "🎒 Bus",
      "badge2": "✏️ Learn",
      "mainIcon": Icons.directions_bus_filled_rounded,
    },
    {
      "step": "STEP 2 OF 3",
      "tag": "📚 Study & Digital Tech",
      "title": "Books & Laptop Education",
      "desc": "Kitabo ke gyaan aur laptop se smart digital study karke Naye India me aage badhna!",
      "gradient": [const Color(0xFF0F172A), const Color(0xFF4338CA), const Color(0xFF6366F1)],
      "accent": const Color(0xFF818CF8),
      "avatar": "👦🏻💻",
      "badge1": "📚 Books",
      "badge2": "💻 Laptop",
      "mainIcon": Icons.laptop_chromebook_rounded,
    },
    {
      "step": "STEP 3 OF 3",
      "tag": "🎓 Graduation & Success",
      "title": "Kamyabi Aur Safalta",
      "desc": "Kada prayaas aur gyaan se jeevan me TOP karke parivar ka naam roshan!",
      "gradient": [const Color(0xFF0F172A), const Color(0xFFB45309), const Color(0xFFD97706)],
      "accent": const Color(0xFFFBBF24),
      "avatar": "👨🏼🎓🏆",
      "badge1": "🏅 Winner",
      "badge2": "🌟 Top",
      "mainIcon": Icons.emoji_events_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _autoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentIndex + 1) % _bannerStories.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(_rotateController);

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _cloudAnimation = Tween<double>(begin: -0.4, end: 1.4).animate(_cloudController);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _rotateController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: topInset + 245.0,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (widget.onStoryChanged != null) {
            widget.onStoryChanged!(
              _bannerStories[index]["gradient"] as List<Color>,
              _bannerStories[index]["accent"] as Color,
            );
          }
        },
          itemCount: _bannerStories.length,
          itemBuilder: (context, index) {
            final story = _bannerStories[index];
            final List<Color> bgColors = story["gradient"];
            final Color accentColor = story["accent"];

            return AnimatedBuilder(
              animation: Listenable.merge([
                _pulseAnimation,
                _floatAnimation,
                _rotateAnimation,
                _cloudAnimation,
              ]),
              builder: (context, child) {
                return Container(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      // 1. ANIMATED BACKGROUND PULSING AMBIENT ORB
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withOpacity(0.18),
                            ),
                          ),
                        ),
                      ),

                      // 2. ANIMATED DRIFTING CLOUD IN BACKGROUND SKY
                      Positioned(
                        left: MediaQuery.of(context).size.width * _cloudAnimation.value,
                        top: topInset + 45,
                        child: Opacity(
                          opacity: 0.22,
                          child: Row(
                            children: const [
                              Icon(Icons.cloud_rounded, color: Colors.white, size: 28),
                              SizedBox(width: 35),
                              Icon(Icons.cloud_queue_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),

                      // 3. ANIMATED ROTATING TWINKLE STAR
                      Positioned(
                        top: topInset + 45,
                        right: 65,
                        child: Transform.rotate(
                          angle: _rotateAnimation.value,
                          child: Icon(
                            Icons.auto_awesome,
                            color: accentColor.withOpacity(0.5),
                            size: 20,
                          ),
                        ),
                      ),

                      // 4. MAIN INTEGRATED LAYOUT: HEADER + STORY CONTENT
                      Column(
                        children: [
                          if (widget.onLogout != null) ...[
                            // 🏛️ INTEGRATED TOP HEADER BAR
                            Padding(
                              padding: EdgeInsets.fromLTRB(14, topInset + 6, 14, 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 🎨 LOGO WITH GLOW BORDER
                                  Container(
                                    height: 38,
                                    width: 38,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(11),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.8),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                        "assets/logo.png",
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 🏷️ SCHOOL NAME & ROLE DASHBOARD
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // 👨‍💼 ROLE DASHBOARD PILL
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                                          ),
                                          child: Text(
                                            '${widget.roleName} Dashboard'.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        // 🏫 SCHOOL NAME
                                        const Text(
                                          'BAL VIKASH GYAN MANDIR',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.1,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'RANIGANJ',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: accentColor,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 6),

                                  // 🔘 ACTION BUTTON (LOGOUT)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: widget.onLogout,
                                    child: Container(
                                      height: 34,
                                      width: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                                      ),
                                      child: const Icon(
                                        Icons.logout_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ➖ SUBTLE GLASS DIVIDER LINE
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              height: 1,
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ] else ...[
                            const SizedBox(height: 10),
                          ],

                          // 📖 STORY CONTENT AREA
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                              child: Row(
                                children: [
                                  // LEFT COLUMN: TEXT & PROGRESS INDICATORS
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Top Tag Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 5,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  color: accentColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                story["tag"],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Main Title & Description
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              story["title"],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              story["desc"],
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.85),
                                                fontSize: 10.5,
                                                height: 1.25,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),

                                        // Bottom Progress Indicators
                                        Row(
                                          children: List.generate(_bannerStories.length, (idx) {
                                            final isSelected = idx == _currentIndex;
                                            return AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              height: 5,
                                              width: isSelected ? 22 : 6,
                                              margin: const EdgeInsets.only(right: 4),
                                              decoration: BoxDecoration(
                                                color: isSelected ? accentColor : Colors.white30,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // RIGHT COLUMN: MULTI-ITEM ANIMATED GRAPHIC CANVAS
                                  Expanded(
                                    flex: 4,
                                    child: Transform.translate(
                                      offset: Offset(0, _floatAnimation.value),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Main Companion Graphic Card (Live Video Animation Effect)
                                          AnimatedStoryVideoGraphic(
                                            storyIndex: index,
                                            mainIcon: story["mainIcon"] as IconData,
                                            accentColor: accentColor,
                                          ),

                                          // Floating Item Badge 1 (Top Right Avatar)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                story["avatar"],
                                                style: const TextStyle(fontSize: 18),
                                              ),
                                            ),
                                          ),

                                          // Floating Item Badge 2 (Bottom Left Pill)
                                          Positioned(
                                            left: 0,
                                            bottom: 2,
                                            child: Transform.translate(
                                              offset: Offset(0, -_floatAnimation.value * 0.8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.4),
                                                  borderRadius: BorderRadius.circular(9),
                                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                                ),
                                                child: Text(
                                                  story["badge1"],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Floating Item Badge 3 (Top Left Pill)
                                          Positioned(
                                            left: 0,
                                            top: 2,
                                            child: Transform.translate(
                                              offset: Offset(0, _floatAnimation.value * 0.8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: accentColor.withOpacity(0.85),
                                                  borderRadius: BorderRadius.circular(9),
                                                ),
                                                child: Text(
                                                  story["badge2"],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
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
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
  }
}

class AnimatedStoryVideoGraphic extends StatefulWidget {
  final int storyIndex;
  final IconData mainIcon;
  final Color accentColor;

  const AnimatedStoryVideoGraphic({
    super.key,
    required this.storyIndex,
    required this.mainIcon,
    required this.accentColor,
  });

  @override
  State<AnimatedStoryVideoGraphic> createState() => _AnimatedStoryVideoGraphicState();
}

class _AnimatedStoryVideoGraphicState extends State<AnimatedStoryVideoGraphic>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _driveController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _driveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _driveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_spinController, _pulseController, _driveController]),
      builder: (context, child) {
        final spinVal = _spinController.value * 2 * pi;
        final pulseVal = 0.95 + (_pulseController.value * 0.12);
        final driveVal = _driveController.value;

        return Container(
          width: 90,
          height: 108,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.accentColor.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.25),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. ROTATING SCI-FI RADAR / VIDEO GLOW RING IN BACKGROUND
              Transform.rotate(
                angle: spinVal,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accentColor.withOpacity(0.4),
                      width: 1.8,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 2,
                        left: 28,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.accentColor,
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. STORY SPECIFIC VIDEO ANIMATION CONTENT
              if (widget.storyIndex == 0) ...[
                // 🚌 BUS JOURNEY ANIMATION VIDEO EFFECT
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.translate(
                      offset: Offset(0, sin(driveVal * 2 * pi) * 2.5),
                      child: Transform.scale(
                        scale: pulseVal,
                        child: Icon(
                          widget.mainIcon,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Moving Road Lines Effect
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 50,
                        height: 3,
                        color: Colors.white24,
                        child: Stack(
                          children: [
                            Positioned(
                              left: (driveVal * 50) - 16,
                              child: Container(
                                width: 16,
                                height: 3,
                                color: widget.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (widget.storyIndex == 1) ...[
                // 💻 BOOKS & LAPTOP ANIMATION VIDEO EFFECT
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: pulseVal,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            widget.mainIcon,
                            color: Colors.white,
                            size: 42,
                          ),
                          Positioned(
                            top: 13,
                            child: Container(
                              width: 18,
                              height: 9,
                              decoration: BoxDecoration(
                                color: widget.accentColor.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Center(
                                child: Container(
                                  width: 12,
                                  height: 2,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final h = 3.0 + sin((driveVal * 2 * pi) + i) * 3;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 3,
                          height: h.clamp(2.0, 8.0),
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ] else ...[
                // 🎓 TROPHY / SUCCESS ANIMATION VIDEO EFFECT
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: -spinVal * 0.5,
                      child: Icon(
                        Icons.brightness_5_rounded,
                        color: widget.accentColor.withOpacity(0.35),
                        size: 60,
                      ),
                    ),
                    Transform.scale(
                      scale: pulseVal,
                      child: Icon(
                        widget.mainIcon,
                        color: const Color(0xFFFFD700),
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ],

              // 3. TOP-LEFT LIVE VIDEO BADGE OVERLAY ("▶ LIVE")
              Positioned(
                top: 4,
                left: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.4),
                        blurRadius: 5,
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 9),
                      SizedBox(width: 1),
                      Text(
                        "LIVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SecondPage extends StatelessWidget {
  final UserRole role;
  final String title;

  const SecondPage({super.key, required this.role, required this.title});

  List<Map<String, String>> get items {
    if (role == UserRole.admin && title == 'Students') {
      return [
        {'name': 'Student Management', 'desc': 'Add, edit, delete students'},
        {'name': 'Teacher Management', 'desc': 'Add, edit, delete teachers'},
        // 👈 ADD
        {'name': 'Admin Management', 'desc': 'Add, edit, delete admins'},
        {'name': 'Class Allocation', 'desc': 'Assign class and section'},
        {'name': 'Slider and Logo Manage', 'desc': 'Uplode Images'},
      ];
    }
    if (role == UserRole.teacher && title == 'Attendance') {
      return [
        {
          'name': 'Mark Daily Attendance',
          'desc': 'Class wise attendance entry'
        },
        {'name': 'Monthly Report', 'desc': 'View attendance reports'},
        {'name': 'Late/Leave Status', 'desc': 'Track leave and late entry'},
      ];
    }
    return [
      {
        'name': 'Attendance Summary',
        'desc': 'View daily and monthly attendance'
      },
      {'name': 'Leave Request', 'desc': 'Apply for leave quickly'},
      {'name': 'Class Presence', 'desc': 'Monitor subject wise status'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CommonPage(
      title: title,
      icon: Icons.widgets_outlined,
      child: Column(
        children: items.map((e) {
          return GestureDetector(
            onTap: () {
              if (e['name'] == 'Student Management') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentListPage()),
                );
              }
              if (e['name'] == 'Class Allocation') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ClassAllocationPage()),
                );
              }
              if (e['name'] == 'Teacher Management') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TeacherListPage()),
                );
              }
              if (e['name'] == 'Admin Management') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminListPage()),
                );
              }
            },
            child: commonTile(e['name']!, e['desc']!),
          );
        }).toList(),
      ),
    );
  }

  Widget commonTile(String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: commonDecoration(),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xffedf3ff),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  desc,
                  style: const TextStyle(color: AppColors.subText),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ThirdPage extends StatelessWidget {
  final UserRole role;
  final String title;

  const ThirdPage({super.key, required this.role, required this.title});

  List<Map<String, String>> get items {
    if (role == UserRole.admin && title == 'Fees') {
      return [
        {'name': 'Fee Collection', 'desc': 'Collect and update monthly fees'},
        {'name': 'Fee History', 'desc': 'Track payment records'},
        {'name': 'Due Students', 'desc': 'See pending fee list'},
        {'name': 'Receipts', 'desc': 'Generate printable receipt'},
      ];
    }
    if (role == UserRole.teacher && title == 'Homework') {
      return [
        {'name': 'Upload Homework', 'desc': 'Subject wise homework publish'},
        {'name': 'Assignment Tracking', 'desc': 'Check submissions'},
        {'name': 'Remarks', 'desc': 'Send notes to students'},
      ];
    }
    return [
      {'name': 'Exam Results', 'desc': 'See marks and grades'},
      {'name': 'Performance Chart', 'desc': 'Track subject progress'},
      {'name': 'Rank & Remarks', 'desc': 'View teacher feedback'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CommonPage(
      title: title,
      icon: Icons.dashboard_customize_outlined,
      child: Column(
        children: items.map((e) {
          return itemTile(e['name']!, e['desc']!);
        }).toList(),
      ),
    );
  }

  Widget itemTile(String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: commonDecoration(),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xffedf3ff), Color(0xfff6f1ff)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child:
            const Icon(Icons.auto_graph_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  desc,
                  style: const TextStyle(color: AppColors.subText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NoticesPage extends StatelessWidget {
  final UserRole role;

  const NoticesPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final uid = UserSession.currentUserId;

    return Scaffold(
      floatingActionButton: role == UserRole.admin
          ? FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddNoticeDialog(),
          );
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      )
          : null,
      body: CommonPage(
        title: 'Notices',
        icon: Icons.notifications_active_outlined,
        child: StreamBuilder<QuerySnapshot>(
          stream: role == UserRole.admin
              ? UserSession.yearColl('notices')
              .orderBy(
            'time',
            descending: true,
          )
              .snapshots()
              : UserSession.yearColl('notices')
              .where(
            Filter.or(
              Filter(
                'role',
                isEqualTo: role.name,
              ),
              Filter(
                'studentId',
                isEqualTo: UserSession.currentUserId,
              ),
            ),
          )
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: commonDecoration(),
                child: const Center(
                  child: Text(
                    "Abhi koi notice nahi hai",
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            final docs = snap.data!.docs;

            // 🔥 SORT
            docs.sort((a, b) {
              final t1 = (a['time'] as Timestamp?)?.toDate() ?? DateTime.now();

              final t2 = (b['time'] as Timestamp?)?.toDate() ?? DateTime.now();

              return t2.compareTo(t1);
            });

            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;

                final data = doc.data() as Map<String, dynamic>;

                List seenBy = data['seenBy'] ?? [];

                bool seen = seenBy.contains(uid);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: commonDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.campaign_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            formatNoticeTime(d['time']),
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontSize: 12,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 1),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: AppColors.subText,
                                  height: 1.08,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                    (d['message'] ?? '').split("\n").first,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                    "\n${(d['message'] ?? '').split("\n").skip(1).join("\n")}",
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              if (!seen) {
                                await UserSession.yearColl('notices')
                                    .doc(doc.id)
                                    .update({
                                  'seenBy': FieldValue.arrayUnion([uid])
                                });
                              }
                            },
                            child: Container(
                              height: 26,
                              width: 26,
                              decoration: BoxDecoration(
                                color:
                                seen ? Colors.green : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "OK",
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: seen ? Colors.white : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  String formatNoticeTime(dynamic time) {
    if (time == null) return "";

    try {
      final dt = (time as Timestamp).toDate();

      String day = "${dt.day}/${dt.month}/${dt.year}";

      int hour = dt.hour;

      String ampm = hour >= 12 ? "PM" : "AM";

      hour = hour % 12;

      if (hour == 0) hour = 12;

      String minute = dt.minute.toString().padLeft(2, '0');

      return "$day  $hour:$minute $ampm";
    } catch (e) {
      return "";
    }
  }

  Widget noticeCard(
      String title,
      String desc,
      String time,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: commonDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.campaign_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 12,
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(
              color: AppColors.subText,
              height: 1.5,
            ),
          )
        ],
      ),
    );
  }
}

class AddNoticeDialog extends StatefulWidget {
  const AddNoticeDialog({super.key});

  @override
  State<AddNoticeDialog> createState() => _AddNoticeDialogState();
}

class _AddNoticeDialogState extends State<AddNoticeDialog> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController msgCtrl = TextEditingController();

  String selectedRole = "student";
  bool loading = false;

  Future<void> sendNotice() async {
    final title = titleCtrl.text.trim();
    final message = msgCtrl.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Heading aur message likhiye")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await UserSession.yearColl('notices').add({
        'title': title,
        'message': message,
        'role': selectedRole,
        'time': FieldValue.serverTimestamp(),
        'seenBy': [],
      });

      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notice sent successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Send Notice"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: "Heading",
                hintText: "Notice heading",
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Message",
                hintText: "Notice message type kijiye",
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: "Select Role",
              ),
              items: const [
                DropdownMenuItem(
                  value: "teacher",
                  child: Text("Teacher"),
                ),
                DropdownMenuItem(
                  value: "student",
                  child: Text("Student"),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  selectedRole = v!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: loading ? null : sendNotice,
          child: loading
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text("Send"),
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  final UserRole role;

  const ProfilePage({super.key, required this.role});

  String get roleText {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = UserSession.currentUserId ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<DocumentSnapshot>(
        stream: UserSession.yearColl(UserSession.collectionName)
            .doc(userId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};

          String studentName = (data['name'] ?? data['studentName'] ?? "").toString();
          String email = (data['email'] ?? "").toString();
          String mobile = (data['mobile'] ?? data['phone'] ?? "").toString();
          String address = (data['address'] ?? "").toString();
          String father = (data['father'] ?? data['fatherName'] ?? "").toString();
          String mother = (data['mother'] ?? data['motherName'] ?? "").toString();
          String classSec = (data['classSection'] ?? data['class'] ?? "").toString();
          String rollNo = (data['rollNo'] ?? "").toString();
          String admNo = (data['admNo'] ?? data['admissionNo'] ?? "").toString();
          String photoUrl = (data['photo'] ?? data['photoUrl'] ?? data['imageUrl'] ?? "").toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              children: [
                // 🔷 TOP BANNER + FLOATING PROFILE CARD STACK
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Top Decorative Cover Banner
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFDBA74), Color(0xFFF97316), Color(0xFFEA580C)],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(36),
                          bottomRight: Radius.circular(36),
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "Profile",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // FLOATING OVERLAPPING PROFILE CARD
                    Padding(
                      padding: const EdgeInsets.only(top: 110, left: 16, right: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Student Profile Photo
                            Container(
                              height: 90,
                              width: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFF97316), width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: photoUrl.isNotEmpty
                                    ? buildSmartImage(photoUrl, fit: BoxFit.cover)
                                    : Container(
                                        color: const Color(0xFFFED7AA),
                                        child: const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Color(0xFFEA580C),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Student Name
                            Text(
                              studentName.isNotEmpty ? studentName.toUpperCase() : "STUDENT",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Subtitle (Role / Class)
                            Text(
                              classSec.isNotEmpty ? "Class: $classSec | $roleText" : roleText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // QUICK STATS BADGE ROW
                            if (role == UserRole.student)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFFFEDD5)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem("Class", classSec.isNotEmpty ? classSec : "-"),
                                    Container(height: 24, width: 1, color: const Color(0xFFFDBA74)),
                                    _buildStatItem("Roll No", rollNo.isNotEmpty ? rollNo : "-"),
                                    Container(height: 24, width: 1, color: const Color(0xFFFDBA74)),
                                    buildGoldMedalRibbonBadge(size: 30),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 🔷 PERSONAL & ACADEMIC DATA TILES LIST
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          "Personal & Academic Info",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),

                      if (email.isNotEmpty)
                        _buildProfileTile(
                          icon: Icons.email_outlined,
                          title: "Email",
                          value: email,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                        ),

                      _buildProfileTile(
                        icon: Icons.phone_outlined,
                        title: "Phone",
                        value: mobile.isNotEmpty ? mobile : "Not Available",
                        iconBg: const Color(0xFFF0FDF4),
                        iconColor: const Color(0xFF16A34A),
                      ),

                      if (father.isNotEmpty)
                        _buildProfileTile(
                          icon: Icons.person_outline,
                          title: "Father's Name",
                          value: father,
                          iconBg: const Color(0xFFFFF7ED),
                          iconColor: const Color(0xFFEA580C),
                        ),

                      if (mother.isNotEmpty)
                        _buildProfileTile(
                          icon: Icons.face_3_outlined,
                          title: "Mother's Name",
                          value: mother,
                          iconBg: const Color(0xFFFDF2F8),
                          iconColor: const Color(0xFFDB2777),
                        ),

                      if (classSec.isNotEmpty)
                        _buildProfileTile(
                          icon: Icons.school_outlined,
                          title: "Class & Section",
                          value: classSec,
                          iconBg: const Color(0xFFEEF2FF),
                          iconColor: const Color(0xFF4F46E5),
                        ),

                      _buildProfileTile(
                        icon: Icons.location_on_outlined,
                        title: "Address",
                        value: address.isNotEmpty ? address : "Raniganj",
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                      ),

                      _buildProfileTile(
                        icon: Icons.settings_outlined,
                        title: "Settings",
                        value: "Theme, security, notifications",
                        iconBg: const Color(0xFFF1F5F9),
                        iconColor: const Color(0xFF475569),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFFC2410C),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9A3412),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String value,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildGoldMedalRibbonBadge({double size = 30}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: size * 0.55,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: 0.25,
                  child: Container(
                    width: size * 0.36,
                    height: size * 0.55,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: size * 0.06),
                Transform.rotate(
                  angle: -0.25,
                  child: Container(
                    width: size * 0.36,
                    height: size * 0.55,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFDE047), Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: size * 0.72,
                height: size * 0.72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF59E0B),
                ),
                child: Center(
                  child: Icon(
                    Icons.star,
                    color: Colors.white,
                    size: size * 0.48,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: size * 0.4),
      const Text(
        "Verified",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9A3412),
        ),
      ),
    ],
  );
}

class CommonPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? bottomNavigationBar;

  const CommonPage({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
              children: [
                Row(
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.black,
                      ),
                      child: Icon(icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search_rounded),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration commonDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: const Color(0xffe7edff)),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

class AddUserDialog extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? oldData;

  AddUserDialog({this.docId, this.oldData});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final fatherCtrl = TextEditingController();
  final motherCtrl = TextEditingController();
  final rollCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  String? imageUrl;
  Uint8List? imageBytes;

  String? role; // 🔥 Initialized to null so no role is pre-selected by default!
  String? selectedClass;

  List<Map<String, dynamic>> classList = [];

  List<String> subjectList = [
    "Math",
    "Science",
    "English",
    "Hindi",
    "Computer",
    "Social Studies",
    "Sanskrit",
    "All Subjects",
  ];

  String subject = "Math";

  @override
  void initState() {
    super.initState();

    if (widget.oldData != null) {
      nameCtrl.text = widget.oldData!['name'] ?? "";
      fatherCtrl.text = widget.oldData!['fatherName'] ?? "";
      motherCtrl.text = widget.oldData!['motherName'] ?? "";
      rollCtrl.text = widget.oldData!['rollNo'] ?? "";
      mobileCtrl.text = widget.oldData!['mobile'] ?? "";
      addressCtrl.text = widget.oldData!['address'] ?? "";
      emailCtrl.text = widget.oldData!['email'] ?? "";
      passCtrl.text = widget.oldData!['password'] ?? "";
      imageUrl = widget.oldData!['photo'];
      role = widget.oldData!['role'];
      selectedClass = widget.oldData!['classSection'];
      if (widget.oldData!['subject'] != null &&
          widget.oldData!['subject'].toString().isNotEmpty) {
        subject = widget.oldData!['subject'];
      }
    }

    UserSession.yearColl('classes').get().then((snap) {
      if (mounted) {
        setState(() {
          classList = snap.docs.map((e) => e.data()).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    fatherCtrl.dispose();
    motherCtrl.dispose();
    rollCtrl.dispose();
    mobileCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  Future<void> showAddClassDialog() async {
    final clsCtrl = TextEditingController();
    final secCtrl = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.class_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text("Create New Class", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: clsCtrl,
              decoration: InputDecoration(
                labelText: "Class Name (e.g. 10th, 9, Nursery)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: secCtrl,
              decoration: InputDecoration(
                labelText: "Section (e.g. A, B, C)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final c = clsCtrl.text.trim();
              final s = secCtrl.text.trim();
              if (c.isEmpty) return;

              final sectionName = s.isEmpty ? "A" : s;

              await UserSession.yearColl('classes').add({
                "className": c,
                "section": sectionName,
              });

              if (ctx.mounted) {
                Navigator.pop(ctx, "$c-$sectionName");
              }
            },
            child: const Text("Create & Select", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final snap = await UserSession.yearColl('classes').get();
      if (mounted) {
        setState(() {
          classList = snap.docs.map((e) => e.data()).toList();
          selectedClass = result;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Class $result created and selected"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      imageBytes = await picked.readAsBytes();
      setState(() {});
    }
  }

  Future<String?> uploadImage() async {
    if (imageBytes == null) return null;
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child("uploads/$fileName.jpg");
      final metadata = SettableMetadata(contentType: "image/jpeg");
      final task = await ref.putData(imageBytes!, metadata);
      final url = await task.ref.getDownloadURL();
      if (url.isNotEmpty) return url;
    } catch (e) {
      print("Storage Upload Error (Falling back to Base64 encoding): $e");
    }
    // Base64 encoding fallback ensures image is ALWAYS saved even if storage fails!
    return "data:image/jpeg;base64,${base64Encode(imageBytes!)}";
  }

  String targetCollection(String targetRole) {
    if (targetRole == 'admin') return 'admins';
    if (targetRole == 'teacher') return 'teachers';
    return 'students';
  }

  Future<void> saveUser() async {
    if (role == null || role!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kripya pehle Role (Student, Teacher ya Admin) select karein"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kripya Name bharein"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (passCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kripya Password bharein"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (imageBytes != null) {
        imageUrl = await uploadImage();
      }

      final String targetColl = targetCollection(role!);

      final String finalPhoto = imageUrl ??
          widget.oldData?['photo'] ??
          widget.oldData?['photoUrl'] ??
          widget.oldData?['imageUrl'] ??
          "";

      final Map<String, dynamic> userData = {
        'name': nameCtrl.text.trim(),
        'fatherName': fatherCtrl.text.trim(),
        'motherName': motherCtrl.text.trim(),
        'rollNo': rollCtrl.text.trim(),
        'mobile': mobileCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'photo': finalPhoto,
        'photoUrl': finalPhoto,
        'imageUrl': finalPhoto,
        'role': role,
        'classSection': selectedClass ?? "",
        'subject': role == "teacher" ? subject : "",
        'password': passCtrl.text.trim(),
      };

      if (widget.docId != null) {
        await UserSession.yearColl(targetColl)
            .doc(widget.docId)
            .update(userData);
      } else {
        userData['createdAt'] = FieldValue.serverTimestamp();
        await UserSession.yearColl(targetColl).add(userData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.docId != null ? "User updated successfully" : "User added successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Save user error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.subText),
      prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffd1d9e6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffe2e8f0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      filled: true,
      fillColor: const Color(0xfff8fafc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.docId != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? "Edit User Details" : "Add New User",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. SELECT ROLE DROPDOWN (TOP ME)
                    const Text(
                      "Select User Role *",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xfff1f5f9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: role == null ? Colors.orange.shade300 : const Color(0xffcbd5e1),
                          width: role == null ? 1.5 : 1.0,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: role,
                          hint: const Text(
                            "-- Choose Role (Student / Teacher / Admin) --",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: "student",
                              child: Row(
                                children: [
                                  Icon(Icons.school_outlined, size: 18, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text("Student", style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: "teacher",
                              child: Row(
                                children: [
                                  Icon(Icons.person_pin_outlined, size: 18, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text("Teacher", style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: "admin",
                              child: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings_outlined, size: 18, color: Colors.purple),
                                  SizedBox(width: 8),
                                  Text("Admin", style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              role = v;
                            });
                          },
                        ),
                      ),
                    ),

                    if (role == null) ...[
                      const SizedBox(height: 30),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.touch_app_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text(
                              "Kripya uper se Role select karein\n(Student, Teacher ya Admin)",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.subText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ] else ...[
                      const SizedBox(height: 16),

                      // PROFILE PHOTO PICKER
                      Center(
                        child: GestureDetector(
                          onTap: pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: const Color(0xfff1f5f9),
                                child: imageBytes != null
                                    ? ClipOval(
                                        child: Image.memory(
                                          imageBytes!,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (imageUrl != null && imageUrl!.isNotEmpty)
                                        ? ClipOval(
                                            child: SizedBox(
                                              width: 72,
                                              height: 72,
                                              child: buildSmartImage(imageUrl!, fit: BoxFit.cover),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person_rounded,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // COMMON FIELD: NAME
                      TextField(
                        controller: nameCtrl,
                        decoration: _inputDec("Full Name *", Icons.person_outline_rounded),
                      ),
                      const SizedBox(height: 12),

                      // STUDENT SPECIFIC FIELDS
                      if (role == "student") ...[
                        TextField(
                          controller: fatherCtrl,
                          decoration: _inputDec("Father Name", Icons.family_restroom_rounded),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: motherCtrl,
                          decoration: _inputDec("Mother Name", Icons.face_rounded),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: rollCtrl,
                          decoration: _inputDec("Roll No", Icons.format_list_numbered_rounded),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xfff8fafc),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xffe2e8f0)),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    List<DropdownMenuItem<String>> classMenuItems = [
                                      ...classList.map((e) {
                                        String val = "${e['className']}-${e['section']}";
                                        return DropdownMenuItem(
                                          value: val,
                                          child: Text(
                                            "Class ${e['className']} - ${e['section']}",
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }),
                                    ];

                                    if (selectedClass != null &&
                                        selectedClass!.isNotEmpty &&
                                        !classMenuItems.any((item) => item.value == selectedClass)) {
                                      classMenuItems.add(
                                        DropdownMenuItem(
                                          value: selectedClass,
                                          child: Text(
                                            "Class $selectedClass",
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      );
                                    }

                                    classMenuItems.add(
                                      const DropdownMenuItem(
                                        value: "__ADD_NEW__",
                                        child: Text(
                                          "+ Create New Class",
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );

                                    return DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedClass,
                                        hint: const Text(
                                          "Select Class",
                                          style: TextStyle(
                                              fontSize: 13, color: AppColors.subText),
                                        ),
                                        isExpanded: true,
                                        items: classMenuItems,
                                        onChanged: (v) {
                                          if (v == "__ADD_NEW__") {
                                            showAddClassDialog();
                                          } else {
                                            setState(() => selectedClass = v);
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: showAddClassDialog,
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xffedf3ff),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xffc6d7ff)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.add_circle_outline, color: AppColors.primary, size: 18),
                                    SizedBox(width: 4),
                                    Text("+ Class", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // TEACHER SPECIFIC FIELDS
                      if (role == "teacher") ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xfff8fafc),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xffe2e8f0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.book_outlined, size: 20, color: AppColors.primary),
                              const SizedBox(width: 10),
                              const Text("Subject:", style: TextStyle(fontSize: 13, color: AppColors.subText)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    List<DropdownMenuItem<String>> subjItems = subjectList.map((s) {
                                      return DropdownMenuItem(value: s, child: Text(s));
                                    }).toList();

                                    if (subject != null &&
                                        subject!.isNotEmpty &&
                                        !subjItems.any((item) => item.value == subject)) {
                                      subjItems.add(DropdownMenuItem(value: subject!, child: Text(subject!)));
                                    }

                                    return DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: subject,
                                        isExpanded: true,
                                        items: subjItems,
                                        onChanged: (v) {
                                          if (v != null) setState(() => subject = v);
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // MOBILE & ADDRESS
                      TextField(
                        controller: mobileCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDec("Mobile Number", Icons.phone_android_rounded),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressCtrl,
                        decoration: _inputDec("Address", Icons.location_on_outlined),
                      ),
                      const SizedBox(height: 12),

                      // EMAIL / USERNAME & PASSWORD
                      TextField(
                        controller: emailCtrl,
                        decoration: _inputDec("Email / User ID", Icons.email_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passCtrl,
                        decoration: _inputDec("Password *", Icons.lock_outline_rounded),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: saveUser,
                  child: Text(
                    isEdit ? "Update User" : "Save User",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StudentListPage extends StatefulWidget {
  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  String searchText = "";

  Future<void> exportStudentsExcel() async {
    try {
      final excel = ex.Excel.createExcel();

      // Select 'Students' sheet
      final ex.Sheet sheet = excel['Students'];

      // 1. COLUMN HEADERS ROW
      sheet.appendRow([
        "Name",
        "Father Name",
        "Mother Name",
        "Mobile",
        "Roll No",
        "Address",
        "Class Section",
        "Email",
        "Password",
      ]);

      // 2. PRE-FILL EXISTING STUDENTS DATA
      final studentSnap = await UserSession.yearColl('students').get();
      for (var doc in studentSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        sheet.appendRow([
          (d['name'] ?? "").toString(),
          (d['fatherName'] ?? "").toString(),
          (d['motherName'] ?? "").toString(),
          (d['mobile'] ?? "").toString(),
          (d['rollNo'] ?? "").toString(),
          (d['address'] ?? "").toString(),
          (d['classSection'] ?? "").toString(),
          (d['email'] ?? "").toString(),
          (d['password'] ?? "").toString(),
        ]);
      }

      // 3. PRE-FILL AVAILABLE CLASSES REFERENCE SHEET
      final classSnap = await UserSession.yearColl('classes').get();
      final ex.Sheet classSheet = excel['Available Classes'];
      classSheet.appendRow(["Available Classes (Use exact name in Class Section column)"]);
      for (var doc in classSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String cls = "${data['className']}-${data['section']}";
        classSheet.appendRow([cls]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to generate Excel file")),
          );
        }
        return;
      }

      // 4. SAFE FILE SAVE WITH FALLBACK FOR ALL ANDROID VERSIONS
      File? savedFile;
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (!downloadDir.existsSync()) {
          downloadDir.createSync(recursive: true);
        }
        savedFile = File("${downloadDir.path}/students_template.xlsx");
        await savedFile.writeAsBytes(bytes);
      } catch (e) {
        print("Download dir write failed: $e, using app docs directory...");
        savedFile = null;
      }

      if (savedFile == null || !savedFile.existsSync()) {
        final appDir = await getApplicationDocumentsDirectory();
        savedFile = File("${appDir.path}/students_template.xlsx");
        await savedFile.writeAsBytes(bytes);
      }

      print("✅ Excel Saved: ${savedFile.path}");

      // Try opening the Excel file
      try {
        await OpenFile.open(savedFile.path);
      } catch (e) {
        print("OpenFile Error: $e");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Excel Template Exported: ${savedFile.path}"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("❌ EXPORT ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Export Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> importStudentsExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      final excel = ex.Excel.decodeBytes(bytes);

      // Get 'Students' sheet or default first sheet
      ex.Sheet? sheet = excel.tables['Students'] ?? (excel.tables.isNotEmpty ? excel.tables.values.first : null);

      if (sheet == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Excel file is empty or invalid")),
          );
        }
        return;
      }

      int success = 0;
      int fail = 0;

      String getCellValue(List<dynamic> row, int index) {
        if (index >= row.length || row[index] == null) return "";
        final cell = row[index];
        if (cell == null) return "";
        try {
          final dynamic val = (cell is Map || cell.runtimeType.toString().contains("Data"))
              ? cell.value
              : cell;
          return (val ?? "").toString().trim();
        } catch (_) {
          return cell.toString().trim();
        }
      }

      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty) continue;

        String name = getCellValue(row, 0);
        String father = getCellValue(row, 1);
        String mother = getCellValue(row, 2);
        String mobile = getCellValue(row, 3);
        String roll = getCellValue(row, 4);
        String address = getCellValue(row, 5);
        String classSection = getCellValue(row, 6);
        String email = getCellValue(row, 7);
        String password = getCellValue(row, 8);

        // Skip header or empty rows
        if (name.isEmpty && mobile.isEmpty && email.isEmpty && roll.isEmpty) {
          continue;
        }

        if (name.toLowerCase() == "name" && father.toLowerCase().contains("father")) {
          continue; // Skip header row if re-read
        }

        // Auto-fill fallback values for smooth creation
        if (email.isEmpty) {
          email = mobile.isNotEmpty ? mobile : "std_${DateTime.now().millisecondsSinceEpoch}_$i";
        }
        if (password.isEmpty) {
          password = "123456";
        }

        try {
          await UserSession.yearColl('students').add({
            "name": name,
            "fatherName": father,
            "motherName": mother,
            "mobile": mobile,
            "rollNo": roll,
            "address": address,
            "classSection": classSection,
            "email": email,
            "password": password,
            "role": "student",
            "createdAt": FieldValue.serverTimestamp(),
          });

          success++;
        } catch (e) {
          print("❌ Row $i Import Error: $e");
          fail++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Import Finished: ✅ $success Created, ❌ $fail Failed"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Import Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Import Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> selectedClasses = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text("Students"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        actions: [
          // 📥 EXPORT BUTTON
          IconButton(
            icon: Icon(Icons.download),
            onPressed: exportStudentsExcel,
          ),

          // 📤 IMPORT BUTTON
          IconButton(
            icon: Icon(Icons.upload),
            onPressed: importStudentsExcel,
          ),
        ],
      ),
      body: Center(
        child: Container(
          width:
          MediaQuery.of(context).size.width > 900 ? 1100 : double.infinity,
          child: Column(
            children: [
              // 🔍 SEARCH + FILTER UI
              Container(
                margin: EdgeInsets.all(12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    // 🔍 SEARCH
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search student...",
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        setState(() {
                          searchText = val.toLowerCase();
                        });
                      },
                    ),

                    SizedBox(height: 10),

                    // 🎯 CLASS FILTER BUTTON
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        onPressed: () async {
                          final usersSnap = await UserSession.yearColl('students')
                              .get();

                          List<String> classList = usersSnap.docs
                              .map((e) =>
                              (e.data()['classSection'] ?? "").toString())
                              .where((e) => e.isNotEmpty)
                              .toSet()
                              .toList();

                          List<String> temp = List.from(selectedClasses);

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            builder: (_) {
                              return StatefulBuilder(
                                builder: (context, setModalState) {
                                  return SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.65,
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 10),

                                        const Text(
                                          "Select Classes",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        // 🔥 APPLY BUTTON (UPPER FIX)
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  selectedClasses = temp;
                                                });
                                                Navigator.pop(context);
                                              },
                                              child: const Text("Apply"),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        // 🔥 LIST
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: classList.length,
                                            itemBuilder: (context, index) {
                                              final c = classList[index];

                                              return CheckboxListTile(
                                                value: temp.contains(c),
                                                title: Text(c),
                                                onChanged: (v) {
                                                  setModalState(() {
                                                    if (v == true) {
                                                      if (!temp.contains(c))
                                                        temp.add(c);
                                                    } else {
                                                      temp.remove(c);
                                                    }
                                                  });
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: Text("Select Class"),
                      ),
                    ),

                    SizedBox(height: 6),

                    // 🔵 SELECTED CHIP
                    Wrap(
                      spacing: 6,
                      children: selectedClasses.map((e) {
                        return Container(
                          padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                e,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedClasses.remove(e);
                                  });
                                },
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.blue),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),

              // 🔥 LIST (UNCHANGED)
              Expanded(
                child: StreamBuilder(
                  stream: UserSession.yearColl('students')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final allData = snapshot.data!.docs;

                    final data = allData.where((doc) {
                      final u = doc.data() as Map<String, dynamic>;

                      final name = (u['name'] ?? "").toString().toLowerCase();
                      final cls = (u['classSection'] ?? "").toString();

                      bool matchSearch = name.contains(searchText);

                      bool matchClass = selectedClasses.isEmpty
                          ? true
                          : selectedClasses.contains(cls);

                      return matchSearch && matchClass;
                    }).toList();

                    return ListView.builder(
                      padding: EdgeInsets.all(12),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final user = data[index];
                        final u = user.data() as Map<String, dynamic>;

                        return Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Text("${index + 1}.",
                                  style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 10),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade200,
                                ),
                                child: ClipOval(
                                  child: (u['photo'] != null &&
                                      u['photo'].toString().isNotEmpty)
                                      ? Image.network(
                                    u['photo'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                        ) {
                                      print("IMAGE ERROR: $error");

                                      return const Icon(
                                        Icons.person,
                                      );
                                    },
                                  )
                                      : const Icon(
                                    Icons.person,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u['name'] ?? "No Name",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      "Roll No: ${u['rollNo'] ?? "-"}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.subText,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      "Class: ${u['classSection'] ?? "-"}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AddUserDialog(
                                      docId: user.id,
                                      oldData: u,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  bool confirm = await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text("Confirm Delete"),
                                      content: Text(
                                          "Kya aap is student ko delete karna chahte hain?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text("Delete"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await UserSession.yearColl('students')
                                        .doc(user.id)
                                        .delete();
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TeacherListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text("Teachers"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: UserSession.yearColl('teachers')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final user = data[index];
              final u = user.data() as Map<String, dynamic>;

              return Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Text("${index + 1}.",
                        style: TextStyle(fontWeight: FontWeight.bold)),

                    SizedBox(width: 10),

                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (u['photo'] != null && u['photo'] != "")
                          ? NetworkImage(u['photo'])
                          : null,
                      child: (u['photo'] == null || u['photo'] == "")
                          ? Icon(Icons.person)
                          : null,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u['name'] ?? "No Name",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            u['subject'] ?? "-",
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    // EDIT
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddUserDialog(
                            docId: user.id,
                            oldData: u,
                          ),
                        );
                      },
                    ),

                    // DELETE
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        bool confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("Confirm Delete"),
                            content: Text(
                                "Kya aap is teacher ko delete karna chahte hain?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("Delete"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await UserSession.yearColl('teachers')
                              .doc(user.id)
                              .delete();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AttendancePage extends StatefulWidget {
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime? selectedDate;

  String selectedClassFilter = "All";
  List<String> classList = ["All"];

  TextEditingController searchCtrl = TextEditingController();

  int presentCount = 0;
  int absentCount = 0;

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    final snap = await UserSession.yearColl('classes').get();

    setState(() {
      classList = ["All"] +
          snap.docs.map((e) {
            final d = e.data();
            return "${d['className']}-${d['section']}";
          }).toList();
    });
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() => selectedDate = date);
      loadCounts();
    }
  }

  String get dateId =>
      "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}";

  Future<void> loadCounts() async {
    if (selectedDate == null) return;

    final snap = await UserSession.yearColl('attendance')
        .where('dateId', isEqualTo: dateId)
        .get();

    int p = 0;
    int a = 0;

    for (var d in snap.docs) {
      if (d['status'] == "P") p++;
      if (d['status'] == "A") a++;
    }

    setState(() {
      presentCount = p;
      absentCount = a;
    });
  }

  Future<void> markAll(String value) async {

    if (selectedDate == null) return;

    final snap = await UserSession.yearColl('students')
        .get();

    final students = snap.docs.where((doc) {

      final data = doc.data();

      if (selectedClassFilter != "All" &&
          (data['classSection'] ?? "") != selectedClassFilter) {
        return false;
      }

      final name =
      (data['name'] ?? "").toLowerCase();

      if (searchCtrl.text.isNotEmpty &&
          !name.contains(searchCtrl.text.toLowerCase())) {
        return false;
      }

      return true;

    }).toList();

    WriteBatch batch =
    FirebaseFirestore.instance.batch();

    for (var s in students) {

      final id = s.id;

      final docId = "${id}_$dateId";

      batch.set(

        UserSession.yearColl('attendance')
            .doc(docId),

        {

          'studentId': id,

          'date': Timestamp.fromDate(selectedDate!),

          'dateId': dateId,

          'status': value,

          'updatedAt':
          FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();

    loadCounts();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Attendance",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 21,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: false,
        elevation: 6,
        shadowColor: const Color(0xFF064E3B).withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF064E3B), // Deep Emerald Forest Midnight
                Color(0xFF047857), // Deep Emerald Teal
                Color(0xFF059669), // Rich Vibrant Emerald
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // DATE + FILTER
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickDate,
                    icon: const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.white),
                    label: Text(
                      selectedDate == null
                          ? "Select Date"
                          : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: selectedClassFilter,
                    underline: SizedBox(),
                    items: classList.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedClassFilter = v!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: "Search student...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),

          const SizedBox(height: 10),

          // 🔥 COMPACT BUTTONS
          if (selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // PRESENT
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Text("P",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        SizedBox(width: 5),
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text("$presentCount",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.green)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  GestureDetector(

                    onTap: () {
                      markAll("A");
                    },

                    child: Container(

                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(

                        color: Colors.red,

                        borderRadius: BorderRadius.circular(30),
                      ),

                      child: const Text(

                        "ALL A",

                        style: TextStyle(

                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  GestureDetector(

                    onTap: () {
                      markAll("P");
                    },

                    child: Container(

                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(

                        color: Colors.green,

                        borderRadius: BorderRadius.circular(30),
                      ),

                      child: const Text(

                        "ALL P",

                        style: TextStyle(

                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),


                  SizedBox(width: 8),

                  // ABSENT
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Text("A",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        SizedBox(width: 5),
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text("$absentCount",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // LIST
          if (selectedDate != null)
            Expanded(
              child: StreamBuilder(
                stream: UserSession.yearColl('students')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final allStudents = snapshot.data!.docs;

                  final students = allStudents.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    if (selectedClassFilter != "All" &&
                        (data['classSection'] ?? "") != selectedClassFilter) {
                      return false;
                    }

                    final name = (data['name'] ?? "").toLowerCase();

                    if (searchCtrl.text.isNotEmpty &&
                        !name.contains(searchCtrl.text.toLowerCase())) {
                      return false;
                    }

                    return true;
                  }).toList();

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final data =
                      students[index].data() as Map<String, dynamic>;

                      return AttendanceTile(
                        name: data['name'] ?? "",
                        roll: data['rollNo'] ?? "",
                        id: students[index].id,
                        date: selectedDate!,
                      );
                    },
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}

class AttendanceTile extends StatefulWidget {
  final String name;
  final String roll;
  final String id;
  final DateTime date;

  const AttendanceTile({
    super.key,
    required this.name,
    required this.roll,
    required this.id,
    required this.date,
  });

  @override
  State<AttendanceTile> createState() => _AttendanceTileState();
}

class _AttendanceTileState extends State<AttendanceTile> {
  String status = ""; // A or P

  String get dateId =>
      "${widget.date.day}-${widget.date.month}-${widget.date.year}";

  String get docId => "${widget.id}_$dateId";

  Future<void> mark(String value) async {
    setState(() => status = value);

    await UserSession.yearColl('attendance').doc(docId).set({
      'studentId': widget.id,
      'date': Timestamp.fromDate(
        DateTime(widget.date.year, widget.date.month, widget.date.day),
      ),
      'dateId': dateId,
      'status': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final studentDoc = await UserSession.yearColl('students')
        .doc(widget.id)
        .get();

    if (studentDoc.exists) {
      final studentData = studentDoc.data() as Map<String, dynamic>;

      final studentEmail = studentData['email'] ?? "";

      if (studentEmail.toString().isNotEmpty) {
        await sendEmail(
          toEmail: studentEmail,
          subject: "Attendance Update",
          body: value == "P"
              ? """
  
  Dear ${widget.name},
  
  You have been marked PRESENT today.
  
  Date:
  ${widget.date.day}-${widget.date.month}-${widget.date.year}
  
  Thank You
  BVGM School
  
  """
              : """
  
  Dear ${widget.name},
  
  You have been marked ABSENT today.
  
  Date:
  ${widget.date.day}-${widget.date.month}-${widget.date.year}
  
  Please contact school if needed.
  
  Thank You
  BVGM School
  
  """,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadStatus();
  }

  Future<void> loadStatus() async {
    final doc = await UserSession.yearColl('attendance')
        .doc(docId)
        .get();

    if (doc.exists && mounted) {
      setState(() {
        status = (doc.data()?['status'] ?? "").toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            child: Icon(Icons.person),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Roll: ${widget.roll}"),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => mark("A"),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: status == "A" ? Colors.red : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Text(
                "A",
                style: TextStyle(
                  color: status == "A" ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => mark("P"),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: status == "P" ? Colors.green : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Text(
                "P",
                style: TextStyle(
                  color: status == "P" ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClassAllocationPage extends StatelessWidget {
  final TextEditingController classCtrl = TextEditingController();
  final TextEditingController sectionCtrl = TextEditingController();

  ClassAllocationPage({super.key});

  Future<void> saveClass() async {
    if (classCtrl.text.trim().isEmpty || sectionCtrl.text.trim().isEmpty)
      return;

    await UserSession.yearColl('classes').add({
      "className": classCtrl.text.trim(),
      "section": sectionCtrl.text.trim(),
    });

    classCtrl.clear();
    sectionCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f9ff),
      appBar: AppBar(
        title: const Text(
          "Class Allocation",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔷 FORM CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                  )
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: classCtrl,
                    decoration: InputDecoration(
                      labelText: "Class",
                      prefixIcon: const Icon(Icons.school),
                      filled: true,
                      fillColor: const Color(0xfff7faff),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sectionCtrl,
                    decoration: InputDecoration(
                      labelText: "Section",
                      prefixIcon: const Icon(Icons.group),
                      filled: true,
                      fillColor: const Color(0xfff7faff),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: saveClass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff6c8cff),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🔷 LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: UserSession.yearColl('classes')
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final data = snap.data!.docs;

                  if (data.isEmpty) {
                    return const Center(
                      child: Text("No Class Added"),
                    );
                  }

                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      final doc = data[i];
                      final d = doc.data() as Map<String, dynamic>;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child:
                              const Icon(Icons.class_, color: Colors.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Class ${d['className']} - ${d['section']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                bool? confirm = await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Delete Class"),
                                    content: const Text(
                                        "Kya aap is class ko delete karna chahte hain?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("No"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Yes"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await UserSession.yearColl('classes')
                                      .doc(doc.id)
                                      .delete();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Deleted Successfully"),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key});

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  Map<String, String> data = {};

  int getPresentCountOfMonth() {
    int count = 0;

    data.forEach((key, value) {
      final parts = key.split("-");
      if (parts.length == 3) {
        int d = int.parse(parts[0]);
        int m = int.parse(parts[1]);
        int y = int.parse(parts[2]);

        if (m == focusedDay.month && y == focusedDay.year && value == "P") {
          count++;
        }
      }
    });

    return count;
  }

  int getAbsentCountOfMonth() {
    int count = 0;

    data.forEach((key, value) {
      final parts = key.split("-");
      if (parts.length == 3) {
        int d = int.parse(parts[0]);
        int m = int.parse(parts[1]);
        int y = int.parse(parts[2]);

        if (m == focusedDay.month && y == focusedDay.year && value == "A") {
          count++;
        }
      }
    });

    return count;
  }

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String _dateKey(DateTime day) {
    return "${day.day}-${day.month}-${day.year}";
  }

  Future<void> loadData() async {
    final uid = UserSession.currentUserId;
    if (uid == null || uid.isEmpty) {
      setState(() => loading = false);
      return;
    }

    final snap = await UserSession.yearColl('attendance')
        .where('studentId', isEqualTo: uid)
        .get();

    final Map<String, String> temp = {};

    for (var d in snap.docs) {
      final map = d.data();

      String key = "";

      if (map['dateId'] != null && map['dateId'].toString().trim().isNotEmpty) {
        key = map['dateId'].toString();
      } else if (map['date'] is Timestamp) {
        final dt = (map['date'] as Timestamp).toDate();
        key = "${dt.day}-${dt.month}-${dt.year}";
      }

      if (key.isNotEmpty) {
        temp[key] = (map['status'] ?? "").toString();
      }
    }

    if (mounted) {
      setState(() {
        data = temp;
        loading = false;
      });
    }
  }

  String getStatus(DateTime day) {
    return data[_dateKey(day)] ?? "";
  }

  Color getDayColor(DateTime day) {
    final status = getStatus(day);
    if (status == "P") return Colors.green;
    if (status == "A") return Colors.red;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final selectedStatus = getStatus(selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Attendance",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 21,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: false,
        elevation: 6,
        shadowColor: const Color(0xFF064E3B).withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF064E3B), // Deep Emerald Forest Midnight
                Color(0xFF047857), // Deep Emerald Teal
                Color(0xFF059669), // Rich Vibrant Emerald
              ],
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: TableCalendar(
                focusedDay: focusedDay,
                firstDay: DateTime(2023),
                lastDay: DateTime(2030),
                selectedDayPredicate: (day) {
                  return isSameDay(selectedDay, day);
                },
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDay = selected;
                    focusedDay = focused;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final color = getDayColor(day);
                    final status = getStatus(day);

                    return Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${day.day}",
                          style: TextStyle(
                            color: status.isEmpty
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final color = getDayColor(day);

                    return Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color == Colors.transparent
                            ? Colors.blue.shade100
                            : color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue,
                          width: 1.4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "${day.day}",
                          style: TextStyle(
                            color: color == Colors.transparent
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final color = getDayColor(day);

                    return Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color == Colors.transparent
                            ? AppColors.primary
                            : color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black12,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "${day.day}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selected Date: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: selectedStatus == "P"
                              ? Colors.green
                              : selectedStatus == "A"
                              ? Colors.red
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        selectedStatus == "P"
                            ? "Present"
                            : selectedStatus == "A"
                            ? "Absent"
                            : "No attendance marked",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "${getPresentCountOfMonth()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Present",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(width: 30),
                      Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "${getAbsentCountOfMonth()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Absent",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceLegend extends StatelessWidget {
  final Color color;
  final String text;

  const _AttendanceLegend({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class AttendancePainter extends CustomPainter {
  final int present;
  final int absent;

  AttendancePainter({required this.present, required this.absent});

  @override
  void paint(Canvas canvas, Size size) {
    final totalDays = DateTime.now().day;
    final noData = totalDays - (present + absent);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final startAngle = -3.14 / 2;

    double presentAngle = (present / totalDays) * 6.28;
    double absentAngle = (absent / totalDays) * 6.28;
    double noDataAngle = (noData / totalDays) * 6.28;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // 🔵 Present (Solid Dark Blue)
    paint.color = const Color(0xff1e3a8a);
    canvas.drawArc(rect, startAngle, presentAngle, false, paint);
    // 🔴 Absent (Clear Light Red)
    paint.color = const Color(0xffff4d4f);
    canvas.drawArc(rect, startAngle + presentAngle, absentAngle, false, paint);

    // ⚪ No Data (Light Grey)
    paint.color = Colors.grey.shade300;
    canvas.drawArc(
      rect,
      startAngle + presentAngle + absentAngle,
      noDataAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Widget attendanceCard({
  required bool isPresent,
  required int selectedYear,
  required int selectedMonth,
}) {
  return StudentAttendanceStatCard(
    isPresent: isPresent,
    selectedYear: selectedYear,
    selectedMonth: selectedMonth,
  );
}

class StudentAttendanceStatCard extends StatefulWidget {
  final bool isPresent;
  final int selectedYear;
  final int selectedMonth;

  const StudentAttendanceStatCard({
    super.key,
    required this.isPresent,
    required this.selectedYear,
    required this.selectedMonth,
  });

  @override
  State<StudentAttendanceStatCard> createState() => _StudentAttendanceStatCardState();
}

class _StudentAttendanceStatCardState extends State<StudentAttendanceStatCard> {
  @override
  Widget build(BuildContext context) {
    final uid = UserSession.currentUserId ?? "";

    return StreamBuilder<QuerySnapshot>(
      stream: UserSession.yearColl('attendance')
          .where('studentId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        int present = 0;
        int absent = 0;

        if (snap.hasData) {
          for (var d in snap.data!.docs) {
            final data = d.data() as Map<String, dynamic>;
            DateTime date = (data['date'] as Timestamp).toDate();

            if (date.year == widget.selectedYear && date.month == widget.selectedMonth) {
              if (data['status'] == "P") present++;
              if (data['status'] == "A") absent++;
            }
          }
        }

        int totalDays = DateTime(widget.selectedYear, widget.selectedMonth + 1, 0).day;
        int count = widget.isPresent ? present : absent;
        double percent = (count / totalDays).clamp(0.0, 1.0);

        final Color mainColor = widget.isPresent ? const Color(0xFF059669) : const Color(0xFFE11D48);
        final Color cardBgTop = widget.isPresent ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2);
        final Color cardBgBottom = widget.isPresent ? const Color(0xFFD1FAE5) : const Color(0xFFFFE4E6);
        final Color borderColor = widget.isPresent ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3);

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [cardBgTop, cardBgBottom],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 🎨 TOP-LEFT CORNER ATTACHED BADGE
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.15),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: mainColor,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.isPresent ? "PRESENT" : "ABSENT",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: mainColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔄 ANIMATED ROTATING CIRCLE IN CENTER
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: AnimatedAttendanceCircle(
                        percent: percent,
                        isPresent: widget.isPresent,
                        count: count,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnimatedAttendanceCircle extends StatefulWidget {
  final double percent;
  final bool isPresent;
  final int count;

  const AnimatedAttendanceCircle({
    super.key,
    required this.percent,
    required this.isPresent,
    required this.count,
  });

  @override
  State<AnimatedAttendanceCircle> createState() => _AnimatedAttendanceCircleState();
}

class _AnimatedAttendanceCircleState extends State<AnimatedAttendanceCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = widget.isPresent ? const Color(0xFF059669) : const Color(0xFFE11D48);
    final Color glowColor = widget.isPresent ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(86, 86),
          painter: AttendanceCirclePainter(
            percent: widget.percent,
            rotationAngle: _rotationController.value * 2 * pi,
            mainColor: mainColor,
            glowColor: glowColor,
            isPresent: widget.isPresent,
          ),
          child: SizedBox(
            height: 86,
            width: 86,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${(widget.percent * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: mainColor,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: mainColor.withOpacity(0.35),
                          blurRadius: 6,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    "${widget.count} Days",
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: mainColor.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AttendanceCirclePainter extends CustomPainter {
  final double percent;
  final double rotationAngle;
  final Color mainColor;
  final Color glowColor;
  final bool isPresent;

  AttendanceCirclePainter({
    required this.percent,
    required this.rotationAngle,
    required this.mainColor,
    required this.glowColor,
    required this.isPresent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;

    // 1. Background Track Circle
    final trackPaint = Paint()
      ..color = mainColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Continuous Rotating Outer Sci-Fi Ring Arc (Hamesa ghumta rahe)
    final outerRingPaint = Paint()
      ..color = glowColor.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    // Rotating 90-degree outer laser arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 4),
      rotationAngle,
      pi / 2,
      false,
      outerRingPaint,
    );

    // Second counter-balancing dot arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 4),
      rotationAngle + pi,
      pi / 4,
      false,
      outerRingPaint..color = mainColor.withOpacity(0.45),
    );

    // 3. Main Progress Arc (Actual Attendance %)
    if (percent > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: [glowColor.withOpacity(0.6), mainColor],
          startAngle: -pi / 2,
          endAngle: -pi / 2 + (2 * pi * percent),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6.5;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * percent,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AttendanceCirclePainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.percent != percent;
  }
}

class FeesPage extends StatefulWidget {
  const FeesPage({super.key});

  @override
  State<FeesPage> createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  String _formatDate(dynamic timestamp) {
    DateTime date = (timestamp as Timestamp).toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  String? selectedStudentId;
  String? selectedClass;

  // 🔥 NEW DATE FILTER
  DateTime? fromDate;
  DateTime? toDate;
  String searchText = "";

  List<QueryDocumentSnapshot> allStudents = [];

  String selectedStudentName = "";
  int pageLimit = 50;
  int totalCount = 0;
  List<QueryDocumentSnapshot> currentFilteredDocs = [];

  // 🔥 PDF RECEIPT GENERATION
  Future<void> generateReceipt(Map<String, dynamic> data) async {
    try {
      final pdf = pw.Document();

      String dateFormatted = "";
      if (data['time'] is Timestamp) {
        DateTime t = (data['time'] as Timestamp).toDate();
        dateFormatted = "${t.day}/${t.month}/${t.year}";
      } else if (data['time'] != null) {
        dateFormatted = data['time'].toString().split(' ')[0];
      }

      final details = (data['details'] ?? []) as List;

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      "NATIONAL PUBLIC SCHOOL",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Center(child: pw.Text("Address - Raniganj")),
                  pw.SizedBox(height: 5),
                  pw.Center(
                    child: pw.Text(
                      "FEE RECEIPT",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.Text("Student Name : ${data['studentName'] ?? ""}"),
                  pw.Text("Class : ${data['class'] ?? data['classSection'] ?? "-"}"),
                  pw.Text("Month : ${data['month'] ?? ""}"),
                  pw.Text("Date : $dateFormatted"),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.Text(
                    "Amount Details",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  ...details.map((e) {
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(e['naration'] ?? ""),
                        pw.Text("Rs. ${e['amount']}"),
                      ],
                    );
                  }),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Total",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        "Rs. ${data['amount'] ?? 0}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Thank You"),
                      pw.Text("Rahul Sir"),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      // 🔥 OPEN PDF PREVIEW INSTANTLY
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text("Receipt Preview")),
              body: PdfPreview(
                build: (format) => pdfBytes,
              ),
            ),
          ),
        );
      }

      // Background Email Dispatch
      final String? studentId = data['studentId']?.toString();
      if (studentId != null && studentId.isNotEmpty) {
        UserSession.yearColl('students').doc(studentId).get().then((studentDoc) {
          if (studentDoc.exists) {
            final studentData = studentDoc.data() as Map<String, dynamic>;
            final studentEmail = studentData['email'] ?? "";

            if (studentEmail.toString().isNotEmpty) {
              final base64Pdf = base64Encode(pdfBytes);
              http.post(
                Uri.parse("https://api.brevo.com/v3/smtp/email"),
                headers: {
                  "accept": "application/json",
                  "api-key": "YOUR_BREVO_API_KEY",
                  "content-type": "application/json",
                },
                body: jsonEncode({
                  "sender": {
                    "name": "BVGM School",
                    "email": "infopushpraj343@gmail.com"
                  },
                  "to": [
                    {"email": studentEmail}
                  ],
                  "subject": "Fees Receipt PDF",
                  "htmlContent": "<html><body><h3>Fees Receipt</h3><p>Dear ${data['studentName']}, your receipt PDF is attached.</p></body></html>",
                  "attachment": [
                    {"content": base64Pdf, "name": "fees_receipt.pdf"}
                  ]
                }),
              ).catchError((e) => print("Brevo send error: $e"));
            }
          }
        }).catchError((e) => print("Fetch student error: $e"));
      }
    } catch (e) {
      print("generateReceipt Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Receipt error: $e")),
        );
      }
    }
  }

  Future<void> loadStudents() async {
    final snap = await UserSession.yearColl('students')
        .get();

    setState(() {
      allStudents = snap.docs;
    });
  }

  Future<void> loadTotalCount() async {
    final snap =
    await UserSession.yearColl('fees').count().get();

    setState(() {
      totalCount = snap.count ?? 0;
    });
  }

  Future<void> exportFeesExcel(List<QueryDocumentSnapshot> filteredDocs) async {
    try {
      if (filteredDocs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Export ke liye koi data nahi hai")),
        );
        return;
      }

      final excel = ex.Excel.createExcel();
      final sheet = excel['Fees Report'];

      sheet.appendRow([
        "Student Name",
        "Class",
        "Month",
        "Date",
        "Amount (Rs)",
        "Status",
        "Type",
        "Details"
      ]);

      for (var doc in filteredDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final String name = data['studentName'] ?? "No Name";
        final String cls = data['class'] ?? "-";
        final String month = data['month'] ?? "-";
        final String dateStr = data['time'] != null ? _formatDate(data['time']) : "-";
        final String amount = (data['amount'] ?? "0").toString();
        final String status = (data['status'] ?? "due").toString().toUpperCase();
        final String type = (data['type'] ?? "-").toString().toUpperCase();

        final details = (data['details'] ?? []) as List;
        final String narationStr = details.map((e) => "${e['naration'] ?? ''}: Rs.${e['amount'] ?? 0}").join("; ");

        sheet.appendRow([
          name,
          cls,
          month,
          dateStr,
          amount,
          status,
          type,
          narationStr,
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) return;

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final fileName = "fees_report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File("${dir.path}/$fileName");

      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Saved in Download/$fileName"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print("Export Excel Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export Excel Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    fromDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    toDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    loadTotalCount();
    loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    return CommonPage(
      title: "Fees",
      icon: Icons.account_balance_wallet_outlined,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffeff6ff),
                    foregroundColor: Colors.blue.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.blue.shade200, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddFeesSheet(isReceived: false),
                    );

                    if (result != null) {
                      setState(() {
                        selectedStudentId = result['studentId'];
                        selectedClass = result['class'];
                      });
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: const Text(
                    "+ Add",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xfff0fdf4),
                    foregroundColor: Colors.green.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.green.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AddFeesSheet(isReceived: true),
                    );

                    if (result != null) {
                      setState(() {
                        selectedStudentId = result['studentId'];
                        selectedClass = result['class'];
                      });
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: const Text(
                    "+ Received",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              String tempSearch = "";

              await showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setD) {
                      final filteredStudents = allStudents.where((e) {
                        final d = e.data() as Map<String, dynamic>;

                        final name = (d['name'] ?? "").toString().toLowerCase();

                        return name.contains(tempSearch.toLowerCase());
                      }).toList();

                      return Dialog(
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 24,
                        ),
                        backgroundColor: Colors.transparent,
                        child: Container(
                          width: double.maxFinite,
                          height: 600,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 46,
                                    width: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.search,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      "Select Student",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.red.shade700,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: "Search Student",
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (v) {
                                  setD(() {
                                    tempSearch = v;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredStudents.length,
                                  itemBuilder: (context, index) {
                                    final student = filteredStudents[index];

                                    final data =
                                    student.data() as Map<String, dynamic>;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.blue.shade100,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                            Colors.blue.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        onTap: () {
                                          setState(() {
                                            selectedStudentId = student.id;

                                            selectedStudentName =
                                                data['name'] ?? "";
                                          });

                                          Navigator.pop(context);
                                        },
                                        leading: CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.blue.shade100,
                                          child: Text(
                                            (data['name'] ?? "S")
                                                .toString()
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.blue.shade900,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          data['name'] ?? "",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding:
                                          const EdgeInsets.only(top: 4),
                                          child: Text(
                                            "Class: ${data['classSection'] ?? "-"}   |   Roll: ${data['rollNo'] ?? "-"}",
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              decoration: commonDecoration(),
              child: Row(
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedStudentName.isEmpty
                          ? "Search Student..."
                          : selectedStudentName,
                    ),
                  ),
                  if (selectedStudentId != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedStudentId = null;
                          selectedStudentName = "";
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 🔥 PILL BUTTONS (HORIZONTALLY SCROLLABLE TO PREVENT OVERFLOW)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 1. DATE RANGE PILL BUTTON (Left - White background, grey border)
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      final DateTimeRange? picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDateRange: (fromDate != null && toDate != null)
                            ? DateTimeRange(start: fromDate!, end: toDate!)
                            : DateTimeRange(
                                start: DateTime.now(),
                                end: DateTime.now(),
                              ),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        setState(() {
                          fromDate = picked.start;
                          toDate = picked.end;
                        });
                      }
                    },
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: (fromDate != null && toDate != null)
                            ? const Color(0xffeff6ff)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: (fromDate != null && toDate != null)
                              ? const Color(0xff0284c7)
                              : const Color(0xff94a3b8),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                            color: Color(0xff334155),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (fromDate != null && toDate != null)
                                ? "${fromDate!.day}/${fromDate!.month} - ${toDate!.day}/${toDate!.month}"
                                : "Date Range",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff1e293b),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 20,
                            color: Color(0xff334155),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (fromDate != null && toDate != null) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        setState(() {
                          fromDate = null;
                          toDate = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.grey),
                      ),
                    ),
                  ],

                  const SizedBox(width: 10),

                  // 2. EXPORT EXCEL PILL BUTTON (Right - Blue badge style matching reference image)
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      if (currentFilteredDocs.isNotEmpty) {
                        exportFeesExcel(currentFilteredDocs);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Export ke liye koi data nahi hai")),
                        );
                      }
                    },
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xffe0f2fe),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xff0284c7),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Left Solid Blue Badge
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xff0284c7),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(22),
                                bottomLeft: Radius.circular(22),
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.file_download_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Export Excel",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff0369a1),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 20,
                            color: Color(0xff0369a1),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 🔥 LIST WITH LIVE STREAM AND EXPORT EXCEL BUTTON
          StreamBuilder<QuerySnapshot>(
            stream: UserSession.yearColl('fees')
                .orderBy('time', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final allDocs = snap.data!.docs;

              final docs = allDocs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;

                if (selectedStudentId != null &&
                    selectedStudentId!.isNotEmpty) {
                  return d['studentId'] == selectedStudentId;
                }

                if (selectedClass != null && selectedClass!.isNotEmpty) {
                  return d['class'] == selectedClass;
                }

                return true;
              }).toList();

              // 🔥 SEARCH & DATE RANGE FILTER
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;

                // 🔍 SEARCH FILTER
                final name =
                (data['studentName'] ?? "").toString().toLowerCase();

                if (searchText.isNotEmpty && !name.contains(searchText)) {
                  return false;
                }

                // 📅 DATE RANGE FILTER
                if (fromDate != null && toDate != null) {
                  if (data['time'] != null) {
                    final DateTime t = (data['time'] as Timestamp).toDate();
                    final DateTime start = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
                    final DateTime end = DateTime(toDate!.year, toDate!.month, toDate!.day, 23, 59, 59);
                    if (t.isBefore(start) || t.isAfter(end)) {
                      return false;
                    }
                  }
                }

                return true;
              }).toList();

              currentFilteredDocs = filteredDocs;

              double totalAdd = 0;
              double totalReceived = 0;

              for (var doc in filteredDocs) {
                final d = doc.data() as Map<String, dynamic>;

                final amt =
                    double.tryParse(d['amount']?.toString() ?? "0") ?? 0;

                final status =
                (d['status'] ?? "").toString().toLowerCase().trim();

                if (status == "paid") {
                  totalReceived += amt;
                } else {
                  totalAdd += amt;
                }
              }

              final double balance = totalAdd - totalReceived;

              if (filteredDocs.isEmpty) {
                return const Center(child: Text("No Fees Data"));
              }

              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Text(
                        "Showing ${filteredDocs.length} of $totalCount entries",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  /// 🔥 TOTAL CARD (Soft Light Green Background)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xfff0fdf4), // 🔥 Soft Light Green
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xffbbf7d0), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Total Add",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "₹${totalAdd.toStringAsFixed(1)}",
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "Received",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "₹${totalReceived.toStringAsFixed(1)}",
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 16, color: Color(0xffcbd5e1)),
                        Column(
                          children: [
                            const Text(
                              "Balance Amount",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "₹${balance.toStringAsFixed(1)}",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// 🔽 LIST ITEMS (Comfortable Height, Inset Bottom Border)
                  Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: filteredDocs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final doc = entry.value;
                        final data = doc.data() as Map<String, dynamic>;
                        final status = (data['status'] ?? "").toString().toLowerCase().trim();
                        final isPaid = status == "paid";
                        final isLast = index == filteredDocs.length - 1;

                        return Column(
                          children: [
                            InkWell(
                              onTap: () => generateReceipt(data),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['studentName'] ?? "No Name",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.text,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Text(
                                                "Month: ${data['month'] ?? '-'}",
                                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                              ),
                                              if (data['time'] != null) ...[
                                                const Text("  •  ", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                                Text(
                                                  "Date: ${_formatDate(data['time'])}",
                                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "₹${data['amount']}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (_) => AddFeesSheet(
                                            isReceived: isPaid,
                                            docId: doc.id,
                                            oldData: data,
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          color: Colors.blue.shade600,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        bool? confirm = await showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              title: const Text("Confirm Delete"),
                                              content: const Text("Delete karna hai?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text("Delete", style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (confirm == true) {
                                          await UserSession.yearColl('fees').doc(doc.id).delete();
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.red.shade600,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                thickness: 0.8,
                                indent: 16,
                                endIndent: 16,
                                color: Colors.grey.shade300,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        pageLimit += 50;
                      });
                    },
                    child: Text("Load More"),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class AddFeesSheet extends StatefulWidget {
  final bool isReceived;

  // 🔥 EDIT SUPPORT
  final String? docId;
  final Map<String, dynamic>? oldData;

  const AddFeesSheet({
    super.key,
    required this.isReceived,
    this.docId,
    this.oldData,
  });

  @override
  State<AddFeesSheet> createState() => _AddFeesSheetState();
}

class _AddFeesSheetState extends State<AddFeesSheet> {
  String? selectedStudentId;
  String? selectedStudentName;
  String? selectedMonth;
  String? selectedClass;

  List<QueryDocumentSnapshot> students = [];
  List<String> classList = [];

  List<Map<String, TextEditingController>> rows = [
    {
      "naration": TextEditingController(),
      "amount": TextEditingController(),
    }
  ];

  @override
  void initState() {
    super.initState();

    // 🔥 AUTO FILL (EDIT MODE)
    if (widget.oldData != null) {
      selectedStudentId = widget.oldData!['studentId'];
      selectedStudentName = widget.oldData!['studentName'];
      selectedMonth = widget.oldData!['month'];
      selectedClass = widget.oldData!['class'];

      if (widget.oldData!['details'] != null) {
        rows = (widget.oldData!['details'] as List).map((e) {
          return {
            "naration": TextEditingController(text: e['naration']),
            "amount": TextEditingController(text: e['amount'].toString()),
          };
        }).toList();
      }
    }

    loadStudents();
    loadClasses();
  }

  int getTotalAmount() {
    int total = 0;
    for (var row in rows) {
      total += int.tryParse(row["amount"]!.text) ?? 0;
    }
    return total;
  }

  Future<void> loadStudents() async {
    final snap = await UserSession.yearColl('students')
        .get();

    setState(() {
      students = snap.docs;
    });
  }

  Future<void> loadClasses() async {
    final snap = await UserSession.yearColl('classes').get();

    List<String> temp = [];

    for (var doc in snap.docs) {
      final d = doc.data();
      String c = (d['className'] ?? "").toString();
      String s = (d['section'] ?? "").toString();
      temp.add("$c-$s");
    }

    setState(() {
      classList = temp.toSet().toList();
    });
  }

  bool isSaving = false;

  Future<void> saveFees() async {
    if (isSaving) return;

    if (selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kripya Month select karein")),
      );
      return;
    }

    if (selectedClass == null && selectedStudentId == null && widget.docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kripya Class ya Student select karein")),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      int amount = getTotalAmount();

      List<Map<String, dynamic>> detailsList = rows.map((r) {
        return {
          "naration": r["naration"]!.text.trim(),
          "amount": int.tryParse(r["amount"]!.text.trim()) ?? 0,
        };
      }).toList();

      // 🔥 UPDATE MODE
      if (widget.docId != null) {
        await UserSession.yearColl('fees').doc(widget.docId).update({
          "month": selectedMonth,
          "amount": amount,
          "details": detailsList,
          "class": selectedClass,
          "status": widget.isReceived ? "paid" : "due",
          "type": widget.isReceived ? "receive" : "add",
        });

        if (mounted) Navigator.pop(context, true);
        return;
      }

      // 🔥 CLASS BATCH MODE (FAST PARALLEL WRITE IN ONE BATCH)
      if (selectedClass != null && selectedClass!.isNotEmpty) {
        final snap = await UserSession.yearColl('students').get();
        final WriteBatch batch = FirebaseFirestore.instance.batch();

        for (var doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>;

          if ((data['classSection'] ?? "") == selectedClass) {
            final newFeeDoc = UserSession.yearColl('fees').doc();
            batch.set(newFeeDoc, {
              "studentId": doc.id,
              "studentName": data['name'],
              "class": selectedClass,
              "month": selectedMonth,
              "amount": amount,
              "details": detailsList,
              "status": widget.isReceived ? "paid" : "due",
              "type": widget.isReceived ? "receive" : "add",
              "time": FieldValue.serverTimestamp(),
            });

            final newNoticeDoc = UserSession.yearColl('notices').doc();
            batch.set(newNoticeDoc, {
              'title': widget.isReceived ? "Fees Received" : "New Fees Added",
              'message': widget.isReceived
                  ? "Your payment of ₹$amount has been received.\nMonth : $selectedMonth\nTotal : ₹$amount"
                  : "Your fees of ₹$amount has been added.\nMonth : $selectedMonth\nTotal : ₹$amount",
              'studentId': doc.id,
              'role': 'private',
              'seenBy': [],
              'time': FieldValue.serverTimestamp(),
            });
          }
        }

        await batch.commit(); // 🔥 ALL FEES + NOTICES CREATED INSTANTLY IN 1 CALL!
      }
      // 🔥 SINGLE STUDENT MODE
      else if (selectedStudentId != null) {
        final newFeeDoc = UserSession.yearColl('fees').doc();
        final newNoticeDoc = UserSession.yearColl('notices').doc();

        final WriteBatch batch = FirebaseFirestore.instance.batch();

        batch.set(newFeeDoc, {
          "studentId": selectedStudentId,
          "studentName": selectedStudentName,
          "class": selectedClass,
          "month": selectedMonth,
          "amount": amount,
          "details": detailsList,
          "status": widget.isReceived ? "paid" : "due",
          "type": widget.isReceived ? "receive" : "add",
          "time": FieldValue.serverTimestamp(),
        });

        batch.set(newNoticeDoc, {
          'title': widget.isReceived ? "Fees Received" : "New Fees Added",
          'message': widget.isReceived
              ? "Your payment of ₹$amount has been received.\nMonth : $selectedMonth\nTotal : ₹$amount"
              : "Your fees of ₹$amount has been added.\nMonth : $selectedMonth\nTotal : ₹$amount",
          'studentId': selectedStudentId ?? "",
          'role': 'private',
          'seenBy': [],
          'time': FieldValue.serverTimestamp(),
        });

        await batch.commit(); // 🔥 INSTANT BATCH COMMIT

        // Background email dispatch (does not delay dialog closing)
        UserSession.yearColl('students').doc(selectedStudentId).get().then((studentDoc) {
          if (studentDoc.exists) {
            final studentData = studentDoc.data() as Map<String, dynamic>;
            final studentEmail = studentData['email'] ?? "";
            if (studentEmail.toString().isNotEmpty) {
              sendEmail(
                toEmail: studentEmail,
                subject: widget.isReceived ? "Fees Payment Received" : "New Fees Added",
                body: widget.isReceived
                    ? "Dear $selectedStudentName,\n\nYour fees payment has been received successfully.\n\nMonth: $selectedMonth\nAmount: ₹$amount\n\nThank You\nBVGM School"
                    : "Dear $selectedStudentName,\n\nNew fees has been added to your account.\n\nMonth: $selectedMonth\nAmount: ₹$amount\n\nPlease pay on time.\n\nThank You\nBVGM School",
              );
            }
          }
        });
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isReceived ? "Fee Received saved successfully!" : "Fee entry added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Save fee error: $e");
      if (mounted) {
        setState(() {
          isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving fee: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            Text(
              widget.docId != null
                  ? "Edit Fees"
                  : (widget.isReceived ? "Receive Fees" : "Add Fees"),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 20),

            // 🔥 CLASS वापस
            buildField(
              icon: Icons.school,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedClass,
                  hint: const Text("Select Class"),
                  items: classList
                      .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedClass = val;
                      selectedStudentId = null;
                    });
                  },
                ),
              ),
            ),

            // 🔥 STUDENT
            buildField(
              icon: Icons.person,
              child: GestureDetector(
                onTap: () async {
                  String search = "";

                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setStateModal) {
                          List<QueryDocumentSnapshot> filtered =
                          students.where((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            final name =
                            (d['name'] ?? "").toString().toLowerCase();
                            return name.contains(search.toLowerCase());
                          }).toList();

                          return Container(
                            height: MediaQuery.of(context).size.height * 0.75,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(25)),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // 🔘 DRAG HANDLE
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // 🔥 TITLE
                                const Text(
                                  "Select Student",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 15),

                                // 🔍 SEARCH BOX
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      hintText: "Search student...",
                                      prefixIcon: Icon(Icons.search),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (val) {
                                      setStateModal(() {
                                        search = val;
                                      });
                                    },
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // 📋 LIST
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: filtered.length,
                                    itemBuilder: (context, i) {
                                      final doc = filtered[i];
                                      final d =
                                      doc.data() as Map<String, dynamic>;
                                      final name = d['name'] ?? "";
                                      final className =
                                          d['classSection'] ?? "-";
                                      final roll = d['rollNo'] ?? "-";

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedStudentId = doc.id;
                                            selectedStudentName = name;
                                            selectedClass = null;
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          margin:
                                          const EdgeInsets.only(bottom: 10),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                            BorderRadius.circular(15),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.shade200,
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              )
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              // 🔵 AVATAR
                                              CircleAvatar(
                                                radius: 22,
                                                backgroundColor:
                                                Colors.blue.shade100,
                                                child: Text(
                                                  name.toString().isNotEmpty
                                                      ? name[0].toUpperCase()
                                                      : "?",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 12),

                                              // 🧑 NAME
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    // 🔥 NAME
                                                    Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                        FontWeight.w700,
                                                        fontSize: 15,
                                                      ),
                                                    ),

                                                    const SizedBox(height: 2),

                                                    // 🔥 CLASS + ROLL
                                                    Text(
                                                      "Class: $className   |   Roll: $roll",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 14)
                                            ],
                                          ),
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
                    },
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedStudentName ?? "Select Student",
                      style: TextStyle(
                        color: selectedStudentName == null
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),

            // 🔥 MONTH
            buildField(
              icon: Icons.calendar_month,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedMonth,
                  hint: const Text("Select Month"),
                  items: [
                    "Jan",
                    "Feb",
                    "Mar",
                    "Apr",
                    "May",
                    "Jun",
                    "Jul",
                    "Aug",
                    "Sep",
                    "Oct",
                    "Nov",
                    "Dec"
                  ].map((m) {
                    return DropdownMenuItem(value: m, child: Text(m));
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedMonth = v;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            ...rows.map((row) {
              return Row(
                children: [
                  Expanded(
                    child: buildField(
                      icon: Icons.notes,
                      child: TextField(
                        controller: row["naration"],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Naration",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildField(
                      icon: Icons.currency_rupee,
                      child: TextField(
                        controller: row["amount"],
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Amount",
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),

            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
                onPressed: () {
                  setState(() {
                    rows.add({
                      "naration": TextEditingController(),
                      "amount": TextEditingController(),
                    });
                  });
                },
              ),
            ),

            buildField(
              icon: Icons.calculate,
              child: Text(
                "Total: ₹${getTotalAmount()}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: isSaving ? null : saveFees,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: isSaving
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Center(
                  child: isSaving
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Saving...",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          widget.docId != null
                              ? "Update"
                              : (widget.isReceived ? "Received Save" : "Add Save"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> generateFeeReceiptPdf(BuildContext context, Map<String, dynamic> data) async {
  try {
    final pdf = pw.Document();

    String dateFormatted = "";
    if (data['time'] is Timestamp) {
      DateTime t = (data['time'] as Timestamp).toDate();
      dateFormatted = "${t.day}/${t.month}/${t.year}";
    } else if (data['time'] != null) {
      dateFormatted = data['time'].toString().split(' ')[0];
    }

    final details = (data['details'] ?? []) as List;
    final studentName = data['studentName'] ?? UserSession.currentName ?? "Student";
    final className = data['class'] ?? data['classSection'] ?? "-";
    final month = data['month'] ?? "-";

    pdf.addPage(
      pw.Page(
        build: (pw.Context pageContext) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    "NATIONAL PUBLIC SCHOOL",
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Center(child: pw.Text("Address - Raniganj")),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    "FEE RECEIPT",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Text("Student Name : $studentName"),
                pw.Text("Class : $className"),
                pw.Text("Month : $month"),
                pw.Text("Date : $dateFormatted"),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Text(
                  "Amount Details",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 5),
                if (details.isEmpty)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(month),
                      pw.Text("Rs. ${data['amount'] ?? 0}"),
                    ],
                  )
                else
                  ...details.map((e) {
                    final nar = (e['naration'] == null || e['naration'].toString().isEmpty)
                        ? month
                        : e['naration'].toString();
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(nar),
                        pw.Text("Rs. ${e['amount']}"),
                      ],
                    );
                  }),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Total",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      "Rs. ${data['amount'] ?? 0}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Thank You"),
                    pw.Text("Rahul Sir"),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Receipt Preview")),
          body: PdfPreview(
            build: (format) => pdfBytes,
          ),
        ),
      ),
    );
  } catch (e) {
    print("generateFeeReceiptPdf Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Receipt error: $e")),
    );
  }
}

class StudentFeesPage extends StatelessWidget {
  const StudentFeesPage({super.key});

  String formatTime(Timestamp? t) {
    if (t == null) return "";

    final dt = t.toDate();

    String date = "${dt.day}/${dt.month}/${dt.year}";

    int hour = dt.hour;
    String ampm = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    if (hour == 0) hour = 12;

    String min = dt.minute.toString().padLeft(2, '0');

    return "$date  $hour:$min $ampm";
  }

  @override
  Widget build(BuildContext context) {
    final uid = UserSession.currentUserId ?? "";

    final stream = UserSession.yearColl('fees')
        .where('studentId', isEqualTo: uid)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          double totalAdd = 0;
          double totalReceived = 0;

          for (var doc in docs) {
            final d = doc.data() as Map<String, dynamic>;
            final amt = double.tryParse(d['amount']?.toString() ?? "0") ?? 0;
            final status = (d['status'] ?? "").toString().toLowerCase().trim();
            final type = (d['type'] ?? "").toString().toLowerCase().trim();

            if (type == "add") {
              totalAdd += amt;
            } else if (type == "received" || type == "receive" || status == "paid") {
              totalReceived += amt;
            } else {
              totalAdd += amt;
            }
          }

          final balance = totalAdd - totalReceived;

          List sortedDocs = List.from(docs);
          sortedDocs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['time'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['time'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return bTime.toDate().compareTo(aTime.toDate());
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                // 🔷 TOP TEAL-EMERALD HEADER BANNER & FLOATING DASHBOARD
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Top Gradient Header Cover
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF047857), Color(0xFF10B981), Color(0xFF34D399)],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (ModalRoute.of(context)?.canPop ?? false)
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  const Text(
                                    "My Fees Statement",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // FLOATING DASHBOARD CARD (LIGHT GREEN BACKGROUND)
                    Padding(
                      padding: const EdgeInsets.only(top: 90, left: 16, right: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // TOP ROW: TOTAL ADD & RECEIVED
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.add_card_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Total Added",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        Text(
                                          "₹${totalAdd.toStringAsFixed(1)}",
                                          style: const TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF16A34A),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Received",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        Text(
                                          "₹${totalReceived.toStringAsFixed(1)}",
                                          style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Divider(height: 1, color: Color(0xFFA7F3D0)),
                            ),

                            // BOTTOM CENTER BALANCE CARD
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Net Remaining Balance",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "₹${balance.toStringAsFixed(1)}",
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0284C7),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(24),
                                      bottomLeft: Radius.circular(24),
                                      topRight: Radius.circular(6),
                                      bottomRight: Radius.circular(6),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withOpacity(0.35),
                                        blurRadius: 10,
                                        offset: const Offset(-2, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.arrow_back_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        balance <= 0 ? "Paid" : "Due Payment",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 🔷 TRANSACTION HISTORY SECTION HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Row(
                        children: [
                          Icon(Icons.history_toggle_off_rounded, color: Color(0xFF0F172A), size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Transaction History",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${sortedDocs.length} Records",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 🔷 FULL WIDTH CONTAINER LIST (NO TOP BORDER, INSET DIVIDERS)
                if (sortedDocs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    color: Colors.white,
                    child: const Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 10),
                        Text(
                          "No Fee Transactions Found",
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Column(
                      children: List.generate(sortedDocs.length, (index) {
                        final doc = sortedDocs[index];
                        final d = doc.data() as Map<String, dynamic>;
                        final time = d['time'] as Timestamp?;
                        final status = (d['status'] ?? "").toString().toLowerCase().trim();
                        final isLast = index == sortedDocs.length - 1;

                        return Column(
                          children: [
                            InkWell(
                              onTap: () => generateFeeReceiptPdf(context, d),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    // Status Colored Icon Box
                                    Container(
                                      height: 44,
                                      width: 44,
                                      decoration: BoxDecoration(
                                        color: status == "paid"
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        status == "paid"
                                            ? Icons.check_circle_rounded
                                            : Icons.pending_actions_rounded,
                                        color: status == "paid"
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFDC2626),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Month & Date
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            d['month'] ?? "Fee Record",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  formatTime(time),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Amount & Status Badge
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "₹${d['amount'] ?? 0}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: status == "paid"
                                                ? const Color(0xFFDCFCE7)
                                                : const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: status == "paid"
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFFB91C1C),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast)
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: Color(0xFFF1F5F9),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget buildField({
  required IconData icon,
  required Widget child,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xffdbe5ff)),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 6),
        )
      ],
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    ),
  );
}

class AdminListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text("Admins"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: UserSession.yearColl('admins')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final user = data[index];
              final u = user.data() as Map<String, dynamic>;

              return Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Text("${index + 1}.",
                        style: TextStyle(fontWeight: FontWeight.bold)),

                    SizedBox(width: 10),

                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (u['photo'] != null && u['photo'] != "")
                          ? NetworkImage(u['photo'])
                          : null,
                      child: (u['photo'] == null || u['photo'] == "")
                          ? Icon(Icons.person)
                          : null,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u['name'] ?? "No Name",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            u['email'] ?? "-",
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    // EDIT
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddUserDialog(
                            docId: user.id,
                            oldData: u,
                          ),
                        );
                      },
                    ),

                    // DELETE
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        bool confirm = await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("Confirm Delete"),
                            content: Text("Admin delete karna hai?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("Delete"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await UserSession.yearColl('admins')
                              .doc(user.id)
                              .delete();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ExamsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Exams",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Examination Schedules & Results",
              style: TextStyle(
                color: Color(0xFFBFDBFE),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: UserSession.currentRole == 'admin'
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddExamPage()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F9FF), Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          ),
        ),
        child: StreamBuilder(
        stream: UserSession.yearColl('exams')
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No Exams Found",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      final role = UserSession.currentRole;

                      if (role == "admin") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddExamPage(
                              docId: docId,
                              oldData: data,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResultViewPage(
                              examData: data,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 14),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          // 🎓 ICON BOX
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.school, color: Colors.blue),
                          ),

                          SizedBox(width: 12),

                          // 📄 TEXT PART
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['examName'] ?? "No Name",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Code: ${data['examCode'] ?? ""}",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 🗑 DELETE (ONLY FOR ADMIN)
                          if (UserSession.currentRole == 'admin')
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text("Delete Exam"),
                                      content:
                                      Text("Pura exam delete karna hai?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await UserSession.yearColl('exams')
                                                .doc(docId)
                                                .delete();

                                            Navigator.pop(context);
                                          },
                                          child: Text("Delete",
                                              style:
                                              TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),

                          // ➡️ ARROW
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    ),
  );
}
}

class AddExamPage extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? oldData;

  AddExamPage({this.docId, this.oldData});

  @override
  State<AddExamPage> createState() => _AddExamPageState();
}

class _AddExamPageState extends State<AddExamPage> {
  final examNameCtrl = TextEditingController();
  final examCodeCtrl = TextEditingController();
  final fullMarksCtrl = TextEditingController();

  TextEditingController searchCtrl = TextEditingController();
  String searchText = "";

  List<QueryDocumentSnapshot> students = [];
  List<Map<String, dynamic>> studentBlocks = [];
  List<Map<String, dynamic>> subjectTemplate = [];

  List<String> allClasses = [];
  List<String> selectedClasses = [];

  @override
  void initState() {
    super.initState();
    loadStudents();
    loadClasses();

    if (widget.oldData != null) {
      examNameCtrl.text = widget.oldData!['examName'] ?? "";
      examCodeCtrl.text = widget.oldData!['examCode'] ?? "";
      fullMarksCtrl.text = (widget.oldData!['fullMarks'] ?? "").toString();
      selectedClasses = List<String>.from(widget.oldData!['classes'] ?? []);

      final oldStudents = widget.oldData!['students'] ?? [];

      for (var s in oldStudents) {
        List subs = [];

        (s['marks'] ?? {}).forEach((k, v) {
          subs.add({
            "name": TextEditingController(text: k),
            "marks": TextEditingController(text: v.toString())
          });
        });

        studentBlocks.add({
          "studentId": s['studentId'],
          "studentName": s['studentName'],
          "subjects": subs
        });
      }

      if (studentBlocks.isNotEmpty) {
        subjectTemplate =
            studentBlocks[0]["subjects"].map<Map<String, dynamic>>((e) {
              return {
                "name": TextEditingController(text: e["name"].text),
                "marks": TextEditingController(),
              };
            }).toList();
      }
    } else {
      addStudent();
    }
  }

  @override
  void dispose() {
    examNameCtrl.dispose();
    examCodeCtrl.dispose();
    fullMarksCtrl.dispose();
    searchCtrl.dispose();

    for (var block in studentBlocks) {
      for (var sub in block["subjects"]) {
        (sub["name"] as TextEditingController).dispose();
        (sub["marks"] as TextEditingController).dispose();
      }
    }

    for (var sub in subjectTemplate) {
      (sub["name"] as TextEditingController).dispose();
      (sub["marks"] as TextEditingController).dispose();
    }

    super.dispose();
  }

  Future<void> loadClasses() async {
    final snap = await UserSession.yearColl('classes').get();

    setState(() {
      allClasses = snap.docs.map((e) {
        final d = e.data();
        return "${d['className']}-${d['section']}";
      }).toList();
    });
  }

  void openClassDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.class_outlined, color: Color(0xFF0B3C91)),
                  SizedBox(width: 8),
                  Text("Select Classes", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: allClasses.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("Class list empty hai"),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: allClasses.map((cls) {
                          final isChecked = selectedClasses.contains(cls);
                          return CheckboxListTile(
                            activeColor: const Color(0xFF0B3C91),
                            value: isChecked,
                            title: Text(
                              cls,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            onChanged: (v) {
                              setStateDialog(() {
                                if (v == true) {
                                  selectedClasses.add(cls);
                                } else {
                                  selectedClasses.remove(cls);
                                }
                              });
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3C91),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> loadStudents() async {
    final snap = await UserSession.yearColl('students')
        .get();

    setState(() {
      students = snap.docs;
    });
  }

  void updateTemplateFromBlock(int fromIndex) {
    subjectTemplate = studentBlocks[fromIndex]["subjects"]
        .map<Map<String, dynamic>>((e) => {
      "name": TextEditingController(text: e["name"].text),
      "marks": TextEditingController(),
    })
        .toList();
  }

  void syncSubjectsToAll(int fromIndex) {
    updateTemplateFromBlock(fromIndex);

    for (int i = 0; i < studentBlocks.length; i++) {
      if (i == fromIndex) continue;

      final oldSubjects = studentBlocks[i]["subjects"] as List;
      List<Map<String, dynamic>> newSubjects = [];

      for (int j = 0; j < subjectTemplate.length; j++) {
        String oldMarks = "";
        if (j < oldSubjects.length) {
          oldMarks = oldSubjects[j]["marks"].text;
        }

        newSubjects.add({
          "name": TextEditingController(text: subjectTemplate[j]["name"].text),
          "marks": TextEditingController(text: oldMarks),
        });
      }

      studentBlocks[i]["subjects"] = newSubjects;
    }
  }

  void addStudent() {
    setState(() {
      studentBlocks.add({
        "studentId": null,
        "studentName": null,
        "subjects": subjectTemplate.isNotEmpty
            ? subjectTemplate
            .map((e) => {
          "name": TextEditingController(text: e["name"].text),
          "marks": TextEditingController()
        })
            .toList()
            : []
      });
    });
  }

  void removeStudent(int i) {
    if (studentBlocks.length == 1) return;
    setState(() {
      studentBlocks.removeAt(i);

      if (studentBlocks.isNotEmpty) {
        updateTemplateFromBlock(0);
      } else {
        subjectTemplate = [];
      }
    });
  }

  void addSubject(int i) {
    setState(() {
      final newSub = {
        "name": TextEditingController(),
        "marks": TextEditingController()
      };

      studentBlocks[i]["subjects"].add(newSub);
      syncSubjectsToAll(i);
    });
  }

  void removeSubject(int i, int j) {
    if (studentBlocks[i]["subjects"].length == 1) return;

    setState(() {
      studentBlocks[i]["subjects"].removeAt(j);
      syncSubjectsToAll(i);
    });
  }

  Map<String, dynamic> calculateResult(List subs) {
    int total = 0;

    for (var sub in subs) {
      total += int.tryParse(sub["marks"].text) ?? 0;
    }

    int full = int.tryParse(fullMarksCtrl.text) ?? 0;
    double percent = full > 0 ? (total / full) * 100 : 0;

    return {"total": total, "percent": percent};
  }

  Future<void> saveExam() async {
    List finalStudents = [];

    for (var s in studentBlocks) {
      Map<String, int> marks = {};
      int total = 0;

      for (var sub in s["subjects"]) {
        String name = sub["name"].text;
        int val = int.tryParse(sub["marks"].text) ?? 0;

        if (name.isNotEmpty) {
          marks[name] = val;
          total += val;
        }
      }

      int full = int.tryParse(fullMarksCtrl.text) ?? 0;
      double percent = full > 0 ? (total / full) * 100 : 0;

      finalStudents.add({
        "studentId": s["studentId"],
        "studentName": s["studentName"],
        "marks": marks,
        "total": total,
        "percent": percent,
      });
    }

    finalStudents.sort((a, b) => b["percent"].compareTo(a["percent"]));

    final data = {
      "examName": examNameCtrl.text,
      "examCode": examCodeCtrl.text,
      "fullMarks": int.tryParse(fullMarksCtrl.text) ?? 0,
      "students": finalStudents,
      "classes": selectedClasses,
      "time": FieldValue.serverTimestamp(),
    };

    if (widget.docId != null) {
      await UserSession.yearColl('exams')
          .doc(widget.docId)
          .update(data);
    } else {
      await UserSession.yearColl('exams').add(data);
    }

    Navigator.pop(context);
  }

  Future<void> generateStudentPdf(Map student) async {
    final pdf = pw.Document();

    final marks = Map<String, dynamic>.from(student['marks'] ?? {});
    final total = student['total'] ?? 0;
    final percent = student['percent'] ?? 0;

    String studentName = (student['studentName'] ?? student['name'] ?? "").toString();
    String father = (student['father'] ?? student['fatherName'] ?? "").toString();
    String mother = (student['mother'] ?? student['motherName'] ?? "").toString();
    String rollNo = (student['rollNo'] ?? "").toString();
    String studentClass = (student['class'] ?? student['classSection'] ?? "").toString();
    String dob = (student['dob'] ?? student['dateOfBirth'] ?? "").toString();
    String admNo = (student['admNo'] ?? student['admissionNo'] ?? "").toString();
    String photoStr = (student['photo'] ?? student['photoUrl'] ?? student['imageUrl'] ?? "").toString();

    final studentId = (student['studentId'] ?? student['id'] ?? UserSession.currentUserId ?? "").toString();

    // 🔥 SMART LOOKUP: If key details are missing, fetch complete student document from Firestore!
    if (father.isEmpty || mother.isEmpty || rollNo.isEmpty || studentClass.isEmpty || dob.isEmpty || photoStr.isEmpty) {
      try {
        DocumentSnapshot? snap;
        if (studentId.isNotEmpty) {
          snap = await UserSession.yearColl('students').doc(studentId).get();
        }
        if ((snap == null || !snap.exists) && studentName.isNotEmpty) {
          final querySnap = await UserSession.yearColl('students')
              .where('name', isEqualTo: studentName)
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            snap = querySnap.docs.first;
          }
        }
        if ((snap == null || !snap.exists) && rollNo.isNotEmpty) {
          final querySnap = await UserSession.yearColl('students')
              .where('rollNo', isEqualTo: rollNo)
              .limit(1)
              .get();
          if (querySnap.docs.isNotEmpty) {
            snap = querySnap.docs.first;
          }
        }

        if (snap != null && snap.exists && snap.data() != null) {
          final sData = snap.data() as Map<String, dynamic>;
          if (studentName.isEmpty) studentName = (sData['name'] ?? sData['studentName'] ?? "").toString();
          if (father.isEmpty) father = (sData['fatherName'] ?? sData['father'] ?? "").toString();
          if (mother.isEmpty) mother = (sData['motherName'] ?? sData['mother'] ?? "").toString();
          if (rollNo.isEmpty) rollNo = (sData['rollNo'] ?? "").toString();
          if (studentClass.isEmpty) studentClass = (sData['classSection'] ?? sData['class'] ?? "").toString();
          if (dob.isEmpty) dob = (sData['dob'] ?? sData['dateOfBirth'] ?? "").toString();
          if (admNo.isEmpty) admNo = (sData['admNo'] ?? sData['admissionNo'] ?? "").toString();
          if (photoStr.isEmpty) photoStr = (sData['photo'] ?? sData['photoUrl'] ?? sData['imageUrl'] ?? "").toString();
        }
      } catch (e) {
        print("Firestore Student Lookup Error for PDF: $e");
      }
    }

    // 🔥 STUDENT PHOTO LOAD
    dynamic studentImage;
    if (photoStr.isNotEmpty) {
      try {
        if (photoStr.startsWith('data:image')) {
          final base64Str = photoStr.split(',').last;
          final bytes = base64Decode(base64Str);
          studentImage = pw.MemoryImage(bytes);
        } else if (photoStr.startsWith('http://') || photoStr.startsWith('https://')) {
          studentImage = await networkImage(photoStr);
        }
      } catch (e) {
        print("PDF Student Image Load Error: $e");
        studentImage = null;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 1),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 🔷 SCHOOL HEADER
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    children: [
                      // SCHOOL NAME
                      pw.Text(
                        "BAL VIKASH GYAN MANDIR",
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),

                      pw.SizedBox(height: 10),

                      // ADDRESS
                      pw.Text(
                        "Raniganj, Imamganj, Gaya (Bihar), Near:Gaytri Mandir 824210",
                        style: const pw.TextStyle(
                          fontSize: 10,
                        ),
                      ),

                      pw.SizedBox(height: 6),

                      // SESSION
                      pw.Text(
                        "Student Marks Card",
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),

                pw.Divider(
                  thickness: 1,
                ),

                pw.SizedBox(height: 14),

                // 🔷 STUDENT INFO SECTION
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // 🔥 LEFT + RIGHT DETAILS
                    pw.Expanded(
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // LEFT
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                infoRow("Name", studentName.isNotEmpty ? studentName : "-"),
                                pw.SizedBox(height: 10),
                                infoRow("Father", father.isNotEmpty ? father : "-"),
                                pw.SizedBox(height: 10),
                                infoRow("Mother", mother.isNotEmpty ? mother : "-"),
                                pw.SizedBox(height: 10),
                                infoRow("DOB", dob.isNotEmpty ? dob : "-"),
                              ],
                            ),
                          ),

                          pw.SizedBox(width: 35),

                          // RIGHT
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                infoRow("Roll No", rollNo.isNotEmpty ? rollNo : "-"),
                                pw.SizedBox(height: 10),
                                infoRow("Adm No", admNo.isNotEmpty ? admNo : "-"),
                                pw.SizedBox(height: 10),
                                infoRow("Class", studentClass.isNotEmpty ? studentClass : "-"),
                                pw.SizedBox(height: 10),
                                infoRow("PEN No", "-"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(width: 20),

                    // 🔥 PHOTO
                    pw.Container(
                      height: 110,
                      width: 90,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.blueGrey,
                          width: 1.5,
                        ),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      padding: const pw.EdgeInsets.all(4),
                      child: studentImage != null
                          ? pw.Image(
                              studentImage,
                              fit: pw.BoxFit.cover,
                            )
                          : pw.Center(
                              child: pw.Text(
                                "PHOTO",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 18),

                // 🔷 SUBJECT HEADER
                pw.Text(
                  "Subject Performance (Max 100 each)",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 6),

                // 🔷 TABLE
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  children: [
                    // HEADER
                    pw.TableRow(
                      children: [
                        tableCell("Subject", isHeader: true),
                        tableCell("Marks", isHeader: true),
                      ],
                    ),

                    // SUBJECTS
                    ...marks.entries.map((e) {
                      return pw.TableRow(
                        children: [
                          tableCell(e.key),
                          tableCell(e.value.toString()),
                        ],
                      );
                    }).toList(),

                    // TOTAL
                    pw.TableRow(
                      children: [
                        tableCell("Grand Total", isHeader: true),
                        tableCell("$total", isHeader: true),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // 🔷 RESULT BLOCK
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  children: [
                    pw.TableRow(
                      children: [
                        tableCell("Percentage", isHeader: true),
                        tableCell("Grade", isHeader: true),
                        tableCell("Class Rank", isHeader: true),
                        tableCell("School Rank", isHeader: true),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        tableCell("${percent.toStringAsFixed(1)}%"),
                        tableCell(student['grade'] ?? "-"),
                        tableCell(student['classRank'] ?? "-"),
                        tableCell(student['schoolRank'] ?? "-"),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // 🔷 SIGNATURE
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Class Teacher"),
                    pw.Text("Principal"),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  pw.Widget infoRow(String title, dynamic value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 55,
          child: pw.Text(
            "$title:",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: PdfColors.blue900,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value?.toString() ?? "-",
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget tableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot> getFilteredStudents(String? currentStudentId) {
    // 🔥 NEW RULE: agar class select nahi → empty list
    if (selectedClasses.isEmpty) {
      return [];
    }

    return students.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final studentClass = (data['classSection'] ?? "").toString();

      // sirf selected class ke student
      if (!selectedClasses.contains(studentClass)) {
        return false;
      }

      final selectedIds = studentBlocks
          .map((e) => e["studentId"])
          .where((id) => id != null)
          .toList();

      if (doc.id == currentStudentId) return true;

      return !selectedIds.contains(doc.id);
    }).toList();
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Save Exam Data?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Kya aap is exam data ko save karna chahte hain?",
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, "dont_save"),
                  child: const Text(
                    "Don't Save",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3C91),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, "save"),
                  child: const Text(
                    "Save",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result == "save") {
      await saveExam();
    } else if (result == "dont_save") {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _showExitConfirmation(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(widget.docId != null ? "Edit Exam" : "Add Exam"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _showExitConfirmation(context),
          ),
        ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // 🔥 STUDENT MARKSHEET & EXAM DETAILS SCROLLVIEW
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    14,
                    12,
                    14,
                    keyboardBottom > 0 ? keyboardBottom + 140 : 20,
                  ),
                  child: Column(
                    children: [
                      // 🔥 TOP HEADER CARD: EXAM DETAILS & SEARCH (Inside scroll view so it hides/scrolls up when keyboard is active)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Exam Name
                            TextField(
                              controller: examNameCtrl,
                              scrollPadding: const EdgeInsets.only(bottom: 180),
                              decoration: InputDecoration(
                                labelText: "Exam Name",
                                hintText: "e.g. Annual Examination 2026",
                                prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 2. Exam Code + Full Marks + Class Select Button
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: examCodeCtrl,
                                    scrollPadding: const EdgeInsets.only(bottom: 180),
                                    decoration: InputDecoration(
                                      labelText: "Exam Code",
                                      hintText: "EX-101",
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: fullMarksCtrl,
                                    keyboardType: TextInputType.number,
                                    scrollPadding: const EdgeInsets.only(bottom: 180),
                                    decoration: InputDecoration(
                                      labelText: "Full Marks",
                                      hintText: "100",
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B3C91),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: openClassDialog,
                                  icon: const Icon(Icons.class_outlined, size: 18),
                                  label: Text(
                                    selectedClasses.isEmpty
                                        ? "Class"
                                        : "Class (${selectedClasses.length})",
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),

                            // 3. Selected Classes Pills
                            if (selectedClasses.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: selectedClasses.map((e) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          e,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E40AF),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedClasses.remove(e);
                                            });
                                          },
                                          child: const Icon(
                                            Icons.cancel,
                                            size: 14,
                                            color: Color(0xFF3B82F6),
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],

                            const SizedBox(height: 12),

                            // 4. Search Student Input
                            TextField(
                              controller: searchCtrl,
                              scrollPadding: const EdgeInsets.only(bottom: 180),
                              decoration: InputDecoration(
                                hintText: "Search Student by name...",
                                prefixIcon: const Icon(Icons.search, size: 20),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  searchText = val.toLowerCase();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      ...List.generate(studentBlocks.length, (i) {
                        var block = studentBlocks[i];

                      if (searchText.isNotEmpty) {
                        String name = (block["studentName"] ?? "").toLowerCase();
                        if (!name.contains(searchText)) {
                          return const SizedBox();
                        }
                      }

                      var result = calculateResult(block["subjects"]);
                      final filteredStudents = getFilteredStudents(block["studentId"]);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // STUDENT SELECTOR ROW WITH PDF & DELETE ACTION BUTTONS
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: block["studentId"],
                                    isExpanded: true,
                                    hint: const Text("Select Student"),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                      ),
                                    ),
                                    items: filteredStudents.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      String name = data['name'] ?? '';
                                      String roll = data['rollNo']?.toString() ?? '';
                                      return DropdownMenuItem(
                                        value: doc.id,
                                        child: Text(
                                          "$name ${roll.isNotEmpty ? '(Roll: $roll)' : ''}",
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      final d = students.firstWhere((e) => e.id == value);
                                      final data = d.data() as Map<String, dynamic>;

                                      setState(() {
                                        block["studentId"] = value;
                                        block["studentName"] = data['name'];
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // PDF Slip Icon Button
                                IconButton(
                                  tooltip: "Generate Marksheet PDF",
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.shade50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                  onPressed: () {
                                    if (block["studentId"] == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please select student first")),
                                      );
                                      return;
                                    }

                                    final selectedDoc = students.firstWhere(
                                      (e) => e.id == block["studentId"],
                                    );
                                    final userData = selectedDoc.data() as Map<String, dynamic>;

                                    final studentData = {
                                      "studentName": block["studentName"] ?? "",
                                      "father": userData['fatherName'] ?? "",
                                      "mother": userData['motherName'] ?? "",
                                      "class": userData['classSection'] ?? "",
                                      "rollNo": userData['rollNo'] ?? "",
                                      "admNo": userData['admNo'] ?? "",
                                      "dob": userData['dob'] ?? "",
                                      "photo": userData['photo'],
                                      "marks": {
                                        for (var sub in block["subjects"])
                                          sub["name"].text:
                                              int.tryParse(sub["marks"].text) ?? 0
                                      },
                                      "total": result["total"],
                                      "percent": result["percent"],
                                    };

                                    generateStudentPdf(studentData);
                                  },
                                ),

                                // Delete Student Card Button
                                if (studentBlocks.length > 1)
                                  IconButton(
                                    tooltip: "Remove Student",
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red.shade50,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => removeStudent(i),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // SUBJECTS LIST TABLE
                            Column(
                              children: List.generate(
                                block["subjects"].length,
                                (j) {
                                  var sub = block["subjects"][j];

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: TextField(
                                            controller: sub["name"],
                                            scrollPadding: const EdgeInsets.only(bottom: 220),
                                            decoration: InputDecoration(
                                              labelText: "Subject Name",
                                              hintText: "e.g. Math",
                                              filled: true,
                                              fillColor: const Color(0xFFF8FAFC),
                                              contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.grey.shade200),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.grey.shade200),
                                              ),
                                            ),
                                            onChanged: (_) {
                                              setState(() {
                                                syncSubjectsToAll(i);
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 4,
                                          child: TextField(
                                            controller: sub["marks"],
                                            keyboardType: TextInputType.number,
                                            scrollPadding: const EdgeInsets.only(bottom: 220),
                                            decoration: InputDecoration(
                                              labelText: "Marks",
                                              hintText: "0",
                                              filled: true,
                                              fillColor: const Color(0xFFF8FAFC),
                                              contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.grey.shade200),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.grey.shade200),
                                              ),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        if (block["subjects"].length > 1)
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                            onPressed: () => removeSubject(i, j),
                                          )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ADD SUBJECT BUTTON + TOTAL & PERCENT SUMMARY BAR
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0B3C91),
                                    side: const BorderSide(color: Color(0xFF93C5FD)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => addSubject(i),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text(
                                    "Add Subject",
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),

                                // Total & Percentage Pill Badges
                                Row(
                                  children: [
                                    Text(
                                      "Total: ${result['total']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF86EFAC)),
                                      ),
                                      child: Text(
                                        "${result['percent'].toStringAsFixed(1)} %",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

              // 🔥 FIXED BOTTOM ACTION BAR (+ Add Student & Save)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0B3C91),
                            side: const BorderSide(color: Color(0xFF0B3C91), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: addStudent,
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text(
                            "Add Student",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B3C91),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: saveExam,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text(
                            "Save Exam",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
      ),
    ),
  );
}
}

Future<void> generateResultPdf(
    BuildContext context, Map student, Map examData) async {
  final pdf = pw.Document();

  final marks = Map<String, dynamic>.from(student['marks'] ?? {});
  final total = student['total'] ?? 0;
  final percent = student['percent'] ?? 0;

  String studentName = (student['studentName'] ?? student['name'] ?? "").toString();
  String father = (student['father'] ?? student['fatherName'] ?? "").toString();
  String mother = (student['mother'] ?? student['motherName'] ?? "").toString();
  String rollNo = (student['rollNo'] ?? "").toString();
  String studentClass = (student['class'] ?? student['classSection'] ?? "").toString();
  String dob = (student['dob'] ?? student['dateOfBirth'] ?? "").toString();
  String photoStr = (student['photo'] ?? student['photoUrl'] ?? student['imageUrl'] ?? "").toString();

  final studentId = (student['studentId'] ?? student['id'] ?? UserSession.currentUserId ?? "").toString();

  // 🔥 SMART LOOKUP: If key details are missing, fetch complete student document from Firestore!
  if (father.isEmpty || mother.isEmpty || rollNo.isEmpty || studentClass.isEmpty || dob.isEmpty || photoStr.isEmpty) {
    try {
      DocumentSnapshot? snap;
      if (studentId.isNotEmpty) {
        snap = await UserSession.yearColl('students').doc(studentId).get();
      }
      if ((snap == null || !snap.exists) && studentName.isNotEmpty) {
        final querySnap = await UserSession.yearColl('students')
            .where('name', isEqualTo: studentName)
            .limit(1)
            .get();
        if (querySnap.docs.isNotEmpty) {
          snap = querySnap.docs.first;
        }
      }
      if ((snap == null || !snap.exists) && rollNo.isNotEmpty) {
        final querySnap = await UserSession.yearColl('students')
            .where('rollNo', isEqualTo: rollNo)
            .limit(1)
            .get();
        if (querySnap.docs.isNotEmpty) {
          snap = querySnap.docs.first;
        }
      }

      if (snap != null && snap.exists && snap.data() != null) {
        final sData = snap.data() as Map<String, dynamic>;
        if (studentName.isEmpty) studentName = (sData['name'] ?? sData['studentName'] ?? "").toString();
        if (father.isEmpty) father = (sData['fatherName'] ?? sData['father'] ?? "").toString();
        if (mother.isEmpty) mother = (sData['motherName'] ?? sData['mother'] ?? "").toString();
        if (rollNo.isEmpty) rollNo = (sData['rollNo'] ?? "").toString();
        if (studentClass.isEmpty) studentClass = (sData['classSection'] ?? sData['class'] ?? "").toString();
        if (dob.isEmpty) dob = (sData['dob'] ?? sData['dateOfBirth'] ?? "").toString();
        if (photoStr.isEmpty) photoStr = (sData['photo'] ?? sData['photoUrl'] ?? sData['imageUrl'] ?? "").toString();
      }
    } catch (e) {
      print("Firestore Student Lookup Error for PDF: $e");
    }
  }

  // 🔥 STUDENT PHOTO LOAD
  dynamic studentImage;
  if (photoStr.isNotEmpty) {
    try {
      if (photoStr.startsWith('data:image')) {
        final base64Str = photoStr.split(',').last;
        final bytes = base64Decode(base64Str);
        studentImage = pw.MemoryImage(bytes);
      } else if (photoStr.startsWith('http://') || photoStr.startsWith('https://')) {
        studentImage = await networkImage(photoStr);
      }
    } catch (e) {
      print("PDF Student Image Load Error: $e");
      studentImage = null;
    }
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (context) {
        return pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  children: [
                    pw.Text(
                      "BAL VIKASH GYAN MANDIR",
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      "Raniganj, Imamganj, Gaya (Bihar), Near:Gaytri Mandir 824210",
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      "${examData['examName'] ?? 'Student Marks Card'}",
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 14),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("Name: ${studentName.isNotEmpty ? studentName : '-'}"),
                              pw.SizedBox(height: 8),
                              pw.Text("Father: ${father.isNotEmpty ? father : '-'}"),
                              pw.SizedBox(height: 8),
                              pw.Text("Mother: ${mother.isNotEmpty ? mother : '-'}"),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("Roll No: ${rollNo.isNotEmpty ? rollNo : '-'}"),
                              pw.SizedBox(height: 8),
                              pw.Text("Class: ${studentClass.isNotEmpty ? studentClass : '-'}"),
                              pw.SizedBox(height: 8),
                              pw.Text("DOB: ${dob.isNotEmpty ? dob : '-'}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    height: 90,
                    width: 75,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blueGrey, width: 1),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: studentImage != null
                        ? pw.Image(studentImage, fit: pw.BoxFit.cover)
                        : pw.Center(
                            child: pw.Text(
                              "PHOTO",
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey600,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                "Subject Performance",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Subject", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Marks Obtained", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...marks.entries.map((e) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(e.key),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(e.value.toString()),
                        ),
                      ],
                    );
                  }).toList(),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Grand Total", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("$total / ${examData['fullMarks'] ?? 0}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Text(
                "Percentage: ${percent.toStringAsFixed(1)}% | Grade: ${student['grade'] ?? '-'}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              ),
            ],
          ),
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}

class ResultViewPage extends StatelessWidget {
  final Map<String, dynamic> examData;

  const ResultViewPage({super.key, required this.examData});

  String _calculateGrade(double percent) {
    if (percent >= 90) return "A+";
    if (percent >= 80) return "A";
    if (percent >= 70) return "B+";
    if (percent >= 60) return "B";
    if (percent >= 50) return "C";
    return "D";
  }

  String _calculateRemark(double percent) {
    if (percent >= 90) return "You are Outstanding,";
    if (percent >= 80) return "You are Excellent,";
    if (percent >= 70) return "Very Good Performance,";
    if (percent >= 60) return "Good Performance,";
    if (percent >= 50) return "Passed Successfully,";
    return "Keep Trying,";
  }

  String _calculateSubjectGrade(int marksVal, int maxSubMarks) {
    if (maxSubMarks <= 0) return "A";
    double p = (marksVal / maxSubMarks) * 100;
    return _calculateGrade(p);
  }

  @override
  Widget build(BuildContext context) {
    final uid = UserSession.currentUserId;
    final students = examData['students'] ?? [];

    final myData = students.where((s) {
      return s['studentId'] == uid;
    }).toList();

    final showList = myData.isEmpty ? students : myData;

    if (showList.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Text(examData['examName'] ?? "Result"),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            "No Result Found",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    int fullMarks = examData['fullMarks'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: PageView.builder(
        itemCount: showList.length,
        itemBuilder: (context, index) {
          final data = showList[index];
          final marks = Map<String, dynamic>.from(data['marks'] ?? {});

          int total = 0;
          marks.forEach((k, v) {
            total += (v is int ? v : (int.tryParse(v.toString()) ?? 0));
          });

          double percent = fullMarks > 0 ? (total / fullMarks) * 100 : 0;
          String overallGrade = _calculateGrade(percent);
          String remark = _calculateRemark(percent);

          int subjectCount = marks.isEmpty ? 1 : marks.length;
          int maxPerSubject = fullMarks > 0 ? (fullMarks / subjectCount).round() : 100;

          return SingleChildScrollView(
            child: Column(
              children: [
                // 🔷 TOP BANNER WITH DECORATIVE GRADIENT & CIRCULAR PERCENTAGE BADGE
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF60A5FA), Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Top Nav Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Text(
                                examData['examName'] ?? "Exam Result",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share_outlined, color: Colors.white),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Result shared successfully!")),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // CIRCULAR PERCENTAGE SCORE BADGE
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.15),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 6),
                              ),
                            ),
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${percent.toStringAsFixed(0)}%",
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    "GRADE $overallGrade",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 6,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.star, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // 🔷 MAIN RESULT SHEET CONTAINER
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        remark,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${(data['studentName'] ?? 'STUDENT').toString().toUpperCase()} !!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // MARKSHEET TABLE CONTAINER
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              color: const Color(0xFFF8FAFC),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      "Subject",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "Max Marks",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      "Score - Grade",
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),

                            ...marks.entries.map((e) {
                              int marksVal = e.value is int ? e.value : (int.tryParse(e.value.toString()) ?? 0);
                              String subGrade = _calculateSubjectGrade(marksVal, maxPerSubject);

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        e.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        "$maxPerSubject",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        "$marksVal - $subGrade",
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              color: const Color(0xFFEFF6FF),
                              child: Row(
                                children: [
                                  const Expanded(
                                    flex: 5,
                                    child: Text(
                                      "Grand Total",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "$fullMarks",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      "$total Marks",
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(0xFF1D4ED8).withOpacity(0.4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            final studentData = {
                              "studentName": data['studentName'] ?? "",
                              "father": data['father'] ?? "",
                              "mother": data['mother'] ?? "",
                              "class": data['class'] ?? "",
                              "rollNo": data['rollNo'] ?? "",
                              "admNo": data['admNo'] ?? "",
                              "dob": data['dob'] ?? "",
                              "photo": data['photo'] ?? data['photoUrl'] ?? data['imageUrl'],
                              "studentId": data['studentId'] ?? data['id'],
                              "marks": marks,
                              "total": total,
                              "percent": percent,
                              "grade": overallGrade,
                            };
                            generateResultPdf(context, studentData, examData);
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 20),
                          label: const Text(
                            "DOWNLOAD PDF",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(Icons.school_outlined, color: Color(0xFF94A3B8), size: 24),
                          Icon(Icons.menu_book_outlined, color: Color(0xFF94A3B8), size: 24),
                          Icon(Icons.calculate_outlined, color: Color(0xFF94A3B8), size: 24),
                          Icon(Icons.edit_note_outlined, color: Color(0xFF94A3B8), size: 24),
                          Icon(Icons.emoji_events_outlined, color: Color(0xFF94A3B8), size: 24),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget buildSmartImage(String url, {BoxFit fit = BoxFit.cover}) {
  if (url.startsWith('data:image')) {
    try {
      final base64Str = url.split(',').last;
      final bytes = base64Decode(base64Str);
      return Image.memory(bytes, fit: fit);
    } catch (_) {}
  }
  return Image.network(
    url,
    fit: fit,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return const Center(child: CircularProgressIndicator());
    },
    errorBuilder: (context, error, stackTrace) => const Center(
      child: Icon(Icons.broken_image, size: 40),
    ),
  );
}

class WreathFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = const Color(0xFF047857)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final innerBorder = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final leafPaint1 = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    final leafPaint2 = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.fill;

    final berryPaint = Paint()
      ..color = const Color(0xFFE11D48)
      ..style = PaintingStyle.fill;

    final flowerPaint = Paint()
      ..color = const Color(0xFFFB7185)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      const Radius.circular(22),
    );

    final innerRrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(7, 7, size.width - 14, size.height - 14),
      const Radius.circular(18),
    );

    canvas.drawRRect(rrect, framePaint);
    canvas.drawRRect(innerRrect, innerBorder);

    final List<Offset> points = [
      const Offset(22, 3),
      const Offset(3, 22),
      Offset(size.width - 22, 3),
      Offset(size.width - 3, 22),
      Offset(22, size.height - 3),
      Offset(3, size.height - 22),
      Offset(size.width - 22, size.height - 3),
      Offset(size.width - 3, size.height - 22),
      Offset(size.width / 2, 3),
      Offset(size.width / 2, size.height - 3),
      Offset(3, size.height / 2),
      Offset(size.width - 3, size.height / 2),
    ];

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 8, height: 5),
        i % 2 == 0 ? leafPaint1 : leafPaint2,
      );

      if (i % 3 == 0) {
        canvas.drawCircle(Offset(p.dx + 4, p.dy - 3), 3.2, berryPaint);
        canvas.drawCircle(Offset(p.dx - 3, p.dy + 4), 2.5, berryPaint);
      } else if (i % 2 == 0) {
        canvas.drawCircle(Offset(p.dx + 3, p.dy + 3), 3.5, flowerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool isUploading = false;

  Future<void> uploadImages() async {
    try {
      final picker = ImagePicker();

      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 40,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (pickedFiles.isEmpty) return;

      setState(() => isUploading = true);

      // 🔥 INSTANT DIRECT BASE64 + FIRESTORE WRITEBATCH (Under 1 Second Total)
      final batch = FirebaseFirestore.instance.batch();
      final galleryRef = UserSession.yearColl('gallery');
      int successCount = 0;

      for (var pickedFile in pickedFiles) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final imageUrl = "data:image/jpeg;base64,$base64String";

        final docRef = galleryRef.doc();
        batch.set(docRef, {
          'url': imageUrl,
          'time': FieldValue.serverTimestamp(),
        });
        successCount++;
      }

      if (successCount > 0) {
        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚡ $successCount Image(s) Uploaded Instantly!"),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  Future<void> deleteImage(String docId, String imageUrl) async {
    try {
      if (imageUrl.startsWith("http")) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint("Storage delete error: $e");
        }
      }

      await UserSession.yearColl('gallery').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image Deleted")),
        );
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFBE185D), Color(0xFFE11D48), Color(0xFFF43F5E)],
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Photo Gallery",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "School Memories & Events",
              style: TextStyle(
                color: Color(0xFFFECDD3),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.photo_library_rounded, color: Colors.white, size: 15),
                  SizedBox(width: 5),
                  Text(
                    "Memories",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: UserSession.currentRole == 'admin'
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: isUploading ? null : uploadImages,
              icon: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo_rounded),
              label: Text(
                isUploading ? "Uploading..." : "Add Photo",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1F2), Color(0xFFFDF2F8), Color(0xFFFAFAFA)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
        stream: UserSession.yearColl('gallery')
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No Images",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          final List<Map<String, dynamic>> galleryItems =
          docs.map<Map<String, dynamic>>((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return {
              "id": doc.id,
              "url": (data['url'] ?? "").toString(),
            };
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: galleryItems.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 900
                  ? 4
                  : MediaQuery.of(context).size.width > 600
                  ? 3
                  : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final item = galleryItems[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenGallery(
                        images: galleryItems
                            .map((e) => e['url'].toString())
                            .toList(),
                        index: index,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Inner Photo
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: ClipOval(
                            child: buildSmartImage(item['url']),
                          ),
                        ),
                      ),

                      // 2. Exact Floral Wreath PNG Overlay
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            "assets/frame_wreath.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // 🔥 DELETE BUTTON (ONLY FOR ADMIN)
                      if (UserSession.currentRole == 'admin')
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Delete"),
                                  content: const Text(
                                    "Delete this image?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, false);
                                      },
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                deleteImage(
                                  item['id'],
                                  item['url'],
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
}

class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int index;

  const FullScreenGallery({
    super.key,
    required this.images,
    required this.index,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController controller;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: widget.index);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: widget.images.length,
            itemBuilder: (context, i) {
              return InteractiveViewer(
                child: Center(
                  child: buildSmartImage(
                    widget.images[i],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentReportPage extends StatefulWidget {
  const StudentReportPage({super.key});

  @override
  State<StudentReportPage> createState() => _StudentReportPageState();
}

class _StudentReportPageState extends State<StudentReportPage> {
  String selectedFilter = "all"; // all, due, zero, advance
  List<String> selectedClasses = [];
  String searchText = "";

  Future<void> exportReportPdf() async {
    try {
      final feeSnap = await UserSession.yearColl('fees').get();
      final userSnap = await UserSession.yearColl('students')
          .get();

      Map<String, double> balanceMap = {};

      for (var feeDoc in feeSnap.docs) {
        final d = feeDoc.data();
        final String studentId = (d['studentId'] ?? "").toString();
        if (studentId.isEmpty) continue;

        final double amount =
            double.tryParse(d['amount']?.toString() ?? "0") ?? 0;

        final String type = (d['type'] ?? "").toString().toLowerCase().trim();

        final String status =
        (d['status'] ?? "").toString().toLowerCase().trim();

        balanceMap.putIfAbsent(studentId, () => 0);

        if (type == "add") {
          balanceMap[studentId] = balanceMap[studentId]! + amount;
        }

        if (type == "received" || type == "receive" || status == "paid") {
          balanceMap[studentId] = balanceMap[studentId]! - amount;
        }
      }

      var students = userSnap.docs.where((doc) {
        final data = doc.data();

        final name = (data['name'] ?? "").toString().toLowerCase();
        final className = (data['classSection'] ?? "").toString();
        final double balance = balanceMap[doc.id] ?? 0;

        if (!name.contains(searchText)) return false;

        if (selectedClasses.isNotEmpty &&
            !selectedClasses.contains(className)) {
          return false;
        }

        if (selectedFilter == "due" && balance <= 0) return false;
        if (selectedFilter == "zero" && balance != 0) return false;
        if (selectedFilter == "advance" && balance >= 0) return false;

        return true;
      }).toList();

      if (students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Export ke liye data nahi hai")),
        );
        return;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(22),
          build: (context) {
            return [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "BAL VIKASH GYAN MANDIR RANIGANJ",
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Student Balance Report",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Filter: ${selectedFilter.toUpperCase()}    Classes: ${selectedClasses.isEmpty ? "All" : selectedClasses.join(", ")}",
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Table.fromTextArray(
                headers: [
                  "S.No",
                  "Student Name",
                  "Roll No",
                  "Class",
                  "Mobile No",
                  "Balance",
                ],
                data: List.generate(students.length, (index) {
                  final doc = students[index];
                  final data = doc.data();
                  final balance = balanceMap[doc.id] ?? 0;

                  return [
                    "${index + 1}",
                    data['name'] ?? "-",
                    data['rollNo'] ?? "-",
                    data['classSection'] ?? "-",
                    data['mobile'] ?? "-",
                    "Rs ${balance.toStringAsFixed(0)}",
                  ];
                }),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                cellStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.center,
                columnWidths: {
                  0: const pw.FixedColumnWidth(35),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.8),
                  5: const pw.FlexColumnWidth(1.4),
                },
                border: pw.TableBorder.all(
                  color: PdfColors.grey600,
                  width: 0.5,
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF Export Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Report")),
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) {
                        setState(() {
                          searchText = val.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search student...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final usersSnap = await UserSession.yearColl('students')
                                .get();

                            List<String> allClasses = usersSnap.docs
                                .map((e) =>
                                (e.data()['classSection'] ?? "").toString())
                                .where((e) => e.isNotEmpty)
                                .toSet()
                                .toList();

                            List<String> tempSelected =
                            List.from(selectedClasses);

                            showModalBottomSheet(
                              context: context,
                              builder: (_) {
                                return StatefulBuilder(
                                  builder: (context, setModalState) {
                                    return Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          const Text(
                                            "Select Classes",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Expanded(
                                            child: ListView(
                                              children: allClasses.map((c) {
                                                return CheckboxListTile(
                                                  value:
                                                  tempSelected.contains(c),
                                                  title: Text(c),
                                                  onChanged: (val) {
                                                    setModalState(() {
                                                      if (val == true) {
                                                        if (!tempSelected
                                                            .contains(c)) {
                                                          tempSelected.add(c);
                                                        }
                                                      } else {
                                                        tempSelected.remove(c);
                                                      }
                                                    });
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                          SafeArea(
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    selectedClasses =
                                                        tempSelected;
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("Apply"),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                          child: const Text("Select Class"),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: exportReportPdf,
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xff0B3C91),
                                  Color(0xff6c8cff),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                buildFilter("All", "all"),
                                buildFilter("Due", "due"),
                                buildFilter("Zero", "zero"),
                                buildFilter("Advance", "advance"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: selectedClasses.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                e,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedClasses.remove(e);
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                  UserSession.yearColl('fees').snapshots(),
                  builder: (context, feeSnap) {
                    if (!feeSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    Map<String, double> balanceMap = {};

                    for (var feeDoc in feeSnap.data!.docs) {
                      final d = feeDoc.data() as Map<String, dynamic>;

                      final String studentId =
                      (d['studentId'] ?? "").toString();
                      if (studentId.isEmpty) continue;

                      final double amount =
                          double.tryParse(d['amount']?.toString() ?? "0") ?? 0;

                      final String type =
                      (d['type'] ?? "").toString().toLowerCase().trim();

                      final String status =
                      (d['status'] ?? "").toString().toLowerCase().trim();

                      balanceMap.putIfAbsent(studentId, () => 0);

                      if (type == "add") {
                        balanceMap[studentId] = balanceMap[studentId]! + amount;
                      }

                      if (type == "received" ||
                          type == "receive" ||
                          status == "paid") {
                        balanceMap[studentId] = balanceMap[studentId]! - amount;
                      }
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: UserSession.yearColl('students')
                          .snapshots(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        var students = userSnap.data!.docs;

                        students = students.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          final name =
                          (data['name'] ?? "").toString().toLowerCase();

                          final className =
                          (data['classSection'] ?? "").toString();

                          final double balance = balanceMap[doc.id] ?? 0;

                          if (!name.contains(searchText)) return false;

                          if (selectedClasses.isNotEmpty &&
                              !selectedClasses.contains(className)) {
                            return false;
                          }

                          if (selectedFilter == "due" && balance <= 0)
                            return false;
                          if (selectedFilter == "zero" && balance != 0)
                            return false;
                          if (selectedFilter == "advance" && balance >= 0) {
                            return false;
                          }

                          return true;
                        }).toList();

                        if (students.isEmpty) {
                          return const Center(child: Text("No Data"));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final data = student.data() as Map<String, dynamic>;

                            final double balance = balanceMap[student.id] ?? 0;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentFeeHistoryPage(
                                      studentId: student.id,
                                      studentName: data['name'] ?? "",
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                  Border.all(color: Colors.blue.shade100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.08),
                                      blurRadius: 10,
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.blue.shade50,
                                      child: Text("${index + 1}"),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['name'] ?? "",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "Class: ${data['classSection'] ?? "-"}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            "Roll: ${data['rollNo'] ?? "-"}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            "Mobile: ${data['mobile'] ?? "-"}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          "Balance",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "₹${balance.toStringAsFixed(0)}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: balance > 0
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFilter(String title, String value) {
    bool active = selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class LibraryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text("Library"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: [
            // 📄 PDF
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PDFPage()),
                );
              },
              child: _buildBox("PDF", Icons.picture_as_pdf, Colors.red),
            ),

            // 🎥 VIDEO
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VideoPage()),
                );
              },
              child: _buildBox("Video", Icons.play_circle_fill, Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class PDFPage extends StatefulWidget {
  @override
  State<PDFPage> createState() => _PDFPageState();
}

class _PDFPageState extends State<PDFPage> {
  final headingController = TextEditingController();
  final descController = TextEditingController();
  final linkController = TextEditingController();

  List<String> selectedClasses = [];
  String searchText = "";
  String userRole = "";
  bool isUploading = false;
  String? pickedFileName;

  @override
  void initState() {
    super.initState();
    loadRole();
  }

  void loadRole() {
    setState(() {
      userRole = UserSession.currentRole ?? "student";
    });
  }

  void clearFields() {
    headingController.clear();
    descController.clear();
    linkController.clear();
    selectedClasses.clear();
    pickedFileName = null;
    isUploading = false;
  }

  Future<void> _pickAndUploadPdf(StateSetter setStateDialog) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      setStateDialog(() {
        isUploading = true;
        pickedFileName = file.name;
      });

      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        throw Exception("Could not read PDF bytes from selected file");
      }

      String downloadUrl = "";

      try {
        if (fb.FirebaseAuth.instance.currentUser == null) {
          await fb.FirebaseAuth.instance.signInAnonymously();
        }

        final String cleanName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9\.]'), '_');
        final String fileName = "${DateTime.now().millisecondsSinceEpoch}_$cleanName";
        final Reference ref = FirebaseStorage.instance.ref().child("pdfs/$fileName");
        final metadata = SettableMetadata(contentType: 'application/pdf');

        final TaskSnapshot snap = await ref.putData(fileBytes, metadata);
        downloadUrl = await snap.ref.getDownloadURL();
      } catch (storageErr) {
        debugPrint("Firebase Storage Upload Error: $storageErr. Using Instant Base64 Fallback.");
        final String base64Pdf = base64Encode(fileBytes);
        downloadUrl = "data:application/pdf;base64,$base64Pdf";
      }

      setStateDialog(() {
        isUploading = false;
        linkController.text = downloadUrl;
        if (headingController.text.isEmpty) {
          headingController.text = file.name.replaceAll('.pdf', '').replaceAll('_', ' ');
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PDF Ready & Saved!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setStateDialog(() {
        isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> deletePDF(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Kya aap is PDF ko delete karna chahte hain?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await UserSession.yearColl("pdfs").doc(id).delete();
    }
  }

  void showAddDialog({DocumentSnapshot? editDoc}) {
    if (editDoc != null) {
      final data = editDoc.data() as Map<String, dynamic>;

      headingController.text = data['heading'] ?? "";
      descController.text = data['desc'] ?? "";
      linkController.text = data['link'] ?? "";
      selectedClasses = List<String>.from(data['classes'] ?? []);
    } else {
      clearFields();
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Container(
                padding: EdgeInsets.all(18),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          editDoc == null ? "Add PDF" : "Edit PDF",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: headingController,
                        decoration: InputDecoration(
                          labelText: "Heading",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text("Select Classes",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      StreamBuilder(
                        stream: UserSession.yearColl("classes")
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return CircularProgressIndicator();
                          }

                          final docs = snapshot.data!.docs;

                          return SizedBox(
                            height: 50,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;

                                String value =
                                    "${data['className']}-${data['section']}";

                                bool isSelected =
                                selectedClasses.contains(value);

                                return GestureDetector(
                                  onTap: () {
                                    setStateDialog(() {
                                      isSelected
                                          ? selectedClasses.remove(value)
                                          : selectedClasses.add(value);
                                    });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(right: 8),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue.withOpacity(0.15)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      "Class ${data['className']}-${data['section']}",
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "PDF Source",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 8),

                      // 📁 PICK PDF FROM PHONE BUTTON
                      InkWell(
                        onTap: isUploading ? null : () => _pickAndUploadPdf(setStateDialog),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                          ),
                          child: isUploading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.2),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Uploading PDF to Storage...",
                                      style: TextStyle(
                                        color: Color(0xFF1D4ED8),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pickedFileName != null
                                                ? "Selected: $pickedFileName"
                                                : "Choose PDF from Phone Storage",
                                            style: TextStyle(
                                              color: pickedFileName != null
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFF1D4ED8),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            "Tap to pick .pdf file from mobile",
                                            style: TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.upload_file_rounded,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "OR PASTE DIRECT LINK",
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: linkController,
                        decoration: InputDecoration(
                          labelText: "PDF Link",
                          hintText: "Auto-filled on file upload or paste URL",
                          prefixIcon: const Icon(Icons.link_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                clearFields();
                              },
                              child: Text("Cancel"),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (headingController.text.isEmpty ||
                                    linkController.text.isEmpty ||
                                    selectedClasses.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text("All fields required")),
                                  );
                                  return;
                                }

                                if (editDoc == null) {
                                  await UserSession.yearColl("pdfs")
                                      .add({
                                    "heading": headingController.text,
                                    "desc": descController.text,
                                    "classes": selectedClasses,
                                    "link": linkController.text,
                                    "time": FieldValue.serverTimestamp(),
                                  });
                                } else {
                                  await UserSession.yearColl("pdfs")
                                      .doc(editDoc.id)
                                      .update({
                                    "heading": headingController.text,
                                    "desc": descController.text,
                                    "classes": selectedClasses,
                                    "link": linkController.text,
                                  });
                                }

                                Navigator.pop(context);
                                clearFields();
                              },
                              child: Text(editDoc == null ? "Save" : "Update"),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void openLink(String link) async {
    try {
      if (link.startsWith("data:application/pdf;base64,")) {
        final base64Str = link.split(',').last;
        final bytes = base64Decode(base64Str);
        final tempDir = await getTemporaryDirectory();
        final file = File("${tempDir.path}/doc_${DateTime.now().millisecondsSinceEpoch}.pdf");
        await file.writeAsBytes(bytes);
        await OpenFile.open(file.path);
      } else {
        final Uri url = Uri.parse(link);
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening PDF: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "PDF Section",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 21,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: false,
        elevation: 6,
        shadowColor: const Color(0xFF2E073F).withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2E073F), // Ultra Deep Midnight Purple
                Color(0xFF3B0764), // Deep Baingani / Violet
                Color(0xFF581C87), // Rich Dark Royal Baingani
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: userRole == "student"
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showAddDialog(),
              backgroundColor: const Color(0xFF3B0764),
              foregroundColor: Colors.white,
              elevation: 6,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Add PDF", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search PDF...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: UserSession.yearColl("pdfs")
                  .orderBy("time", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['heading'] ?? "")
                      .toLowerCase()
                      .contains(searchText) ||
                      (data['desc'] ?? "").toLowerCase().contains(searchText);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(child: Text("No PDF Added"));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                    filteredDocs[index].data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        if (data['link'] != null) {
                          openLink(data['link']);
                        }
                      },
                      child: Container(
                        margin:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            )
                          ],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.picture_as_pdf,
                                  color: Colors.red, size: 26),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          data['heading'] ?? "",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (userRole != "student") ...[
                                        InkWell(
                                          onTap: () => showAddDialog(
                                              editDoc: filteredDocs[index]),
                                          child: Icon(Icons.edit,
                                              size: 18, color: Colors.blue),
                                        ),
                                        SizedBox(width: 6),
                                        InkWell(
                                          onTap: () =>
                                              deletePDF(filteredDocs[index].id),
                                          child: Icon(Icons.delete,
                                              size: 18, color: Colors.red),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(data['desc'] ?? ""),
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: (data['classes'] ?? [])
                                        .map<Widget>((cls) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        child: Text(cls,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue)),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPage extends StatefulWidget {
  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final headingController = TextEditingController();
  final descController = TextEditingController();
  final linkController = TextEditingController();

  List<String> selectedClasses = [];
  String searchText = "";
  String userRole = "";

  @override
  void initState() {
    super.initState();
    loadRole();
  }

  void loadRole() {
    setState(() {
      userRole = UserSession.currentRole ?? "student";
    });
  }

  void clearFields() {
    headingController.clear();
    descController.clear();
    linkController.clear();
    selectedClasses.clear();
  }

  Future<void> deleteVideo(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Delete this video?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await UserSession.yearColl("videos").doc(id).delete();
    }
  }

  void showAddDialog({DocumentSnapshot? editDoc}) {
    if (editDoc != null) {
      final data = editDoc.data() as Map<String, dynamic>;
      headingController.text = data['heading'] ?? "";
      descController.text = data['desc'] ?? "";
      linkController.text = data['link'] ?? "";
      selectedClasses = List<String>.from(data['classes'] ?? []);
    } else {
      clearFields();
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Container(
                padding: EdgeInsets.all(18),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          editDoc == null ? "Add Video" : "Edit Video",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: headingController,
                        decoration: InputDecoration(labelText: "Heading"),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: descController,
                        decoration: InputDecoration(labelText: "Description"),
                      ),
                      SizedBox(height: 10),
                      Text("Select Classes"),
                      SizedBox(height: 6),
                      StreamBuilder(
                        stream: UserSession.yearColl("classes")
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return CircularProgressIndicator();

                          final docs = snapshot.data!.docs;

                          return SizedBox(
                            height: 50,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                String value =
                                    "${data['className']}-${data['section']}";

                                bool isSelected =
                                selectedClasses.contains(value);

                                return GestureDetector(
                                  onTap: () {
                                    setStateDialog(() {
                                      isSelected
                                          ? selectedClasses.remove(value)
                                          : selectedClasses.add(value);
                                    });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(right: 8),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue.withOpacity(0.15)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(value),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: linkController,
                        decoration: InputDecoration(labelText: "Video Link"),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                clearFields();
                              },
                              child: Text("Cancel"),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (headingController.text.isEmpty ||
                                    linkController.text.isEmpty ||
                                    selectedClasses.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text("All fields required")),
                                  );
                                  return;
                                }

                                if (editDoc == null) {
                                  await UserSession.yearColl("videos")
                                      .add({
                                    "heading": headingController.text,
                                    "desc": descController.text,
                                    "classes": selectedClasses,
                                    "link": linkController.text,
                                    "time": FieldValue.serverTimestamp(),
                                  });
                                } else {
                                  await UserSession.yearColl("videos")
                                      .doc(editDoc.id)
                                      .update({
                                    "heading": headingController.text,
                                    "desc": descController.text,
                                    "classes": selectedClasses,
                                    "link": linkController.text,
                                  });
                                }

                                Navigator.pop(context);
                                clearFields();
                              },
                              child: Text(editDoc == null ? "Save" : "Update"),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void openLink(String link) async {
    final Uri url = Uri.parse(link);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Video Section",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 21,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: false,
        elevation: 6,
        shadowColor: const Color(0xFF881337).withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4C0519), // Ultra Deep Rose Midnight
                Color(0xFF881337), // Deep Crimson Ruby Red
                Color(0xFFBE123C), // Vibrant Rose Crimson
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: userRole == "student"
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showAddDialog(),
              backgroundColor: const Color(0xFF881337),
              foregroundColor: Colors.white,
              elevation: 6,
              icon: const Icon(Icons.video_call_rounded),
              label: const Text("Add Video", style: TextStyle(fontWeight: FontWeight.bold)),
            ),

      body: StreamBuilder(
        stream: UserSession.yearColl("videos")
            .orderBy("time", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () {
                  if (data['link'] != null) {
                    openLink(data['link']);
                  }
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      )
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🎥 SAME ICON
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.play_circle_fill,
                            color: Colors.blue, size: 26),
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['heading'] ?? "",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // 🔥 ONLY CHANGE (hide for student)
                                if (userRole != "student") ...[
                                  InkWell(
                                    onTap: () =>
                                        showAddDialog(editDoc: docs[index]),
                                    child: Icon(Icons.edit,
                                        size: 18, color: Colors.blue),
                                  ),
                                  SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => deleteVideo(docs[index].id),
                                    child: Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(data['desc'] ?? ""),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children:
                              (data['classes'] ?? []).map<Widget>((cls) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    cls,
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.blue),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StudentFeeHistoryPage extends StatelessWidget {
  final String studentId;
  final String studentName;

  const StudentFeeHistoryPage({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  String formatDate(dynamic time) {
    if (time == null) return "-";
    final dt = (time as Timestamp).toDate();
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  // 🔥 DETAILS EXTRACT (IMPORTANT)
  String getDetails(Map<String, dynamic> d) {
    try {
      List<String> parts = [];

      d.forEach((key, value) {
        // ❌ ये fields ignore
        if (key == "amount" ||
            key == "type" ||
            key == "month" ||
            key == "studentId" ||
            key == "time" ||
            key == "status") return;

        // ✅ numeric fields पकड़ो
        if (value is num && value > 0) {
          parts.add("$key=$value");
        }

        // ✅ अगर map के अंदर भी data है
        if (value is Map) {
          value.forEach((k, v) {
            if (v is num && v > 0) {
              parts.add("$k=$v");
            }
          });
        }
      });

      return parts.join(", ");
    } catch (e) {
      return "";
    }
  }

  Future<void> exportPdf(BuildContext context) async {
    try {
      final snap = await UserSession.yearColl('fees')
          .where('studentId', isEqualTo: studentId)
          .get();

      if (snap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No Data")),
        );
        return;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return [
              // 🔥 HEADER
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "BAL VIKASH GYAN MANDIR RANIGANJ",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "Student Fee Details",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      "Student Name: $studentName",
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              // 🔥 TABLE
              pw.Table.fromTextArray(
                headers: ["Date", "Month", "Fees Add", "Fees Received"],
                data: snap.docs.map((doc) {
                  final d = doc.data();

                  final amount =
                      double.tryParse(d['amount']?.toString() ?? "0") ?? 0;

                  final type = (d['type'] ?? "").toString().toLowerCase();

                  final details = getDetails(d);

                  return [
                    formatDate(d['time']),
                    d['month'] ?? "-",

                    // 🔴 ADD + DETAILS
                    type == "add"
                        ? "Rs ${amount.toStringAsFixed(0)}"
                        "${details.isNotEmpty ? "\n($details)" : ""}"
                        : "",

                    // 🟢 RECEIVED + DETAILS
                    (type == "received" || type == "receive")
                        ? "Rs ${amount.toStringAsFixed(0)}"
                        "${details.isNotEmpty ? "\n($details)" : ""}"
                        : "",
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                ),
                cellStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellPadding: const pw.EdgeInsets.all(6),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: ModalRoute.of(context)?.canPop ?? false,
        title: Text(
          studentName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: false,
        elevation: 6,
        shadowColor: const Color(0xFF0F172A).withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF334155),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            onPressed: () => exportPdf(context),
            tooltip: "Export PDF",
          )
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: UserSession.yearColl('fees')
            .where('studentId', isEqualTo: studentId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No Transactions Found",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              color: Colors.white,
              child: Column(
                children: [
                  // 📊 TABLE HEADER BAR (DEBIT / CREDIT COLUMNS)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            "DATE & MONTH",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF475569),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 85,
                          child: Text(
                            "DEBIT (DUE)",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            "CREDIT (PAID)",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 📝 TRANSACTION LIST (NO GAP, BOTTOM BORDER ONLY)
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;

                        double amount =
                            double.tryParse(data['amount']?.toString() ?? "0") ?? 0;

                        String type = (data['type'] ?? "").toString().toLowerCase().trim();
                        bool isDebit = type == "add";

                        DateTime? date;
                        if (data['time'] != null && data['time'] is Timestamp) {
                          date = (data['time'] as Timestamp).toDate();
                        }

                        String dateStr = date != null
                            ? "${date.day}/${date.month}/${date.year}"
                            : "-";

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 📅 DATE & MONTH
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Month: ${data['month'] ?? "-"}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 🔴 DEBIT COLUMN
                              SizedBox(
                                width: 85,
                                child: Text(
                                  isDebit ? "₹${amount.toStringAsFixed(0)}" : "-",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: isDebit ? const Color(0xFFDC2626) : Colors.grey.shade300,
                                    fontWeight: isDebit ? FontWeight.w900 : FontWeight.w600,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),

                              // 🟢 CREDIT COLUMN
                              SizedBox(
                                width: 90,
                                child: Text(
                                  !isDebit ? "₹${amount.toStringAsFixed(0)}" : "-",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: !isDebit ? const Color(0xFF16A34A) : Colors.grey.shade300,
                                    fontWeight: !isDebit ? FontWeight.w900 : FontWeight.w600,
                                    fontSize: 14.5,
                                  ),
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
            ),
          );
        },
      ),
    );
  }
}
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState
    extends State<ForgotPasswordDialog> {

  final TextEditingController emailCtrl =
  TextEditingController();

  bool loading = false;

  Future<void> sendPassword() async {

    final email = emailCtrl.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email dijiye"),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {

      DocumentSnapshot? targetDoc;

      var snap = await UserSession.yearColl('admins')
          .where('email', isEqualTo: email)
          .get();

      if (snap.docs.isNotEmpty) {
        targetDoc = snap.docs.first;
      } else {
        snap = await UserSession.yearColl('teachers')
            .where('email', isEqualTo: email)
            .get();
        if (snap.docs.isNotEmpty) {
          targetDoc = snap.docs.first;
        } else {
          snap = await UserSession.yearColl('students')
              .where('email', isEqualTo: email)
              .get();
          if (snap.docs.isNotEmpty) {
            targetDoc = snap.docs.first;
          }
        }
      }

      if (targetDoc == null) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email not found"),
          ),
        );

        setState(() {
          loading = false;
        });

        return;
      }

      final data = targetDoc.data() as Map<String, dynamic>;

      final password = data['password'] ?? "";

      final name = data['name'] ?? "";

      await sendEmail(
        toEmail: email,
        subject: "Your Password",
        body: """
Dear $name,

Your login password is:

$password

Thank You
BVGM School
""",
      );

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Password sent to email",
            ),
          ),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );

    }

    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(

      title: const Text("Forgot Password"),

      content: TextField(
        controller: emailCtrl,
        decoration: const InputDecoration(
          labelText: "Enter Email",
        ),
      ),

      actions: [

        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed: loading ? null : sendPassword,
          child: loading
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text("Generate Password"),
        ),

      ],
    );
  }
}

