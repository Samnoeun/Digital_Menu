import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/api_services.dart';

class AddCategoryScreen extends StatefulWidget {
  final Category? category;
  const AddCategoryScreen({Key? key, this.category}) : super(key: key);

  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isDuplicateName = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.category != null) {
      _nameController.text = widget.category!.name;
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

 Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    setState(() {
      _isLoading = true;
      _isDuplicateName = false;
    });

    if (widget.category == null) {
      // Create category
      await ApiService.createCategory(_nameController.text);
      _showSuccessSnackbar('Category added successfully');
    } else {
      // Update category
      await ApiService.updateCategory(
        widget.category!.id,
        _nameController.text,
      );
      _showSuccessSnackbar('Category updated successfully');
    }

    Navigator.pop(context, true);

  } catch (e) {
    // Laravel now returns 400 with message if duplicate for the same restaurant
    if (e.toString().contains('Category name already exists')) {
      setState(() {
        _isDuplicateName = true;
      });
      _formKey.currentState!.validate();
      _showErrorSnackbar('Category "${_nameController.text}" already exists for your restaurant');
    } else {
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

void _showSuccessSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 2), // Optional: Add duration
    ),
  );
}
void _showErrorSnackbar(String error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(error)),
        ],
      ),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode
        ? Colors.deepPurple[600]
        : Colors.deepPurple;
    final scaffoldBgColor = isDarkMode
        ? Colors.grey[900]
        : Colors.deepPurple.shade50;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final inputFillColor = isDarkMode
        ? Colors.grey[700]
        : Colors.deepPurple.shade50;
    final errorColor = Colors.red.shade400;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 2, right: 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 0),
              Text(
                widget.category == null ? 'Add Category' : 'Edit Category',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
        backgroundColor: primaryColor,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor!,
                isDarkMode
                    ? Colors.deepPurple.shade600
                    : Colors.deepPurple.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        kToolbarHeight -
                        40,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(
                                  255,
                                  71,
                                  70,
                                  70,
                                ).withOpacity(isDarkMode ? 0.2 : 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor,
                                        isDarkMode
                                            ? Colors.deepPurple.shade500
                                            : Colors.deepPurple.shade400,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.category_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  widget.category == null
                                      ? 'Create Category'
                                      : 'Edit Category',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.category == null
                                      ? 'Add a new category to organize your items'
                                      : 'Update the category information',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: secondaryTextColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Category Name',
                                    labelStyle: TextStyle(
                                      color: _isDuplicateName
                                          ? errorColor
                                          : (isDarkMode
                                                ? Colors.white
                                                : primaryColor),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    hintText: 'Enter category name',
                                    hintStyle: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.label_outline,
                                      color: _isDuplicateName
                                          ? errorColor
                                          : (isDarkMode
                                                ? Colors.white
                                                : primaryColor),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _isDuplicateName
                                            ? errorColor
                                            : (isDarkMode
                                                  ? Colors.grey[600]!
                                                  : Colors.deepPurple.shade300),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _isDuplicateName
                                            ? errorColor
                                            : (isDarkMode
                                                  ? Colors.white
                                                  : primaryColor),
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _isDuplicateName
                                            ? errorColor
                                            : (isDarkMode
                                                  ? Colors.grey[600]!
                                                  : Colors.deepPurple.shade300),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode
                                        ? Colors.grey[800]
                                        : inputFillColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    errorText: _isDuplicateName
                                        ? 'Category name already exists'
                                        : null,
                                    errorStyle: TextStyle(
                                      color: errorColor,
                                      fontSize: 14,
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: errorColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: errorColor,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a category name';
                                    }
                                    if (_isDuplicateName) {
                                      return '"$value" already exists. Please use a different name.';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    if (_isDuplicateName) {
                                      setState(() {
                                        _isDuplicateName = false;
                                      });
                                      _formKey.currentState?.validate();
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor,
                                        isDarkMode
                                            ? Colors.deepPurple.shade500
                                            : Colors.deepPurple.shade400,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(0),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                widget.category == null
                                                    ? Icons.add_rounded
                                                    : Icons.update_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                widget.category == null
                                                    ? 'Add Category'
                                                    : 'Update Category',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
