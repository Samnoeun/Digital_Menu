import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final ValueChanged<Locale> onLanguageSelected;
  final List<Map<String, String>> languages = const [
    {'code': 'en', 'name': 'English'},
    {'code': 'km', 'name': 'ភាសាខ្មែរ'},
  ];

  const LanguageSelector({
    super.key,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Language',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._buildLanguageOptions(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLanguageOptions() {
    return List<Widget>.generate(languages.length * 2 - 1, (index) {
      if (index.isOdd) return const Divider(height: 1);
      final languageIndex = index ~/ 2;
      return _buildLanguageItem(languages[languageIndex]);
    });
  }

  Widget _buildLanguageItem(Map<String, String> language) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onLanguageSelected(Locale(language['code']!)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          language['name']!,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
