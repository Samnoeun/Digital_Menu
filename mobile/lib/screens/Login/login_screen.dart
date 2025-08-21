import 'package:flutter/material.dart';
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

    if (emailController.text.trim().isEmpty) {
      setState(() {
        emailError = 'Email is required';
      });
      isValid = false;
    } else if (!isValidEmail(emailController.text.trim())) {
      setState(() {
        emailError = 'Please enter a valid email address';
      });
      isValid = false;
    }

    if (passwordController.text.isEmpty) {
      setState(() {
        passwordError = 'Password is required';
      });
      isValid = false;
    } else if (!isValidPassword(passwordController.text)) {
      setState(() {
        passwordError = 'Password must be at least 6 characters';
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
      String errorMessage = e.toString();
      
      if (errorMessage.contains("No account found with this email address")) {
        setState(() {
          emailError = "Email not found. Please check or register";
          passwordError = null;
        });
      } else if (errorMessage.contains("Invalid password") || 
                 errorMessage.contains("Incorrect password")) {
        setState(() {
          passwordError = "Incorrect password. Please try again";
          emailError = null;
        });
      } else if (errorMessage.contains("account is locked") || 
                 errorMessage.contains("too many attempts")) {
        setState(() {
          passwordError = "Account locked. Try again later or reset password";
        });
      } else {
        setState(() {
          generalError = "Login failed. Please try again";
        });
      }
    } finally {
      if (context.mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        'QR Menu App',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.deepPurple,
                              letterSpacing: 1.2,
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
                            'Welcome Back',
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.deepPurple,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sign in to your account',
                            style: Theme.of(context).textTheme.bodyMedium,
                            
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
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          _buildEmailField(isDark),
                          const SizedBox(height: 16),
                          _buildPasswordField(isDark),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Add forgot password functionality
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.deepPurple.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
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
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 24, // Larger font
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Or continue with',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSocialButton(
                                icon: Icons.g_mobiledata,
                                label: 'Google',
                                color: Colors.red,
                                onTap: () {
                                  // Add Google sign-in logic
                                },
                                isDark: isDark,
                              ),
                              _buildSocialButton(
                                icon: Icons.apple,
                                label: 'Apple',
                                color: isDark ? Colors.white70 : Colors.black,
                                onTap: () {
                                  // Add Apple sign-in logic
                                },
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account?',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
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
                            'Create account',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.deepPurple,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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

 Widget _buildPasswordField(bool isDark) {
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
            labelText: 'Password',
            labelStyle: TextStyle(
              color: passwordError != null
                  ? Colors.red.shade400
                  : isDark
                      ? Colors.white70
                      : Colors.deepPurple.shade400,
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
          style: Theme.of(context).textTheme.bodyLarge,
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
            ),
          ),
        ),
    ],
  );
}

  Widget _buildEmailField(bool isDark) {
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
              labelText: 'Email',
              labelStyle: TextStyle(
                color: emailError != null
                    ? Colors.red.shade400
                    : isDark
                        ? Colors.white70
                        : Colors.deepPurple.shade400,
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
            style: Theme.of(context).textTheme.bodyLarge,
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
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
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