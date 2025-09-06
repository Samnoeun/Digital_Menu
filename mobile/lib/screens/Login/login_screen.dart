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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? emailError;
  String? passwordError;
  String? generalError;
  bool _obscurePassword = true;
  String selectedLanguage = 'English';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _loadSavedLanguage();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MenuScreen(onThemeToggle: widget.onThemeToggle),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
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
          AnimatedBackground(isDark: isDark),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800.withOpacity(0.8) : Colors.white.withOpacity(0.9),
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
                        ),
                        const SizedBox(height: 40),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800.withOpacity(0.9) : Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
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
                                  style: getTextStyle(isSubtitle: true),
                                ),
                                const SizedBox(height: 24),
                                if (generalError != null)
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Container(
                                      key: ValueKey<String>(generalError!),
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
                                  ),
                                _buildEmailField(isDark, lang),
                                const SizedBox(height: 16),
                                _buildPasswordField(isDark, lang),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      _showForgotPasswordDialog(context, lang);
                                    },
                                    child: Text(
                                      lang['forgot_password']!,
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.deepPurple.shade600,
                                        fontSize: 14,
                                        fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: LinearGradient(
                                        colors: isLoading
                                            ? [Colors.grey.shade400, Colors.grey.shade600]
                                            : [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: isLoading
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: Colors.deepPurple.withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(15),
                                        onTap: isLoading ? null : loginUser,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            AnimatedOpacity(
                                              opacity: isLoading ? 0 : 1,
                                              duration: const Duration(milliseconds: 200),
                                              child: Text(
                                                lang['sign_in']!,
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                                ),
                                              ),
                                            ),
                                            if (isLoading)
                                              const CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                lang['no_account']!,
                                style: getTextStyle(),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => RegisterScreen(
                                        onThemeToggle: widget.onThemeToggle,
                                      ),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOut;
                                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                                  foregroundColor: isDark ? Colors.white : Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  lang['create_account']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context, Map<String, String> lang) {
    TextEditingController emailResetController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            lang['forgot_password']!,
            style: TextStyle(
              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
            ),
          ),
          content: TextField(
            controller: emailResetController,
            decoration: InputDecoration(
              labelText: lang['email'],
              hintText: 'Enter your email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Password reset instructions sent to ${emailResetController.text}',
                      style: TextStyle(
                        fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(
                'Send Reset Link',
                style: TextStyle(
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ),
          ],
        );
      },
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
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
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    key: ValueKey<bool>(_obscurePassword),
                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                  ),
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
            style: TextStyle(
              color: Colors.black,
              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
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
            style: TextStyle(
              color: Colors.black,
              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
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

class AnimatedBackground extends StatelessWidget {
  final bool isDark;

  const AnimatedBackground({Key? key, required this.isDark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.deepPurple.shade900,
                      Colors.indigo.shade900,
                    ]
                  : [
                      Colors.deepPurple.shade100,
                      Colors.indigo.shade100,
                      Colors.blue.shade100,
                    ],
            ),
          ),
        ),
        // Left and top side
        _AnimatedIcon(
          icon: Icons.local_dining,
          size: 60,
          top: 50,
          left: 20,
          duration: const Duration(seconds: 6),
          color: isDark ? Colors.brown.shade300.withOpacity(0.3) : Colors.brown.shade200.withOpacity(0.4),
        ),
        _AnimatedIcon(
          icon: Icons.cake,
          size: 55,
          top: 150,
          left: 60,
          duration: const Duration(seconds: 7),
          color: isDark ? Colors.pink.shade300.withOpacity(0.3) : Colors.pink.shade200.withOpacity(0.4),
        ),
        _AnimatedIcon(
          icon: Icons.fastfood,
          size: 50,
          top: 250,
          left: 30,
          duration: const Duration(seconds: 8),
          color: isDark ? Colors.red.shade300.withOpacity(0.3) : Colors.red.shade200.withOpacity(0.4),
        ),
        // Right side
        _AnimatedIcon(
          icon: Icons.local_pizza,
          size: 60,
          top: 100,
          left: 280,
          duration: const Duration(seconds: 6),
          color: isDark ? Colors.orange.shade300.withOpacity(0.3) : Colors.orange.shade200.withOpacity(0.4),
        ),
        _AnimatedIcon(
          icon: Icons.lunch_dining,
          size: 50,
          top: 200,
          left: 300,
          duration: const Duration(seconds: 7),
          color: isDark ? Colors.yellow.shade300.withOpacity(0.3) : Colors.yellow.shade200.withOpacity(0.4),
        ),
        _AnimatedIcon(
          icon: Icons.restaurant_menu,
          size: 55,
          top: 300,
          left: 260,
          duration: const Duration(seconds: 8),
          color: isDark ? Colors.teal.shade300.withOpacity(0.3) : Colors.teal.shade200.withOpacity(0.4),
        ),
        // Bottom side
        _AnimatedIcon(
          icon: Icons.local_cafe,
          size: 50,
          top: 450,
          left: 80,
          duration: const Duration(seconds: 7),
          color: isDark ? Colors.amber.shade300.withOpacity(0.3) : Colors.amber.shade200.withOpacity(0.4),
        ),
        _AnimatedIcon(
          icon: Icons.rice_bowl,
          size: 55,
          top: 500,
          left: 150,
          duration: const Duration(seconds: 9),
          color: isDark ? Colors.green.shade300.withOpacity(0.3) : Colors.green.shade200.withOpacity(0.4),
        ),
        _AnimatedIcon(
          icon: Icons.icecream,
          size: 45,
          top: 480,
          left: 220,
          duration: const Duration(seconds: 8),
          color: isDark ? Colors.purple.shade300.withOpacity(0.3) : Colors.purple.shade200.withOpacity(0.4),
        ),
        // Bottom-right
        _AnimatedIcon(
          icon: Icons.flatware,
          size: 50,
          top: 460,
          left: 300,
          duration: const Duration(seconds: 7),
          color: isDark ? Colors.grey.shade300.withOpacity(0.3) : Colors.grey.shade400.withOpacity(0.4),
        ),
        _AnimatedIcon(
          icon: Icons.local_bar,
          size: 55,
          top: 500,
          left: 260,
          duration: const Duration(seconds: 9),
          color: isDark ? Colors.blue.shade300.withOpacity(0.3) : Colors.blue.shade200.withOpacity(0.4),
        ),
        _AnimatedIcon(
          icon: Icons.restaurant,
          size: 50,
          top: 480,
          left: 320,
          duration: const Duration(seconds: 8),
          color: isDark ? Colors.cyan.shade300.withOpacity(0.3) : Colors.cyan.shade200.withOpacity(0.4),
        ),
      ],
    );
  }
}

class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final double top;
  final double left;
  final Duration duration;
  final Color color;

  const _AnimatedIcon({
    required this.icon,
    required this.size,
    required this.top,
    required this.left,
    required this.duration,
    required this.color,
  });

  @override
  __AnimatedIconState createState() => __AnimatedIconState();
}

class __AnimatedIconState extends State<_AnimatedIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: const Offset(0, -0.1),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: _offsetAnimation.value * widget.size,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Icon(
                widget.icon,
                size: widget.size,
                color: widget.color,
              ),
            ),
          );
        },
      ),
    );
  }
}