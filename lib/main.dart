import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey:            "AIzaSyD9fElRB4NHtU4RVVPmTCbuaeol8HqD2vw",
      authDomain:        "febryalvian-26f60.firebaseapp.com",
      projectId:         "febryalvian-26f60",
      storageBucket:     "febryalvian-26f60.firebasestorage.app",
      messagingSenderId: "56764412424",
      appId:             "1:56764412424:web:d585c8d6253cd69b8fd7bd",
      measurementId:     "G-0SXESBPCH5",
    ),
  );
  runApp(const SpaceNewsCoreApp());
}

// ─────────────────────────────────────────────────
// ROOT APP
// ─────────────────────────────────────────────────
class SpaceNewsCoreApp extends StatelessWidget {
  const SpaceNewsCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpaceNews Core',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A1628),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0A1628),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1628),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────
class Article {
  final int id;
  final String title;
  final String url;
  final String imageUrl;
  final String newsSite;
  final String summary;
  final String publishedAt;

  Article({
    required this.id,
    required this.title,
    required this.url,
    required this.imageUrl,
    required this.newsSite,
    required this.summary,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['image_url'] ?? '',
      newsSite: json['news_site'] ?? '',
      summary: json['summary'] ?? '',
      publishedAt: json['published_at'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────────
// COLORS & THEME CONSTANTS
// ─────────────────────────────────────────────────
const kBgDark = Color(0xFF0A1628);
const kBgCard = Color(0xFF112240);
const kAccent = Color(0xFF64FFDA);
const kAccentOrange = Color(0xFFFF6B35);
const kTextLight = Color(0xFFCCD6F6);
const kTextMuted = Color(0xFF8892B0);

// ─────────────────────────────────────────────────
// 1. SPLASH SCREEN
// ─────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), _navigate);
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (!mounted) return;

    if (isLoggedIn && FirebaseAuth.instance.currentUser != null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainShell()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const RegisterPage()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder (replace with your Freepik asset)
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: kBgCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: kAccent.withOpacity(0.3),
                        blurRadius: 24,
                        spreadRadius: 2)
                  ],
                ),
                child: const Icon(Icons.rocket_launch_rounded,
                    color: kAccent, size: 56),
              ),
              const SizedBox(height: 24),
              const Text(
                'SpaceNews Core',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Advanced International News Portal',
                  style: TextStyle(color: kTextMuted, fontSize: 13)),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kAccent)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 2. REGISTER PAGE
// ─────────────────────────────────────────────────
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'instagram': '',
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const WelcomePage()));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kAccent, width: 1.5),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded,
                      color: kAccent, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('Buat Akun Baru',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              const Center(
                  child: Text('Bergabung dengan SpaceNews Core',
                      style: TextStyle(color: kTextMuted, fontSize: 13))),
              const SizedBox(height: 32),
              _buildField('Nama Lengkap', _nameCtrl, Icons.person_outline),
              const SizedBox(height: 16),
              _buildField('Email', _emailCtrl, Icons.email_outlined,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildPasswordField(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(kAccent)))
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        foregroundColor: kBgDark,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      child: const Text('Daftar'),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginPage())),
                child: const Text('Apakah sudah punya akun? Login',
                    style: TextStyle(color: kAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextMuted),
        prefixIcon: Icon(icon, color: kAccent),
        filled: true,
        fillColor: kBgCard,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAccent)),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordCtrl,
      obscureText: _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(color: kTextMuted),
        prefixIcon: const Icon(Icons.lock_outline, color: kAccent),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
              color: kTextMuted),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: true,
        fillColor: kBgCard,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAccent)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 3. FORGOT PASSWORD PAGE
// ─────────────────────────────────────────────────
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _send() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailCtrl.text.trim());
      setState(() {
        _isSuccess = true;
        _message = 'Link reset password telah dikirim ke email Anda.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isSuccess = false;
        _message = e.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(title: const Text('Lupa Password')),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.lock_reset, color: kAccent, size: 72),
            const SizedBox(height: 24),
            const Text('Reset Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Masukkan email Anda dan kami akan mengirimkan link reset password.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextMuted, fontSize: 13)),
            const SizedBox(height: 32),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: kTextMuted),
                prefixIcon: const Icon(Icons.email_outlined, color: kAccent),
                filled: true,
                fillColor: kBgCard,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kAccent)),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!,
                  style: TextStyle(
                      color: _isSuccess ? kAccent : Colors.redAccent,
                      fontSize: 13),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(kAccent)))
                : ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: kBgDark,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Send to email',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 4. LOGIN PAGE
