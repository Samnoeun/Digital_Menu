class SettingModel {
  final String restaurantName;
  final String? logo;
  final String address;
  final String currency;
  final String language;
  final bool darkMode;

  SettingModel({
    required this.restaurantName,
    required this.logo,
    required this.address,
    required this.currency,
    required this.language,
    required this.darkMode,
  });

  factory SettingModel.fromJson(Map<String, dynamic> json) {
    return SettingModel(
      restaurantName: json['restaurant_name'],
      logo: json['logo'],
      address: json['address'],
      currency: json['currency'],
      language: json['language'],
      darkMode: json['dark_mode'] ?? false,
    );
  }
}
