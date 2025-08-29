import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_services.dart';
import 'restaurant_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  const RegisterScreen({super.key, required this.onThemeToggle});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false;
  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? generalError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String selectedLanguage = 'English'; // Default value

  final Map<String, Map<String, String>> localization = {
    'English': {
      'app_title': 'QR Menu App',
      'create_account': 'Create Account',
      'username': 'Username',
      'username_required': 'Username is required',
      'email': 'Email',
      'email_required': 'Email is required',
      'valid_email': 'Please enter a valid email address',
      'password': 'Password',
      'password_required': 'Password is required',
      'password_length': 'Password must be at least 6 characters',
      'confirm_password': 'Confirm Password',
      'confirm_password_required': 'Confirm password is required',
      'passwords_match': 'Passwords do not match',
      'continue': 'Continue',
      'have_account': 'Already have an account? ',
      'login': 'Login',
      'email_taken': 'This email is already registered',
      'registration_failed': 'Registration failed. Please try again',
      'registration_success': 'Registration successful!',
    },
    'Khmer': {
      'app_title': 'កម្មវិធីម៉ឺនុយ QR',
      'create_account': 'បង្កើតគណនី',
      'username': 'ឈ្មោះអ្នកប្រើ',
      'username_required': 'ឈ្មោះអ្នកប្រើប្រាស់ត្រូវបានទាមទារ',
      'email': 'អ៊ីមែល',
      'email_required': 'អ៊ីមែលត្រូវបានទាមទារ',
      'valid_email': 'សូមបញ្ចូលអាសយដ្ឋានអ៊ីមែលដែលត្រឹមត្រូវ',
      'password': 'ពាក្យសម្ងាត់',
      'password_required': 'ពាក្យសម្ងាត់ត្រូវបានទាមទារ',
      'password_length': 'ពាក្យសម្ងាត់ត្រូវតែមានយ៉ាងហោចណាស់ ៦ តួអក្សរ',
      'confirm_password': 'បញ្ជាក់ពាក្យសម្ងាត់',
      'confirm_password_required': 'ត្រូវការបញ្ជាក់ពាក្យសម្ងាត់',
      'passwords_match': 'ពាក្យសម្ងាត់មិនត្រូវគ្នា',
      'continue': 'បន្ត',
      'have_account': 'មានគណនីរួចហើយ? ',
      'login': 'ចូល',
      'email_taken': 'អ៊ីមែលនេះត្រូវបានចុះឈ្មោះរួចហើយ',
      'registration_failed': 'ការចុះឈ្មោះបរាជ័យ។ សូមព្យាយាមម្តងទៀត',
      'registration_success': 'ការចុះឈ្មោះជោគជ័យ!',
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
      nameError = null;
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;
      generalError = null;
    });

    bool isValid = true;
    final lang = localization[selectedLanguage]!;

    if (nameController.text.trim().isEmpty) {
      setState(() {
        nameError = lang['username_required'];
      });
      isValid = false;
    }

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

    if (confirmPasswordController.text.isEmpty) {
      setState(() {
        confirmPasswordError = lang['confirm_password_required'];
      });
      isValid = false;
    } else if (confirmPasswordController.text != passwordController.text) {
      setState(() {
        confirmPasswordError = lang['passwords_match'];
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> registerUser() async {
    if (!validateForm()) return;

    setState(() {
      isLoading = true;
      emailError = null; // Clear previous errors
    });

    try {
      await ApiService.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
      );

      if (mounted) {
        final lang = localization[selectedLanguage]!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(lang['registration_success']!)));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RestaurantScreen(onThemeToggle: widget.onThemeToggle),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final lang = localization[selectedLanguage]!;
        setState(() {
          // Handle specific error cases
          if (e.toString().contains("email is already taken") ||
              e.toString().contains("email already exists")) {
            emailError = lang['email_taken'];
          } else if (!isValidEmail(emailController.text.trim())) {
            emailError = lang['valid_email'];
          } else {
            // For other errors, still show on email field but generic message
            emailError = lang['registration_failed'];
          }
        });
      }
    } finally {
      if (mounted) {
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
        height: 60, // Changed from 50 to 60
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
          obscureText: isPassword 
              ? (label == lang['password'] ? _obscurePassword : _obscureConfirmPassword)
              : false,
          keyboardType: keyboardType,
          onChanged: (value) {
            if (errorText != null) {
              setState(() {
                if (controller == nameController) nameError = null;
                if (controller == passwordController) passwordError = null;
                if (controller == confirmPasswordController) confirmPasswordError = null;
              });
            }
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18, // Changed from 12 to 18
            ),
            prefixIcon: Icon(
              icon,
              color: errorText != null
                  ? Colors.red
                  : isDark
                      ? Colors.white70
                      : Colors.deepPurple.shade400,
              size: 28, // Reverted from 24 to 28
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      label == lang['password']
                          ? _obscurePassword ? Icons.visibility_off : Icons.visibility
                          : _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      size: 20, // Reverted from 18 to 20
                    ),
                    onPressed: () {
                      setState(() {
                        if (label == lang['password']) {
                          _obscurePassword = !_obscurePassword;
                        } else {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        }
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            hintText: label,
            hintStyle: TextStyle(
              fontSize: 18, // Reverted from 16 to 18
              color: isDark ? Colors.white70 : Colors.deepPurple.shade400,
              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
            ),
          ),
          style: TextStyle(
            fontSize: 18, // Reverted from 16 to 18
            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
          ),
        ),
      ),
      if (errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4), // Reverted from 4 to 8
          child: Text(
            errorText,
            style: TextStyle(
              color: Colors.red,
              fontSize: 16, // Reverted from 14 to 16
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
      Container(
        height: 60, // Changed from 50 to 60
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: emailError != null ? Colors.red : isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            if (emailError != null) {
              setState(() => emailError = null);
            }
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18, // Changed from 12 to 18
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: emailError != null ? Colors.red : isDark
                      ? Colors.white70
                      : Colors.deepPurple.shade400,
              size: 28, // Reverted from 24 to 28
            ),
            border: InputBorder.none,
            hintText: lang['email'],
            hintStyle: TextStyle(
              fontSize: 18, // Reverted from 16 to 18
              color: isDark
                      ? Colors.white70
                      : Colors.deepPurple.shade400,
              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
            ),
          ),
          style: TextStyle(
            fontSize: 18, // Reverted from 16 to 18
            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
          ),
        ),
      ),
      if (emailError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8), // Reverted from 4 to 8
          child: Text(
            emailError!,
            style: TextStyle(
              color: Colors.red,
              fontSize: 16, // Reverted from 14 to 16
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
            right: 0,
            child: ClipPath(
              clipper: BottomWaveClipper(),
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
                        shape: BoxShape.circle, // Makes it circular
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
                          'assets/logo/app_logo.png', // Path to your logo image
                          height: 50,
                          width: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback in case image fails to load
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Text(
                              lang['create_account']!,
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.deepPurple,
                                    fontFamily: selectedLanguage == 'Khmer'
                                        ? 'NotoSansKhmer'
                                        : null,
                                  ),
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
                                    fontFamily: selectedLanguage == 'Khmer'
                                        ? 'NotoSansKhmer'
                                        : null,
                                  ),
                                ),
                              ),
                            _buildStyledTextField(
                              controller: nameController,
                              label: lang['username']!,
                              icon: Icons.person_outline,
                              errorText: nameError,
                              isDark: isDark,
                              lang: lang,
                            ),
                            const SizedBox(height: 25),
                            _buildEmailField(isDark, lang),
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
                            const SizedBox(height: 25),
                            _buildStyledTextField(
                              controller: confirmPasswordController,
                              label: lang['confirm_password']!,
                              icon: Icons.lock_outline,
                              isPassword: true,
                              errorText: confirmPasswordError,
                              isDark: isDark,
                              lang: lang,
                            ),
                            const SizedBox(height: 35),
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : registerUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 5,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      )
                                    : Text(
                                        lang['continue']!,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily:
                                              selectedLanguage == 'Khmer'
                                              ? 'NotoSansKhmer'
                                              : null,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            // Account section - made responsive
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // For small screens, use a column layout
                                if (constraints.maxWidth < 400) {
                                  return Column(
                                    children: [
                                      Text(
                                        lang['have_account']!,
                                        style: getTextStyle().copyWith(
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => LoginScreen(
                                                onThemeToggle:
                                                    widget.onThemeToggle,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          lang['login']!,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.deepPurple,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily:
                                                selectedLanguage == 'Khmer'
                                                ? 'NotoSansKhmer'
                                                : null,
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
                                        lang['have_account']!,
                                        style: getTextStyle().copyWith(
                                          fontSize: 16,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => LoginScreen(
                                                onThemeToggle:
                                                    widget.onThemeToggle,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          lang['login']!,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.deepPurple,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily:
                                                selectedLanguage == 'Khmer'
                                                ? 'NotoSansKhmer'
                                                : null,
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

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 50);
    var firstControlPoint = Offset(size.width / 3, 0);
    var firstEndPoint = Offset(size.width / 2, 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    var secondControlPoint = Offset(size.width * 2 / 3, 60);
    var secondEndPoint = Offset(size.width, 20);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}