import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_services.dart';
import 'register_screen.dart';
import '../taskbar_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  const LoginScreen({super.key, required this.onThemeToggle});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? emailError;
  String? passwordError;
  String? generalError;
  bool _obscurePassword = true;
  String selectedLanguage = 'English'; // Default value

  final Map<String, Map<String, String>> localization = {
    'English': {
      'app_title': 'QR Menu App',
      'welcome_back': 'Welcome Back',
      'sign_in_to_account': 'Sign in to your account',
      'email': 'Email',
      'email_required': 'Email is required',
      'valid_email': 'Please enter a valid email address',
      'password': 'Password',
      'password_required': 'Password is required',
      'password_length': 'Password must be at least 6 characters',
      'forgot_password': 'Forgot Password?',
      'sign_in': 'Sign In',
      'or_continue_with': 'Or continue with',
      'google': 'Google',
      'apple': 'Apple',
      'no_account': 'Don\'t have an account?',
      'create_account': 'Create account',
      'email_not_found': 'Email not found. Please check or register',
      'incorrect_password': 'Incorrect password. Please try again',
      'account_locked': 'Account locked. Try again later or reset password',
      'login_failed': 'Login failed. Please try again',
    },
    'Khmer': {
      'app_title': 'កម្មវិធីម៉ឺនុយ QR',
      'welcome_back': 'សូមស្វាគមន៍មកកាន់វិញ',
      'sign_in_to_account': 'ចូលក្នុងគណនីរបស់អ្នក',
      'email': 'អ៊ីមែល',
      'email_required': 'អ៊ីមែលត្រូវបានទាមទារ',
      'valid_email': 'សូមបញ្ចូលអាសយដ្ឋានអ៊ីមែលដែលត្រឹមត្រូវ',
      'password': 'ពាក្យសម្ងាត់',
      'password_required': 'ពាក្យសម្ងាត់ត្រូវបានទាមទារ',
      'password_length': 'ពាក្យសម្ងាត់ត្រូវតែមានយ៉ាងហោចណាស់ ៦ តួអក្សរ',
      'forgot_password': 'ភ្លេចពាក្យសម្ងាត់?',
      'sign_in': 'ចូល',
      'or_continue_with': 'ឬបន្តជាមួយ',
      'google': 'Google',
      'apple': 'Apple',
      'no_account': 'មិនមានគណនី?',
      'create_account': 'បង្កើតគណនី',
      'email_not_found': 'រកមិនឃើញអ៊ីមែល។ សូមពិនិត្យ ឬចុះឈ្មោះ',
      'incorrect_password': 'ពាក្យសម្ងាត់មិនត្រឹមត្រូវ។ �សូមព្យាយាមម្តងទៀត',
      'account_locked': 'គណនីត្រូវបានចាក់សោ។ សូមព្យាយាមម្តងទៀតនៅពេលក្រោយ ឬកំណត់ពាក្យសម្ងាត់ឡើងវិញ',
      'login_failed': 'ការចូលបរាជ័យ។ សូមព្យាយាមម្តងទៀត',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage(); // Load saved language on initialization
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      selectedLanguage = savedLanguage;
    });
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  bool validateForm() {
    setState(() {
      emailError = null;
      passwordError = null;
      generalError = null;
    });

    bool isValid = true;
    final lang = localization[selectedLanguage]!;

    if (emailController.text.trim().isEmpty) {
      setState(() {
        emailError = lang['email_required'];
      });
      isValid = false;
    } else if (!isValidEmail(emailController.text.trim())) {
      setState(() {
        emailError = lang['valid_email'];
      });
      isValid = false;
    }

    if (passwordController.text.isEmpty) {
      setState(() {
        passwordError = lang['password_required'];
      });
      isValid = false;
    } else if (!isValidPassword(passwordController.text)) {
      setState(() {
        passwordError = lang['password_length'];
      });
      isValid = false;
    }

    return isValid;
  }

  void loginUser() async {
    if (!validateForm()) return;

    setState(() {
      isLoading = true;
      emailError = null;
      passwordError = null;
      generalError = null;
    });

    try {
      final response = await ApiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      final user = response['user'];
      final token = response['token'] as String;

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MenuScreen(onThemeToggle: widget.onThemeToggle),
          ),
        );
      }
    } catch (e) {
      final lang = localization[selectedLanguage]!;
      String errorMessage = e.toString();
      
      if (errorMessage.contains("No account found with this email address")) {
        setState(() {
          emailError = lang['email_not_found'];
          passwordError = null;
        });
      } else if (errorMessage.contains("Invalid password") || 
                 errorMessage.contains("Incorrect password")) {
        setState(() {
          passwordError = lang['incorrect_password'];
          emailError = null;
        });
      } else if (errorMessage.contains("account is locked") || 
                 errorMessage.contains("too many attempts")) {
        setState(() {
          passwordError = lang['account_locked'];
        });
      } else {
        setState(() {
          generalError = lang['login_failed'];
        });
      }
    } finally {
      if (context.mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  TextStyle getTextStyle({bool isSubtitle = false, bool isGray = false}) {
    return TextStyle(
      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
      fontSize: isSubtitle ? 14 : 16,
      color: isGray
          ? Theme.of(context).textTheme.bodyMedium!.color
          : isSubtitle
              ? Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7)
              : Theme.of(context).textTheme.bodyLarge!.color,
      fontWeight: isSubtitle ? FontWeight.w400 : FontWeight.w600,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = localization[selectedLanguage]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          ClipPath(
            clipper: TopWaveClipper(),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade600,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: ClipPath(
              clipper: BottomLeftWaveClipper(),
              child: Container(
                height: 120,
                width: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.deepPurple.shade200.withOpacity(0.3),
                      Colors.deepPurple.shade300.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        lang['app_title']!,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.deepPurple,
                              letterSpacing: 1.2,
                              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            lang['welcome_back']!,
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.deepPurple,
                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            lang['sign_in_to_account']!,
                            style: getTextStyle(),
                          ),
                          const SizedBox(height: 24),
                          if (generalError != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                generalError!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          _buildEmailField(isDark, lang),
                          const SizedBox(height: 16),
                          _buildPasswordField(isDark, lang),
                          
                          const SizedBox(height: 16),
                          // Larger Sign In button
                          SizedBox(
                            width: double.infinity,
                            height: 60, // Increased height
                            child: ElevatedButton(
                              onPressed: isLoading ? null : loginUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                padding: const EdgeInsets.symmetric(vertical: 18), // Increased padding
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      lang['sign_in']!,
                                      style: TextStyle(
                                        fontSize: 24, // Larger font
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Account creation section - made responsive
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // For small screens, use a column layout
                              if (constraints.maxWidth < 400) {
                                return Column(
                                  children: [
                                    Text(
                                      lang['no_account']!,
                                      style: getTextStyle(),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RegisterScreen(
                                              onThemeToggle: widget.onThemeToggle,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        lang['create_account']!,
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.deepPurple,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              // For larger screens, use a row layout
                              else {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      lang['no_account']!,
                                      style: getTextStyle(),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RegisterScreen(
                                              onThemeToggle: widget.onThemeToggle,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        lang['create_account']!,
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.deepPurple,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(bool isDark, Map<String, String> lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: passwordError != null
                  ? Colors.red.shade400
                  : isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade200,
              width: passwordError != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: passwordController,
            obscureText: _obscurePassword,
            onChanged: (value) {
              if (passwordError != null) {
                setState(() {
                  passwordError = null;
                });
              }
            },
            decoration: InputDecoration(
              labelText: lang['password'],
              labelStyle: TextStyle(
                color: passwordError != null
                    ? Colors.red.shade400
                    : isDark
                        ? Colors.white70
                        : Colors.deepPurple.shade400,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: passwordError != null
                    ? Colors.red.shade400
                    : isDark
                        ? Colors.white70
                        : Colors.deepPurple.shade400,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              errorStyle: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
              ),
            ),
            style: getTextStyle(),
          ),
        ),
        if (passwordError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              passwordError!,
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmailField(bool isDark, Map<String, String> lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: emailError != null
                  ? Colors.red.shade400
                  : isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade200,
              width: emailError != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              if (emailError != null) {
                setState(() {
                  emailError = null;
                });
              }
            },
            decoration: InputDecoration(
              labelText: lang['email'],
              labelStyle: TextStyle(
                color: emailError != null
                    ? Colors.red.shade400
                    : isDark
                        ? Colors.white70
                        : Colors.deepPurple.shade400,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: emailError != null
                    ? Colors.red.shade400
                    : isDark
                        ? Colors.white70
                        : Colors.deepPurple.shade400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              errorStyle: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
              ),
            ),
            style: getTextStyle(),
          ),
        ),
        if (emailError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              emailError!,
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ),
      ],
    );
  }
}

class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomLeftWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(size.width, 30);
    var firstControlPoint = Offset(size.width * 2 / 3, 0);
    var firstEndPoint = Offset(size.width / 2, 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    var secondControlPoint = Offset(size.width / 4, 40);
    var secondEndPoint = Offset(0, 10);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}