// ─────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const WelcomePage()));
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kAccent, width: 1.5),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded,
                      color: kAccent, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('Selamat Datang Kembali',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              const Center(
                  child: Text('Masuk ke akun SpaceNews Core Anda',
                      style: TextStyle(color: kTextMuted, fontSize: 13))),
              const SizedBox(height: 36),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: kTextMuted),
                  prefixIcon:
                      const Icon(Icons.email_outlined, color: kAccent),
                  filled: true,
                  fillColor: kBgCard,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kAccent)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: kTextMuted),
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: kAccent),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: kTextMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: kBgCard,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kAccent)),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage())),
                  child: const Text('Forgot Password?',
                      style: TextStyle(color: kAccent, fontSize: 13)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(kAccent)))
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        foregroundColor: kBgDark,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      child: const Text('Login'),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Belum punya akun? Daftar',
                    style: TextStyle(color: kAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 5. WELCOME PAGE
// ─────────────────────────────────────────────────
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Online illustration image
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    'https://img.freepik.com/free-vector/journalist-concept-illustration_114360-1649.jpg',
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.newspaper,
                          size: 80, color: kAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Welcome to SpaceNews Core Application',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sumber berita luar angkasa terpercaya dari seluruh dunia, langsung di genggaman Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextMuted, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const MainShell())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: kBgDark,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    child: const Text('Mulai Sekarang →'),
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

// ─────────────────────────────────────────────────
// 6. MAIN SHELL (BottomNavigationBar)
// ─────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    FavoritePage(),
    NotificationPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: kBgCard,
        selectedItemColor: kAccent,
        unselectedItemColor: kTextMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded), label: 'Favorite'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_rounded),
              label: 'Notification'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 7. HOME PAGE
