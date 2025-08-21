import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  String selectedLanguage = 'English'; // Default value

  final Map<String, Map<String, String>> localization = {
    'English': {
      'add_category': 'Add Category',
      'edit_category': 'Edit Category',
      'create_category': 'Create Category',
      'update_category': 'Update Category',
      'category_name': 'Category Name',
      'enter_category_name': 'Enter category name',
      'please_enter_name': 'Please enter a category name',
      'add_new_category': 'Add a new category to organize your items',
      'update_category_info': 'Update the category information',
      'category_added': 'Category added successfully',
      'category_updated': 'Category updated successfully',
      'error': '{error}',
    },
    'Khmer': {
      'add_category': 'បន្ថែមប្រភេទ',
      'edit_category': 'កែប្រែប្រភេទ',
      'create_category': 'បង្កើតប្រភេទ',
      'update_category': 'ធ្វើបច្ចុប្បន្នភាពប្រភេទ',
      'category_name': 'ឈ្មោះប្រភេទ',
      'enter_category_name': 'បញ្ចូលឈ្មោះប្រភេទ',
      'please_enter_name': 'សូមបញ្ចូលឈ្មោះប្រភេទ',
      'add_new_category': 'បន្ថែមប្រភេទថ្មីដើម្បីរៀបចំធាតុរបស់អ្នក',
      'update_category_info': 'ធ្វើបច្ចុប្បន្នភាពព័ត៌មានប្រភេទ',
      'category_added': 'បានបន្ថែមប្រភេទដោយជោគជ័យ',
      'category_updated': 'បានធ្វើបច្ចុប្បន្នភាពប្រភេទដោយជោគជ័យ',
      'error': '{error}',
    },
  };

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
    _loadSavedLanguage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      selectedLanguage = savedLanguage;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      if (widget.category == null) {
        await ApiService.createCategory(_nameController.text);
        _showSuccessSnackbar(localization[selectedLanguage]!['category_added']!);
      } else {
        await ApiService.updateCategory(
          widget.category!.id,
          _nameController.text,
        );
        _showSuccessSnackbar(localization[selectedLanguage]!['category_updated']!);
      }
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackbar(localization[selectedLanguage]!['error']!.replaceFirst('{error}', e.toString()));
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: error.contains('restaurant')
            ? SnackBarAction(
                label: 'Create Restaurant',
                textColor: Colors.white,
                onPressed: () =>
                    Navigator.pushNamed(context, '/create-restaurant'),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple;
    final scaffoldBgColor = isDarkMode ? Colors.grey[900] : Colors.deepPurple.shade50;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final inputFillColor = isDarkMode ? Colors.grey[700] : Colors.deepPurple.shade50;
    final lang = localization[selectedLanguage]!;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 2, right: 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 0),
              Text(
                widget.category == null
                    ? lang['add_category']!
                    : lang['edit_category']!,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: Colors.white,
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                isDarkMode ? Colors.deepPurple.shade500 : Colors.deepPurple.shade400,
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
                    minHeight: MediaQuery.of(context).size.height -
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
                                color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
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
                                        isDarkMode ? Colors.deepPurple.shade500 : Colors.deepPurple.shade400,
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
                                      ? lang['create_category']!
                                      : lang['update_category']!,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.category == null
                                      ? lang['add_new_category']!
                                      : lang['update_category_info']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: secondaryTextColor,
                                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: lang['category_name']!,
                                    labelStyle: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                    ),
                                    hintText: lang['enter_category_name']!,
                                    prefixIcon: Icon(
                                      Icons.label_outline,
                                      color: primaryColor,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDarkMode ? Colors.grey[600]! : Colors.deepPurple.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDarkMode ? Colors.grey[600]! : Colors.deepPurple.shade300,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: inputFillColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return lang['please_enter_name']!;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor,
                                        isDarkMode ? Colors.deepPurple.shade500 : Colors.deepPurple.shade400,
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
                                            mainAxisAlignment: MainAxisAlignment.center,
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
                                                    ? lang['add_category']!
                                                    : lang['update_category']!,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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