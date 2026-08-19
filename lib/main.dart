import 'package:flutter/material.dart';
import 'dart:ui'; // 🔥 add at top अगर नहीं है
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
      "sender": {"name": "SCCR Coaching", "email": "infopushpraj343@gmail.com"},
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School App',
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

  Future<UserRole> _getRole(fb.User user) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final role = doc.data()?['role'];

      if (role == "admin") return UserRole.admin;
      if (role == "teacher") return UserRole.teacher;
      if (role == "student") return UserRole.student;
    }

    return UserRole.student;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb.User?>(
      stream: fb.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData) {
          return const LoginPage();
        }

        return FutureBuilder<UserRole>(
          future: _getRole(snap.data!),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return HomeShell(
              role: roleSnap.data ?? UserRole.student,
            );
          },
        );
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool hidePass = true;
  bool loading = false;

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = userCtrl.text.trim();
    final password = passCtrl.text.trim();

    // 🔥 ADMIN FIX LOGIN
    if (email == "admin" && password == "1234") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeShell(role: UserRole.admin),
        ),
      );
      return;
    }

    // 🔽 NORMAL FIREBASE LOGIN
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email aur password dijiye')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final cred = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Error")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xfff7fbff),
              Color(0xffeef4ff),
              Color(0xfff5f0ff),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 430),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.86),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      height: 68,
                      width: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          "assets/logo.png", // 👈 apna logo
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'SCCR',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'WELCOME TO SARASWATI COACHING CENTER RANIGANJ.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.subText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 18),
                    buildField(
                      controller: userCtrl,
                      hint: 'User ID / Email',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 14),
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
                          color: AppColors.subText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: loading ? null : _login,
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Center(
                          child: loading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xfff7faff),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xffe4ebff)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.black),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Use Correct User Name OR Pasword.',
                              style: TextStyle(
                                color: AppColors.subText,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
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
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: Colors.black),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.subText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffdbe5ff)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffdbe5ff)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
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
        return ['Dashboard', 'Students', 'Add', 'Notices', 'Profile'];
      case UserRole.teacher:
        return ['Dashboard', 'Attendance', 'Homework', 'Notices', 'Profile'];
      case UserRole.student:
        return ['Dashboard', 'Attendance', 'Results', 'Notices', 'Profile'];
    }
  }

  IconData getNavIcon(int index) {
    switch (index) {
      case 0:
        return Icons.grid_view_rounded;
      case 1:
        return Icons.fact_check_outlined;
      case 2:
        return Icons.add;
      case 3:
        return Icons.notifications_active_outlined;
      default:
        return Icons.person_outline_rounded;
    }
  }

  Future<void> _logout() async {
    await fb.FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final pages = [
      DashboardPage(role: widget.role, onLogout: _logout),
      SecondPage(role: widget.role, title: tabs[1]),
      ThirdPage(role: widget.role, title: tabs[2]),
      NoticesPage(role: widget.role),
      ProfilePage(role: widget.role),
    ];

    return Scaffold(
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
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 38),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.80),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.black.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                widget.role == UserRole.student ? 4 : 5,
                    (index) {
                  int i = index;

                  if (widget.role == UserRole.student && index >= 2) {
                    i = index + 1;
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (index == 2 && widget.role == UserRole.admin) {
                          showDialog(
                            context: context,
                            builder: (_) => AddUserDialog(),
                          );
                          return;
                        }

                        setState(() {
                          currentIndex = i;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: currentIndex == i
                              ? const Color(0xFF0B3C91).withOpacity(0.12)
                              : Colors.transparent,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🔥 CENTER BUTTON SPECIAL DESIGN
                            if (index == 2 &&
                                widget.role == UserRole.admin)
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff6c8cff),
                                      Color(0xff8f9fff),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.4),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.add,
                                    color: Colors.white, size: 26),
                              )
                            else
                              Stack(
                                children: [
                                  Icon(
                                    getNavIcon(i),
                                    size: 26,
                                    color: currentIndex == i
                                        ? const Color(0xFF0B3C91)
                                        : AppColors.subText,
                                  ),
                                  if (i == 3)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('notices')
                                            .where(
                                          Filter.or(
                                            Filter(
                                              'role',
                                              isEqualTo: widget.role.name,
                                            ),
                                            Filter(
                                              'studentId',
                                              isEqualTo:
                                              fb.FirebaseAuth.instance.currentUser?.uid,
                                            ),
                                          ),
                                        )
                                            .snapshots(),
                                        builder: (context, snap) {
                                          if (!snap.hasData) {
                                            return const SizedBox();
                                          }

                                          final uid = fb.FirebaseAuth
                                              .instance.currentUser?.uid;

                                          int unread = 0;

                                          for (var doc
                                          in snap.data!.docs) {
                                            final data = doc.data()
                                            as Map<String, dynamic>;

                                            List seenBy =
                                                data['seenBy'] ?? [];

                                            if (!seenBy.contains(uid)) {
                                              unread++;
                                            }
                                          }

                                          if (unread == 0) {
                                            return const SizedBox();
                                          }

                                          return Container(
                                            padding:
                                            const EdgeInsets.all(5),
                                            decoration:
                                            const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              unread.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight:
                                                FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              )
                          ],
                        ),
                      ),
                    ),
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
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width > 900
                    ? 1180
                    : double.infinity,
              ),
              margin: EdgeInsets.all(
                MediaQuery.of(context).size.width > 900 ? 18 : 4,
              ),
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width > 900 ? 18 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.78),
                borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width > 900 ? 34 : 26,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 120),
                children: [
                  header(context),
                  const SizedBox(height: 18),
                  premiumBanner(),
                  const SizedBox(height: 18),
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // YEAR
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: DropdownButton<int>(
                          value: selectedYear,
                          underline: const SizedBox(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18),
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

                      const SizedBox(width: 10),

                      // MONTH
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: DropdownButton<int>(
                          value: selectedMonth,
                          underline: const SizedBox(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18),
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
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'student')
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
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'teacher')
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
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'admin')
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
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(fb.FirebaseAuth.instance.currentUser!.uid)
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
                          stream: FirebaseFirestore.instance
                              .collection('fees')
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
                          stream: FirebaseFirestore.instance
                              .collection('notices')
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
                        final uid = fb.FirebaseAuth.instance.currentUser!.uid;

                        return StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('fees')
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
                          ? 1.08
                          : 0.92,
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
        ),
      ),
    );
  }

  Widget header(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              "assets/logo.png", // 👈 apna logo yaha dalna
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$roleName Dashboard',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.cyan,
                    Colors.blue,
                    Colors.purple,
                  ],
                ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: const Text(
                  'SARASWATI COACHING CENTER RANIGANJ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white, // shader ke liye white rakhna hota hai
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: () async {
                  await sendEmail(
                    toEmail: "infopushpraj343@gmail.com",
                    subject: "Test Mail",
                    body: "Hello from SCCR Coaching App",
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Mail Sent"),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.email,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: widget.onLogout,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget premiumBanner() {
    final List<String> images = [
      "assets/slider1.png",
      "assets/slider2.png",
      "assets/slider3.jpeg",
    ];

    return SizedBox(
      height: MediaQuery.of(context).size.width > 900 ? 340 : 180,
      child: PageView.builder(
        controller: _controller,
        onPageChanged: (i) {
          _current = i;
        },
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                images[index],
                fit: BoxFit.fill,
                width: double.infinity,
              ),
            ),
          );
        },
      ),
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

    // 🔽 NORMAL CARD (बाकी सब same)
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: getIconBgColor(title),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: getIconColor(title)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.subText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: premiumCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: getIconBgColor(title), // ✅ CHANGE
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: getIconColor(title)), // ✅ CHANGE
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open Module',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
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
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;

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
              ? FirebaseFirestore.instance
              .collection('notices')
              .orderBy(
            'time',
            descending: true,
          )
              .snapshots()
              : FirebaseFirestore.instance
              .collection('notices')
              .where(
            Filter.or(
              Filter(
                'role',
                isEqualTo: role.name,
              ),
              Filter(
                'studentId',
                isEqualTo: fb.FirebaseAuth.instance.currentUser?.uid,
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
                                await FirebaseFirestore.instance
                                    .collection('notices')
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
      await FirebaseFirestore.instance.collection('notices').add({
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
    final user = fb.FirebaseAuth.instance.currentUser;

    return CommonPage(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              // 👤 TOP CARD
              // 🔥 NEW PREMIUM HEADER
              Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(60),
                        bottomRight: Radius.circular(60),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            gradient: const LinearGradient(
                              colors: [Color(0xff667eea), Color(0xff764ba2)],
                            ),
                          ),
                          child: ClipOval(
                            child: (data['photo'] != null &&
                                data['photo'].toString().isNotEmpty)
                                ? Image.network(
                              data['photo'],
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                  context,
                                  child,
                                  progress,
                                  ) {
                                if (progress == null) {
                                  return child;
                                }

                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                  ) {
                                print(
                                  "IMAGE ERROR: $error",
                                );

                                return const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                );
                              },
                            )
                                : const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          (data['name'] ?? "").toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          roleText,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              const SizedBox(height: 14),

              // 📧 EMAIL
              profileTile(Icons.email_outlined, 'Email', data['email'] ?? ""),

              // 📱 PHONE (अब DB से आएगा)
              profileTile(Icons.phone_outlined, 'Phone', data['mobile'] ?? ""),

              // 📍 ADDRESS (अब DB से आएगा)
              profileTile(
                  Icons.location_on_outlined, 'Address', data['address'] ?? ""),

              profileTile(Icons.settings_outlined, 'Settings',
                  'Theme, security, notifications'),
            ],
          );
        },
      ),
    );
  }

  Widget profileTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: commonDecoration(),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: const Color(0xffedf3ff),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
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
                  value,
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

class CommonPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const CommonPage({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

  String role = "student";
  String? selectedClass;

  List<Map<String, dynamic>> classList = [];

  List<String> subjectList = [
    "Math",
    "Science",
    "English",
    "Hindi",
    "Computer"
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

      role = widget.oldData!['role'] ?? "student";

      selectedClass = widget.oldData!['classSection'];
    }

    FirebaseFirestore.instance.collection('classes').get().then((snap) {
      setState(() {
        classList = snap.docs.map((e) => e.data()).toList();
      });
    });
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
    try {
      if (imageBytes == null) return null;

      final fileName = DateTime.now().millisecondsSinceEpoch.toString();

      final ref = FirebaseStorage.instance.ref().child("uploads/$fileName.jpg");

      final metadata = SettableMetadata(
        contentType: "image/jpeg",
      );

      final task = await ref.putData(
        imageBytes!,
        metadata,
      );

      final url = await task.ref.getDownloadURL();

      print("IMAGE URL => $url");

      return url;
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  Future<void> saveUser() async {
    try {
      if (imageBytes != null) {
        imageUrl = await uploadImage();
      }

      if (widget.docId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.docId)
            .update({
          'name': nameCtrl.text.trim(),
          'fatherName': fatherCtrl.text.trim(),
          'motherName': motherCtrl.text.trim(),
          'rollNo': rollCtrl.text.trim(),
          'mobile': mobileCtrl.text.trim(),
          'address': addressCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'photo': imageUrl ?? "",
          'role': role,
          'classSection': selectedClass ?? "",
          'subject': role == "teacher" ? subject : "",
          'password': passCtrl.text.trim(),
        });
      } else {
        final cred =
        await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passCtrl.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'name': nameCtrl.text.trim(),
          'fatherName': fatherCtrl.text.trim(),
          'motherName': motherCtrl.text.trim(),
          'rollNo': rollCtrl.text.trim(),
          'mobile': mobileCtrl.text.trim(),
          'address': addressCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'password': passCtrl.text.trim(),
          'role': role,
          'photo': imageUrl ?? "",
          'classSection': selectedClass ?? "",
          'subject': role == "teacher" ? subject : "",
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Navigator.pop(context);
    } catch (e) {
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add User"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                child: imageBytes != null
                    ? ClipOval(
                  child: Image.memory(
                    imageBytes!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
                    : (imageUrl != null && imageUrl!.isNotEmpty)
                    ? ClipOval(
                  child: Image.network(
                    imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Icon(
                  Icons.camera_alt,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Name",
              ),
            ),
            TextField(
              controller: fatherCtrl,
              decoration: const InputDecoration(
                labelText: "Father Name",
              ),
            ),
            TextField(
              controller: motherCtrl,
              decoration: const InputDecoration(
                labelText: "Mother Name",
              ),
            ),
            TextField(
              controller: mobileCtrl,
              decoration: const InputDecoration(
                labelText: "Mobile No",
              ),
            ),
            TextField(
              controller: rollCtrl,
              decoration: const InputDecoration(
                labelText: "Roll No",
              ),
            ),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                labelText: "Address",
              ),
            ),
            DropdownButton<String>(
              value: selectedClass,
              hint: const Text(
                "Select Class",
              ),
              isExpanded: true,
              items: classList.map((e) {
                String value = "${e['className']}-${e['section']}";

                return DropdownMenuItem(
                  value: value,
                  child: Text(
                    "Class ${e['className']} - ${e['section']}",
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  selectedClass = v;
                });
              },
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(
                labelText: "Password",
              ),
            ),
            DropdownButton<String>(
              value: role,
              items: const [
                DropdownMenuItem(
                  value: "student",
                  child: Text("Student"),
                ),
                DropdownMenuItem(
                  value: "teacher",
                  child: Text("Teacher"),
                ),
                DropdownMenuItem(
                  value: "admin",
                  child: Text("Admin"),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  role = v!;
                });
              },
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saveUser,
          child: Text(
            widget.docId != null ? "Update" : "Save",
          ),
        )
      ],
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
      final sheet = excel['Students'];

      // HEADER
      sheet.appendRow([
        "Name",
        "Father Name",
        "Mother Name",
        "Mobile",
        "Roll No",
        "Address",
        "Class",
        "Email",
        "Password"
      ]);

      // 🔥 class fetch
      final snap = await FirebaseFirestore.instance.collection('classes').get();

      final classSheet = excel['Classes'];

      for (var doc in snap.docs) {
        final data = doc.data();
        String cls = "${data['className']}-${data['section']}";
        classSheet.appendRow([cls]);
      }

      final bytes = excel.encode();
      if (bytes == null) return;

      // 🔥 DIRECT DOWNLOAD PATH
      final dir = Directory('/storage/emulated/0/Download');

      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final file = File("${dir.path}/students.xlsx");

      await file.writeAsBytes(bytes);

      print("✅ Saved in Download: ${file.path}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Saved in Download/students.xlsx"),
        ),
      );
    } catch (e) {
      print("❌ EXPORT ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Export Failed"),
        ),
      );
    }
  }

  Future<void> importStudentsExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null) return;

    final bytes = File(result.files.single.path!).readAsBytesSync();

    final excel = ex.Excel.decodeBytes(bytes);
    final sheet = excel['Students'];

    int success = 0;
    int fail = 0;

    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);

      // 🔥 DEBUG (console me dikhega)
      print("ROW $i => ${row.map((e) => e?.value).toList()}");

      try {
        String name = (row.length > 0 && row[0] != null)
            ? row[0]!.value.toString().trim()
            : "";

        String father = (row.length > 1 && row[1] != null)
            ? row[1]!.value.toString().trim()
            : "";

        String mother = (row.length > 2 && row[2] != null)
            ? row[2]!.value.toString().trim()
            : "";

        String mobile = (row.length > 3 && row[3] != null)
            ? row[3]!.value.toString().trim()
            : "";

        String roll = (row.length > 4 && row[4] != null)
            ? row[4]!.value.toString().trim()
            : "";

        String address = (row.length > 5 && row[5] != null)
            ? row[5]!.value.toString().trim()
            : "";

        String classSection = (row.length > 6 && row[6] != null)
            ? row[6]!.value.toString().trim()
            : "";

        String email = (row.length > 7 && row[7] != null)
            ? row[7]!.value.toString().trim()
            : "";

        String password = (row.length > 8 && row[8] != null)
            ? row[8]!.value.toString().trim()
            : "";

        // ❌ skip invalid row
        if (email.isEmpty || password.isEmpty) {
          print("❌ Row $i skipped (email/password missing)");
          fail++;
          continue;
        }

        final cred =
        await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          "name": name,
          "fatherName": father,
          "motherName": mother,
          "mobile": mobile,
          "rollNo": roll,
          "address": address,
          "classSection": classSection,
          "email": email,
          "role": "student",
          "createdAt": FieldValue.serverTimestamp(),
        });

        success++;
      } catch (e) {
        fail++;
        print("❌ Row $i Error: $e");
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Done: $success success, ❌ $fail failed"),
      ),
    );
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
                          final usersSnap = await FirebaseFirestore.instance
                              .collection('users')
                              .where('role', isEqualTo: 'student')
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
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'student')
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
                                    await FirebaseFirestore.instance
                                        .collection('users')
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
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'teacher')
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
                          await FirebaseFirestore.instance
                              .collection('users')
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
    final snap = await FirebaseFirestore.instance.collection('classes').get();

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

    final snap = await FirebaseFirestore.instance
        .collection('attendance')
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

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
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

        FirebaseFirestore.instance
            .collection('attendance')
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
      appBar: AppBar(title: Text("Attendance")),
      body: Column(
        children: [
          // DATE + FILTER
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: pickDate,
                    child: Text(
                      selectedDate == null
                          ? "Select Date"
                          : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
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
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'student')
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

    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'studentId': widget.id,
      'date': Timestamp.fromDate(
        DateTime(widget.date.year, widget.date.month, widget.date.day),
      ),
      'dateId': dateId,
      'status': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final studentDoc = await FirebaseFirestore.instance
        .collection('users')
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
  SCCR Coaching
  
  """
              : """
  
  Dear ${widget.name},
  
  You have been marked ABSENT today.
  
  Date:
  ${widget.date.day}-${widget.date.month}-${widget.date.year}
  
  Please contact coaching if needed.
  
  Thank You
  SCCR Coaching
  
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
    final doc = await FirebaseFirestore.instance
        .collection('attendance')
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

    await FirebaseFirestore.instance.collection('classes').add({
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
                stream: FirebaseFirestore.instance
                    .collection('classes')
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
                                  await FirebaseFirestore.instance
                                      .collection('classes')
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
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('attendance')
        .where('studentId', isEqualTo: user.uid)
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
        title: const Text("My Attendance"),
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
  final user = fb.FirebaseAuth.instance.currentUser;

  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection('attendance')
        .where('studentId', isEqualTo: user!.uid) // 🔥 USER FILTER
        .snapshots(),
    builder: (context, snap) {
      int present = 0;
      int absent = 0;

      if (snap.hasData) {
        for (var d in snap.data!.docs) {
          final data = d.data() as Map<String, dynamic>;

          DateTime date = (data['date'] as Timestamp).toDate();

          // 🔥 YEAR + MONTH FILTER
          if (date.year == selectedYear && date.month == selectedMonth) {
            if (data['status'] == "P") present++;
            if (data['status'] == "A") absent++;
          }
        }
      }

      // 🔥 SELECTED MONTH DAYS
      int totalDays = DateTime(selectedYear, selectedMonth + 1, 0).day;

      double percent = isPresent ? present / totalDays : absent / totalDays;

      percent = percent.clamp(0, 1);

      Color color = isPresent ? Colors.green : Colors.red;

      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: isPresent
                    ? [
                  Colors.green.withOpacity(0.15),
                  Colors.green.withOpacity(0.05),
                ]
                    : [
                  Colors.red.withOpacity(0.15),
                  Colors.red.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isPresent
                    ? Colors.green.withOpacity(0.25)
                    : Colors.red.withOpacity(0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 6.3, // 🔁 full rotation
                        child: child,
                      );
                    },
                    onEnd: () {
                      (context as Element).markNeedsBuild(); // 🔁 repeat
                    },
                    child: SizedBox(
                      height: 85,
                      width: 85,
                      child: CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 3,
                        backgroundColor: Colors.white.withOpacity(0.6),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  Text(
                    "${(percent * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
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

  // 🔥 PDF FUNCTION SAME
  Future<void> generateReceipt(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          final details = (data['details'] ?? []) as List;

          return pw.Padding(
            padding: pw.EdgeInsets.all(20),
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
                pw.Text(
                    "Class : ${data['class'] ?? data['classSection'] ?? "-"}"),
                pw.Text("Month : ${data['month'] ?? ""}"),
                pw.Text(
                  "Date : ${data['time'] != null ? (data['time'].toDate().toString().split(' ')[0]) : ""}",
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Text("Amount Details",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
                    pw.Text("Total",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Rs. ${data['amount'] ?? 0}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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

    final studentDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(data['studentId'])
        .get();

    if (studentDoc.exists) {
      final studentData = studentDoc.data() as Map<String, dynamic>;

      final studentEmail = studentData['email'] ?? "";

      if (studentEmail.toString().isNotEmpty) {
        final base64Pdf = base64Encode(pdfBytes);

        final response = await http.post(
          Uri.parse(
            "https://api.brevo.com/v3/smtp/email",
          ),
          headers: {
            "accept": "application/json",
            "api-key":
            "YOUR_BREVO_API_KEY",
            "content-type": "application/json",
          },
          body: jsonEncode({
            "sender": {
              "name": "SCCR Coaching",
              "email": "infopushpraj343@gmail.com"
            },
            "to": [
              {"email": studentEmail}
            ],
            "subject": "Fees Receipt PDF",
            "htmlContent": """
  
          <html>
  
            <body>
  
              <h3>Fees Receipt</h3>
  
              <p>
              Dear ${data['studentName']},
              your receipt PDF is attached.
              </p>
  
            </body>
  
          </html>
  
          """,
            "attachment": [
              {"content": base64Pdf, "name": "fees_receipt.pdf"}
            ]
          }),
        );

        print(response.body);
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text("Receipt")),
          body: PdfPreview(
            build: (format) => pdf.save(),
          ),
        ),
      ),
    );
  }

  Future<void> loadStudents() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    setState(() {
      allStudents = snap.docs;
    });
  }

  Future<void> loadTotalCount() async {
    final snap =
    await FirebaseFirestore.instance.collection('fees').count().get();

    setState(() {
      totalCount = snap.count ?? 0;
    });
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
      child: Column(
        children: [
          /// 🔘 BUTTONS SAME
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
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
                  child: const Text("+ Add"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
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
                  child: const Text("+ Received"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
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

          // 🔥 DATE FILTER UI
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: commonDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          fromDate = picked;
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          fromDate == null
                              ? "From Date"
                              : "${fromDate!.day}/${fromDate!.month}/${fromDate!.year}",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          toDate = picked;
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          toDate == null
                              ? "To Date"
                              : "${toDate!.day}/${toDate!.month}/${toDate!.year}",
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      fromDate = null;
                      toDate = null;
                    });
                  },
                )
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// 🔥 LIST
          StreamBuilder<QuerySnapshot>(
            stream: (fromDate != null && toDate != null)
                ? FirebaseFirestore.instance
                .collection('fees')
                .where(
              'time',
              isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate!),
            )
                .where(
              'time',
              isLessThanOrEqualTo: Timestamp.fromDate(
                toDate!.add(const Duration(days: 1)),
              ),
            )
                .orderBy('time', descending: true)
                .snapshots()
                : const Stream.empty(),
            builder: (context, snap) {
              if (fromDate == null || toDate == null) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: commonDecoration(),
                    child: const Text(
                      "Please Select From Date and To Date",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

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

              // 🔥 DATE FILTER
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;

                // 🔍 SEARCH FILTER
                final name =
                (data['studentName'] ?? "").toString().toLowerCase();

                if (searchText.isNotEmpty && !name.contains(searchText)) {
                  return false;
                }

                return true;
              }).toList();

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

                  /// 🔥 TOTAL CARD SAME
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: commonDecoration(),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Total Add"),
                                Text(
                                  "₹${totalAdd.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text("Received"),
                                Text(
                                  "₹${totalReceived.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            const Text("Balance"),
                            Text(
                              "₹${balance.toStringAsFixed(1)}",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// 🔽 LIST ITEMS (UNCHANGED)
                  ...filteredDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final status =
                    (data['status'] ?? "").toString().toLowerCase().trim();

                    return GestureDetector(
                      onTap: () {
                        generateReceipt(data);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: commonDecoration(),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['studentName'] ?? "No Name",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Month: ${data['month'] ?? ''}",
                                        style:
                                        const TextStyle(color: Colors.grey),
                                      ),
                                      if (data['time'] != null)
                                        Text(
                                          "Date: ${_formatDate(data['time'])}",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "₹${data['amount']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == "paid"
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => AddFeesSheet(
                                        isReceived:
                                        (data['status'] ?? "") == "paid",
                                        docId: doc.id,
                                        oldData: data,
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.edit,
                                      color: Colors.blue),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () async {
                                    bool? confirm = await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text("Confirm Delete"),
                                          content: Text("Delete karna hai?"),
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
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('fees')
                                          .doc(doc.id)
                                          .delete();
                                    }
                                  },
                                  child: const Icon(Icons.delete),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    setState(() {
      students = snap.docs;
    });
  }

  Future<void> loadClasses() async {
    final snap = await FirebaseFirestore.instance.collection('classes').get();

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

  Future<void> saveFees() async {
    if (selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Month select karo")),
      );
      return;
    }

    int amount = getTotalAmount();

    List<Map<String, dynamic>> detailsList = rows.map((r) {
      return {
        "naration": r["naration"]!.text,
        "amount": int.tryParse(r["amount"]!.text) ?? 0,
      };
    }).toList();

    // 🔥 UPDATE MODE (same)
    if (widget.docId != null) {
      await FirebaseFirestore.instance
          .collection('fees')
          .doc(widget.docId)
          .update({
        "month": selectedMonth,
        "amount": amount,
        "details": detailsList,
        "class": selectedClass,
        "status": widget.isReceived ? "paid" : "due",
        "type": widget.isReceived ? "receive" : "add",
      });

      Navigator.pop(context);
      return;
    }

    // 🔥 BATCH START
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // 🔥 CLASS → ALL STUDENTS (FAST)
    if (selectedClass != null && selectedClass!.isNotEmpty) {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();

        if ((data['classSection'] ?? "") == selectedClass) {
          final newDoc = FirebaseFirestore.instance.collection('fees').doc();

          batch.set(newDoc, {
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
          await FirebaseFirestore.instance.collection('notices').add({

            'title': widget.isReceived
                ? "Fees Received"
                : "New Fees Added",

            'message': widget.isReceived

                ? """Your payment of ₹$amount has been received.
Month : $selectedMonth

${detailsList.map((e) =>
            "${e['naration']} - ₹${e['amount']}")
                .join("\n")}

Total : ₹$amount"""

                : """Your fees of ₹$amount has been added.
Month : $selectedMonth

${detailsList.map((e) =>
            "${e['naration']} - ₹${e['amount']}")
                .join("\n")}

Total : ₹$amount""",

            // 🔥 IMPORTANT
            'studentId': doc.id,

            'role': 'private',

            'seenBy': [],

            'time': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit(); // 🔥 EK SAATH SAVE
    }

    // 🔥 SINGLE STUDENT
    else if (selectedStudentId != null) {
      await FirebaseFirestore.instance.collection('fees').add({
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
      await FirebaseFirestore.instance.collection('notices').add({

        'title': widget.isReceived
            ? "Fees Received"
            : "New Fees Added",

        'message': widget.isReceived

            ? """Your payment of ₹$amount has been received.
Month : $selectedMonth

${detailsList.map((e) =>
        "${e['naration']} - ₹${e['amount']}")
            .join("\n")}

Total : ₹$amount"""

            : """Your fees of ₹$amount has been added.
Month : $selectedMonth

${detailsList.map((e) =>
        "${e['naration']} - ₹${e['amount']}")
            .join("\n")}

Total : ₹$amount""",

        'studentId': selectedStudentId ?? "",

        // 🔥 IMPORTANT
        'role': 'private',

        'seenBy': [],

        'time': FieldValue.serverTimestamp(),
      });
      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(selectedStudentId)
          .get();

      if (studentDoc.exists) {
        final studentData = studentDoc.data() as Map<String, dynamic>;

        final studentEmail = studentData['email'] ?? "";

        if (studentEmail.toString().isNotEmpty) {
          await sendEmail(
            toEmail: studentEmail,
            subject:
            widget.isReceived ? "Fees Payment Received" : "New Fees Added",
            body: widget.isReceived
                ? """
    Dear $selectedStudentName,
    
    Your fees payment has been received successfully.
    
    Month: $selectedMonth
    Amount: ₹$amount
    
    Thank You
    SCCR Coaching
    """
                : """
    Dear $selectedStudentName,
    
    New fees has been added to your account.
    
    Month: $selectedMonth
    Amount: ₹$amount
    
    Please pay on time.
    
    Thank You
    SCCR Coaching
    """,
          );
        }
      }
    }

    Navigator.pop(context);
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
              onTap: saveFees,
              child: Container(
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Center(
                  child: Text(
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
    final user = fb.FirebaseAuth.instance.currentUser;

    final stream = FirebaseFirestore.instance
        .collection('fees')
        .where('studentId', isEqualTo: user!.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("My Fees")),
      body: Column(
        children: [
          /// 🔥 TOP
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox();

              final docs = snap.data!.docs;

              double totalDue = 0;
              double totalReceived = 0;

              for (var doc in docs) {
                final d = doc.data() as Map<String, dynamic>;

                final amt =
                    double.tryParse(d['amount']?.toString() ?? "0") ?? 0;

                final status =
                (d['status'] ?? "").toString().toLowerCase().trim();

                if (status == "paid") {
                  totalReceived += amt;
                } else {
                  totalDue += amt;
                }
              }

              final balance = totalDue - totalReceived;

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Total Add"),
                              const SizedBox(height: 6),
                              Text(
                                "₹${totalDue.toStringAsFixed(1)}",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("Received"),
                              const SizedBox(height: 6),
                              Text(
                                "₹${totalReceived.toStringAsFixed(1)}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          Text(
                            "Balance",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "₹${balance.toStringAsFixed(1)}",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          /// 🔽 LIST (SAFE SORT)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List docs = snap.data!.docs;

                /// ✅ LOCAL SORT (NO CRASH)
                docs.sort((a, b) {
                  final aTime =
                  (a.data() as Map<String, dynamic>)['time'] as Timestamp?;
                  final bTime =
                  (b.data() as Map<String, dynamic>)['time'] as Timestamp?;

                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;

                  return bTime.toDate().compareTo(aTime.toDate());
                });

                if (docs.isEmpty) {
                  return const Center(child: Text("No Fees Record Found"));
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final time = d['time'] as Timestamp?;

                    final status =
                    (d['status'] ?? "").toString().toLowerCase().trim();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['month'] ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      "₹${d['amount'] ?? 0}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Text(
                                        formatTime(time),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: status == "paid"
                                  ? Colors.green.withOpacity(0.12)
                                  : Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status == "paid"
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
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
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'admin')
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
                          await FirebaseFirestore.instance
                              .collection('users')
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
      appBar: AppBar(title: Text("Exams")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddExamPage()),
          );
        },
        child: Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('exams')
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
                      // 🔥 USER ROLE CHECK
                      final user = fb.FirebaseAuth.instance.currentUser;

                      if (user != null) {
                        // 🔥 USER ROLE FIRESTORE se lao
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get()
                            .then((doc) {
                          final role = doc.data()?['role'];

                          // 👨‍💼 ADMIN → edit page (same as before)
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
                          }

                          // 🎓 STUDENT → sirf apna result
                          else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultViewPage(
                                  examData: data,
                                ),
                              ),
                            );
                          }
                        });
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

                          // 🗑 DELETE
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
                                          await FirebaseFirestore.instance
                                              .collection('exams')
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
    final snap = await FirebaseFirestore.instance.collection('classes').get();

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
              title: const Text("Choose Class"),
              content: SizedBox(
                width: double.maxFinite,
                child: allClasses.isEmpty
                    ? const Text("Class list empty hai")
                    : ListView(
                  shrinkWrap: true,
                  children: allClasses.map((cls) {
                    return CheckboxListTile(
                      value: selectedClasses.contains(cls),
                      title: Text(cls),
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
                TextButton(
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
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
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
      await FirebaseFirestore.instance
          .collection('exams')
          .doc(widget.docId)
          .update(data);
    } else {
      await FirebaseFirestore.instance.collection('exams').add(data);
    }

    Navigator.pop(context);
  }

  Future<void> generateStudentPdf(Map student) async {
    final pdf = pw.Document();

    final marks = Map<String, dynamic>.from(student['marks'] ?? {});
    final total = student['total'] ?? 0;
    final percent = student['percent'] ?? 0;

    // 🔥 STUDENT PHOTO LOAD
    dynamic studentImage;

    if (student['photo'] != null && student['photo'].toString().isNotEmpty) {
      try {
        studentImage = await networkImage(student['photo']);
      } catch (e) {
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
                // 🔷 SCHOOL HEADER
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    children: [
                      // SCHOOL NAME
                      pw.Text(
                        "SARASWATI SISHU VIDHYA MANDHIR",
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
                                infoRow("Name", student['studentName']),
                                pw.SizedBox(height: 10),
                                infoRow("Father", student['father']),
                                pw.SizedBox(height: 10),
                                infoRow("Mother", student['mother']),
                                pw.SizedBox(height: 10),
                                infoRow("DOB", student['dob']),
                              ],
                            ),
                          ),

                          pw.SizedBox(width: 35),

                          // RIGHT
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                infoRow("Roll No", student['rollNo']),
                                pw.SizedBox(height: 10),
                                infoRow("Adm No", student['admNo']),
                                pw.SizedBox(height: 10),
                                infoRow("Class", student['class']),
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
                    if (studentImage != null)
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
                        child: pw.Image(
                          studentImage,
                          fit: pw.BoxFit.cover,
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

  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text("Add Exam")),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: examNameCtrl,
                      scrollPadding: const EdgeInsets.only(bottom: 180),
                      decoration: InputDecoration(
                        labelText: "Exam Name",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: examCodeCtrl,
                            scrollPadding: const EdgeInsets.only(bottom: 180),
                            decoration:
                            const InputDecoration(labelText: "Exam Code"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: fullMarksCtrl,
                            keyboardType: TextInputType.number,
                            scrollPadding: const EdgeInsets.only(bottom: 180),
                            decoration:
                            const InputDecoration(labelText: "Full Marks"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: openClassDialog,
                          child: const Text("Class"),
                        ),
                      ],
                    ),
                    if (selectedClasses.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: selectedClasses.map((e) {
                            return Container(
                              padding: EdgeInsets.symmetric(
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
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedClasses.remove(e);
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.black54,
                                    ),
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextField(
                      controller: searchCtrl,
                      scrollPadding: const EdgeInsets.only(bottom: 180),
                      decoration: const InputDecoration(
                        labelText: "Search Student",
                        prefixIcon: Icon(Icons.search),
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
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    keyboardBottom > 0 ? keyboardBottom + 140 : 16,
                  ),
                  child: Column(
                    children: List.generate(studentBlocks.length, (i) {
                      var block = studentBlocks[i];

                      if (searchText.isNotEmpty) {
                        String name =
                        (block["studentName"] ?? "").toLowerCase();
                        if (!name.contains(searchText)) {
                          return const SizedBox();
                        }
                      }

                      var result = calculateResult(block["subjects"]);
                      final filteredStudents =
                      getFilteredStudents(block["studentId"]);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),

                          // 🔥 BORDER
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),

                          // 🔥 LIGHT BLUE SHADOW
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.08),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: block["studentId"],
                              hint: const Text("Select Student"),
                              items: filteredStudents.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;

                                String name = data['name'] ?? '';
                                String roll = data['rollNo']?.toString() ?? '';

                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text("$name (Roll: $roll)"),
                                );
                              }).toList(),
                              onChanged: (value) {
                                final d =
                                students.firstWhere((e) => e.id == value);
                                final data = d.data() as Map<String, dynamic>;

                                setState(() {
                                  block["studentId"] = value;
                                  block["studentName"] = data['name'];
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            Column(
                              children: List.generate(
                                block["subjects"].length,
                                    (j) {
                                  var sub = block["subjects"][j];

                                  return Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: sub["name"],
                                          scrollPadding: const EdgeInsets.only(
                                              bottom: 220),
                                          decoration: const InputDecoration(
                                            labelText: "Subject",
                                          ),
                                          onChanged: (_) {
                                            setState(() {
                                              syncSubjectsToAll(i);
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: sub["marks"],
                                          keyboardType: TextInputType.number,
                                          scrollPadding: const EdgeInsets.only(
                                              bottom: 220),
                                          decoration: const InputDecoration(
                                            labelText: "Marks",
                                          ),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => removeSubject(i, j),
                                      )
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Total: ${result['total']}"),
                                Text(
                                  "${result['percent'].toStringAsFixed(1)} %",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => addSubject(i),
                              icon: const Icon(Icons.add),
                              label: const Text("Add Subject"),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.picture_as_pdf,
                                      color: Colors.red),
                                  onPressed: () {
                                    // 🔴 safety check
                                    if (block["studentId"] == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Please select student first")),
                                      );
                                      return;
                                    }

                                    // 🔥 selected student Firestore से निकालो
                                    final selectedDoc = students.firstWhere(
                                          (e) => e.id == block["studentId"],
                                    );

                                    final userData = selectedDoc.data()
                                    as Map<String, dynamic>;

                                    final studentData = {
                                      "studentName": block["studentName"] ?? "",

                                      // 🔥 IMPORTANT (अब auto fill होगा)
                                      "father": userData['fatherName'] ?? "",
                                      "mother": userData['motherName'] ?? "",
                                      "class": userData['classSection'] ?? "",
                                      "rollNo": userData['rollNo'] ?? "",
                                      "admNo": userData['admNo'] ?? "",
                                      "dob": userData['dob'] ?? "",
                                      "photo": userData['photo'],

                                      // 🔥 marks
                                      "marks": {
                                        for (var sub in block["subjects"])
                                          sub["name"].text:
                                          int.tryParse(sub["marks"].text) ??
                                              0
                                      },

                                      "total": result["total"],
                                      "percent": result["percent"],
                                    };

                                    generateStudentPdf(studentData);
                                  },
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => removeStudent(i),
                              child: const Text(
                                "Remove Student",
                                style: TextStyle(color: Colors.red),
                              ),
                            )
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: addStudent,
                          icon: Icon(Icons.person_add_alt_1, size: 18),
                          label: Text(
                            "Add Student",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: saveExam,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 18),
                              SizedBox(width: 6),
                              Text(
                                "Save",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}

class ResultViewPage extends StatelessWidget {
  final Map<String, dynamic> examData;

  ResultViewPage({required this.examData});

  @override
  Widget build(BuildContext context) {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    final students = examData['students'] ?? [];

    // 🔥 STUDENT FILTER
    final myData = students.where((s) {
      return s['studentId'] == uid;
    }).toList();

    final showList = myData.isEmpty ? [] : myData;

    if (showList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Result")),
        body: Center(child: Text("No Result Found")),
      );
    }

    // ✅ FULL MARKS
    int fullMarks = examData['fullMarks'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(examData['examName'] ?? "Result")),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: showList.length,
        itemBuilder: (context, index) {
          final data = showList[index];
          final marks = data['marks'] as Map<String, dynamic>;

          // ✅ TOTAL CALCULATE
          int total = 0;
          marks.forEach((k, v) {
            total += (v as int);
          });

          // ✅ PERCENTAGE
          double percent = fullMarks > 0 ? (total / fullMarks) * 100 : 0;

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👤 NAME
                Text(
                  data['studentName'] ?? "",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 10),

                // 📚 SUBJECT LIST
                Column(
                  children: marks.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key),
                          Text(e.value.toString()),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                Divider(height: 20),

                // 🔥 TOTAL + FULL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total: $total"),
                    Text("Full: $fullMarks"),
                  ],
                ),

                SizedBox(height: 6),

                // 🔥 PERCENTAGE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Percentage",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${percent.toStringAsFixed(1)} %",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
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
        imageQuality: 70,
      );

      if (pickedFiles.isEmpty) return;

      setState(() => isUploading = true);

      for (var pickedFile in pickedFiles) {
        // 🔥 WEB + MOBILE BOTH SUPPORT
        final bytes = await pickedFile.readAsBytes();

        final fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}";

        final ref =
        FirebaseStorage.instance.ref().child("gallery").child(fileName);

        // 🔥 putFile हटाकर putData
        await ref.putData(
          bytes,
          SettableMetadata(
            contentType: "image/jpeg",
          ),
        );

        final imageUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('gallery').add({
          'url': imageUrl,
          'time': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Images Uploaded Successfully"),
        ),
      );
    } catch (e) {
      debugPrint("Upload Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload Failed : $e"),
        ),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> deleteImage(String docId, String imageUrl) async {
    try {
      // 🔥 delete from storage
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();

      // 🔥 delete firestore doc
      await FirebaseFirestore.instance
          .collection('gallery')
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image Deleted"),
        ),
      );
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gallery"),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: isUploading ? null : uploadImages,
        child: isUploading
            ? const CircularProgressIndicator(
          color: Colors.white,
        )
            : const Icon(
          Icons.add_a_photo,
          color: Colors.white,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gallery')
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
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.grey.shade200,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            item['url'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // 🔥 DELETE BUTTON
                      Positioned(
                        top: 8,
                        right: 8,
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
                              size: 18,
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
                  child: Image.network(
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
      final feeSnap = await FirebaseFirestore.instance.collection('fees').get();
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
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
                      "SARASWATI COACHING CENTER RANIGANJ",
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
                            final usersSnap = await FirebaseFirestore.instance
                                .collection('users')
                                .where('role', isEqualTo: 'student')
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
                  FirebaseFirestore.instance.collection('fees').snapshots(),
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
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('role', isEqualTo: 'student')
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

  @override
  void initState() {
    super.initState();
    loadRole();
  }

  void loadRole() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(fb.FirebaseAuth.instance.currentUser!.uid)
        .get();

    setState(() {
      userRole = doc.data()?['role'] ?? "";
    });
  }

  void clearFields() {
    headingController.clear();
    descController.clear();
    linkController.clear();
    selectedClasses.clear();
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
      await FirebaseFirestore.instance.collection("pdfs").doc(id).delete();
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
                        stream: FirebaseFirestore.instance
                            .collection("classes")
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
                      SizedBox(height: 12),
                      TextField(
                        controller: linkController,
                        decoration: InputDecoration(
                          labelText: "PDF Link",
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
                                  await FirebaseFirestore.instance
                                      .collection("pdfs")
                                      .add({
                                    "heading": headingController.text,
                                    "desc": descController.text,
                                    "classes": selectedClasses,
                                    "link": linkController.text,
                                    "time": FieldValue.serverTimestamp(),
                                  });
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection("pdfs")
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
        title: Text("PDF Section"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: userRole == "student"
          ? null
          : FloatingActionButton(
        onPressed: () => showAddDialog(),
        child: Icon(Icons.add),
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
              stream: FirebaseFirestore.instance
                  .collection("pdfs")
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

  void loadRole() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(fb.FirebaseAuth.instance.currentUser!.uid)
        .get();

    setState(() {
      userRole = doc.data()?['role'] ?? "";
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
      await FirebaseFirestore.instance.collection("videos").doc(id).delete();
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
                        stream: FirebaseFirestore.instance
                            .collection("classes")
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
                                  await FirebaseFirestore.instance
                                      .collection("videos")
                                      .add({
                                    "heading": headingController.text,
                                    "desc": descController.text,
                                    "classes": selectedClasses,
                                    "link": linkController.text,
                                    "time": FieldValue.serverTimestamp(),
                                  });
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection("videos")
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
        title: Text("Video Section"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      // 🔥 ONLY CHANGE (add hide)
      floatingActionButton: userRole == "student"
          ? null
          : FloatingActionButton(
        onPressed: () => showAddDialog(),
        child: Icon(Icons.add),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("videos")
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
      final snap = await FirebaseFirestore.instance
          .collection('fees')
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
                      "SARASWATI COACHING CENTER RANIGANJ",
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
      appBar: AppBar(
        title: Text(studentName),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () => exportPdf(context),
          )
        ],
      ),

      // 🔽 LIST SAME AS BEFORE
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fees')
            .where('studentId', isEqualTo: studentId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return Center(child: Text("No Data"));
          }

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;

                  double amount =
                      double.tryParse(data['amount'].toString()) ?? 0;

                  String type = (data['type'] ?? "").toString().toLowerCase();

                  DateTime? date;
                  if (data['time'] != null) {
                    date = (data['time'] as Timestamp).toDate();
                  }

                  return Container(
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Month: ${data['month'] ?? ""}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                date != null
                                    ? "${date.day}/${date.month}/${date.year}"
                                    : "",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "₹$amount",
                          style: TextStyle(
                            color: type == "add" ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
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

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snap.docs.isEmpty) {

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

      final data = snap.docs.first.data();

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
SCCR Coaching
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