// ─────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Article> _articles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    try {
      final res = await http.get(Uri.parse(
          'https://api.spaceflightnewsapi.net/v4/articles/?limit=20'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = data['results'] as List;
        setState(() {
          _articles = results.map((e) => Article.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat berita.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Tidak ada koneksi internet.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, color: kAccent, size: 22),
            const SizedBox(width: 8),
            const Text('SpaceNews Core',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: kAccent),
            onPressed: () {
              setState(() => _loading = true);
              _fetchArticles();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kAccent)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: kTextMuted, size: 64),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: const TextStyle(color: kTextMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: () {
                            setState(() => _loading = true);
                            _fetchArticles();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kAccent,
                              foregroundColor: kBgDark),
                          child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: kAccent,
                  onRefresh: _fetchArticles,
                  child: CustomScrollView(
                    slivers: [
                      // ── Headline Banner ──
                      if (_articles.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _HeadlineBanner(article: _articles.first),
                        ),
                      // ── Section title ──
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text('Berita Terbaru',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      // ── News List ──
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final article = _articles[i + 1];
                            return _NewsCard(article: article);
                          },
                          childCount:
                              (_articles.length - 1).clamp(0, _articles.length),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                ),
    );
  }
}

class _HeadlineBanner extends StatelessWidget {
  final Article article;
  const _HeadlineBanner({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailPage(article: article))),
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: kBgCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              article.imageUrl.isNotEmpty
                  ? Image.network(article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: kBgCard,
                            child: const Icon(Icons.broken_image,
                                color: kTextMuted, size: 48),
                          ))
                  : Container(
                      color: kBgCard,
                      child:
                          const Icon(Icons.newspaper, color: kAccent, size: 48)),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      kBgDark.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
              // Label & title
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kAccentOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('HEADLINE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    Text(article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(article.newsSite,
                        style: const TextStyle(
                            color: kAccent, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Article article;
  const _NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailPage(article: article))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: article.imageUrl.isNotEmpty
                  ? Image.network(article.imageUrl,
                      width: 90,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            width: 90,
                            height: 80,
                            color: kBgDark,
                            child: const Icon(Icons.broken_image,
                                color: kTextMuted),
                          ))
                  : Container(
                      width: 90,
                      height: 80,
                      color: kBgDark,
                      child:
                          const Icon(Icons.newspaper, color: kAccent)),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.newsSite,
                      style:
                          const TextStyle(color: kAccent, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3)),
                  const SizedBox(height: 6),
                  Text(
                    article.publishedAt.length >= 10
                        ? article.publishedAt.substring(0, 10)
                        : '',
                    style: const TextStyle(color: kTextMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 8. DETAIL PAGE
// ─────────────────────────────────────────────────
class DetailPage extends StatefulWidget {
  final Article article;
  const DetailPage({super.key, required this.article});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isFavorite = false;
  bool _savingFav = false;

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _savingFav = true);

    final docRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc('${user.uid}_${widget.article.id}');

    if (_isFavorite) {
      await docRef.delete();
      setState(() => _isFavorite = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Dihapus dari favorit'),
              backgroundColor: kBgCard),
        );
      }
    } else {
      await docRef.set({
        'articleId': widget.article.id,
        'title': widget.article.title,
        'imageUrl': widget.article.imageUrl,
        'newsSite': widget.article.newsSite,
        'summary': widget.article.summary,
        'publishedAt': widget.article.publishedAt,
        'userId': user.uid,
        'savedAt': FieldValue.serverTimestamp(),
      });
      setState(() => _isFavorite = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Ditambahkan ke favorit!'),
              backgroundColor: kBgCard),
        );
      }
    }
    setState(() => _savingFav = false);
  }

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('favorites')
        .doc('${user.uid}_${widget.article.id}')
        .get();
    if (mounted) setState(() => _isFavorite = doc.exists);
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text('Detail Artikel',
            style: TextStyle(color: Colors.white)),
        actions: [
          _savingFav
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(kAccent))),
                )
              : IconButton(
                  icon: Icon(
                      _isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          _isFavorite ? Colors.redAccent : Colors.white),
                  onPressed: _toggleFavorite,
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            article.imageUrl.isNotEmpty
                ? Image.network(
                    article.imageUrl,
                    width: double.infinity,
                    height: 230,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          height: 230,
                          color: kBgCard,
                          child: const Icon(Icons.broken_image,
                              color: kTextMuted, size: 64),
                        ),
                  )
                : Container(
                    height: 230,
                    color: kBgCard,
                    child: const Center(
                        child: Icon(Icons.newspaper,
                            color: kAccent, size: 64)),
                  ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Publisher badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: kAccent.withOpacity(0.4)),
                    ),
                    child: Text(article.newsSite,
                        style: const TextStyle(
                            color: kAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 14),
                  // Title
                  Text(article.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.4)),
                  const SizedBox(height: 10),
                  // Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: kTextMuted, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        article.publishedAt.length >= 10
                            ? article.publishedAt.substring(0, 10)
                            : article.publishedAt,
                        style: const TextStyle(
                            color: kTextMuted, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: kBgCard, thickness: 1.5),
                  const SizedBox(height: 16),
                  // Summary
                  const Text('Ringkasan',
                      style: TextStyle(
                          color: kAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(article.summary,
                      style: const TextStyle(
                          color: kTextLight,
                          fontSize: 15,
                          height: 1.7)),
                  const SizedBox(height: 24),
                  // Read full article button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Open URL in browser (add url_launcher package)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Buka: ${article.url}'),
                              backgroundColor: kBgCard),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kAccent,
                        side: const BorderSide(color: kAccent),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Baca Artikel Lengkap'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// 9. FAVORITE PAGE
// ─────────────────────────────────────────────────
class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: const Text('Favorit Saya',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: user == null
          ? const Center(
              child: Text('Silakan login terlebih dahulu',
                  style: TextStyle(color: kTextMuted)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
    .collection('favorites')
    .where('userId', isEqualTo: user.uid)
    .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(kAccent)));
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border,
                            color: kTextMuted, size: 64),
                        SizedBox(height: 16),
                        Text('Belum ada artikel favorit',
                            style: TextStyle(
                                color: kTextMuted, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Tekan ikon hati di halaman artikel\nuntuk menyimpan',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: kTextMuted, fontSize: 13)),
                      ],
                    ),
                  );
                }

                final docs = snap.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final article = Article(
                      id: data['articleId'] ?? 0,
                      title: data['title'] ?? '',
                      url: '',
                      imageUrl: data['imageUrl'] ?? '',
                      newsSite: data['newsSite'] ?? '',
                      summary: data['summary'] ?? '',
                      publishedAt: data['publishedAt'] ?? '',
                    );
                    return _NewsCard(article: article);
                  },
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────
// 10. NOTIFICATION PAGE
// ─────────────────────────────────────────────────
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  // Sample notification data
  static final _notifications = [
    {
      'icon': Icons.rocket_launch,
      'color': kAccent,
      'title': 'Berita Baru Tersedia',
      'body': 'Artikel terbaru dari SpaceX telah dipublikasikan.',
      'time': '2 menit lalu',
    },
    {
      'icon': Icons.satellite_alt,
      'color': Color(0xFFFFD700),
      'title': 'Pembaruan Misi ISS',
      'body': 'Laporan terbaru dari Stasiun Luar Angkasa Internasional.',
      'time': '1 jam lalu',
    },
    {
      'icon': Icons.public,
      'color': kAccentOrange,
      'title': 'NASA Mengumumkan Misi Baru',
      'body': 'NASA berencana meluncurkan misi ke Mars tahun depan.',
      'time': '3 jam lalu',
    },
    {
      'icon': Icons.star,
      'color': Color(0xFF8A2BE2),
      'title': 'Artikel Favorit Diperbarui',
      'body': 'Artikel yang Anda simpan telah mendapat pembaruan.',
      'time': '5 jam lalu',
    },
    {
      'icon': Icons.notifications_active,
      'color': Colors.blueAccent,
      'title': 'Selamat Datang!',
      'body': 'Terima kasih telah bergabung dengan SpaceNews Core.',
      'time': '1 hari lalu',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: const Text('Notifikasi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Tandai semua dibaca',
                style: TextStyle(color: kAccent, fontSize: 12)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final n = _notifications[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(14),
              border: i == 0
                  ? Border.all(color: kAccent.withOpacity(0.4))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (n['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(n['icon'] as IconData,
                      color: n['color'] as Color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(n['title'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          if (i == 0)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: kAccent,
                                  shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n['body'] as String,
                          style: const TextStyle(
                              color: kTextMuted, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 6),
                      Text(n['time'] as String,
                          style: const TextStyle(
                              color: kTextMuted, fontSize: 11)),
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
}

// ─────────────────────────────────────────────────
// 11. PROFILE PAGE
// ─────────────────────────────────────────────────
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (mounted) {
      setState(() {
        _userData = doc.data();
        _loading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBgCard,
        title: const Text('Log Out',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Apakah Anda yakin ingin keluar dari akun ini?',
            style: TextStyle(color: kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Batal', style: TextStyle(color: kTextMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kAccent)));
    }

    final name = _userData?['name'] ?? user?.displayName ?? 'Pengguna';
    final email = _userData?['email'] ?? user?.email ?? '-';
    final instagram = _userData?['instagram'] ?? '-';
    final photoUrl = _userData?['photoUrl'] ?? user?.photoURL ?? '';

    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: const Text('Profil Saya',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Profile photo
            CircleAvatar(
              radius: 56,
              backgroundColor: kBgCard,
              backgroundImage:
                  photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: kAccent,
                          fontSize: 36,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(email,
                style: const TextStyle(color: kTextMuted, fontSize: 14)),
            const SizedBox(height: 32),
            // Info cards
            _buildInfoCard(Icons.person_outline, 'Nama Lengkap', name),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.email_outlined, 'Email', email),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.camera_alt_outlined, 'Instagram', instagram),
            const SizedBox(height: 36),
            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: kAccent, size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: kTextMuted, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}