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
      'incorrect_password': 'ពាក្យសម្ងាត់មិនត្រឹមត្រូវ។ សូមព្យាយាមម្តងទៀត',
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

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? errorText,
    required bool isDark,
    required Map<String, String> lang,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null
                  ? Colors.red
                  : isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? _obscurePassword : false,
            keyboardType: keyboardType,
            onChanged: (value) {
              if (errorText != null) {
                setState(() {
                  if (controller == emailController) emailError = null;
                  if (controller == passwordController) passwordError = null;
                });
              }
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 18,
              ),
              prefixIcon: Icon(
                icon,
                color: errorText != null
                    ? Colors.red
                    : isDark
                        ? Colors.white70
                        : Colors.deepPurple.shade400,
                size: 28,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              hintText: label,
              hintStyle: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white70 : Colors.deepPurple.shade400,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
            style: TextStyle(
              fontSize: 18,
              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ),
      ],
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
                height: 150,
                width: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
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
              padding: const EdgeInsets.all(28.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Circular logo container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: Image.asset(
                          'assets/logo/app_logo.png',
                          height: 50,
                          width: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.restaurant_menu,
                              size: 40,
                              color: isDark ? Colors.white : Colors.deepPurple,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(30),
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
                                  fontSize: 24,
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
                          const SizedBox(height: 30),
                          if (generalError != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                generalError!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 16,
                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                              ),
                            ),
                          _buildStyledTextField(
                            controller: emailController,
                            label: lang['email']!,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            errorText: emailError,
                            isDark: isDark,
                            lang: lang,
                          ),
                          const SizedBox(height: 25),
                          _buildStyledTextField(
                            controller: passwordController,
                            label: lang['password']!,
                            icon: Icons.lock_outline,
                            isPassword: true,
                            errorText: passwordError,
                            isDark: isDark,
                            lang: lang,
                          ),
                          const SizedBox(height: 35),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : loginUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 5,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    )
                                  : Text(
                                      lang['sign_in']!,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          LayoutBuilder(
                            builder: (context, constraints) {
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
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      lang['no_account']!,
                                      style: getTextStyle(),
                                    ),
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
                                          fontSize: 18,
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