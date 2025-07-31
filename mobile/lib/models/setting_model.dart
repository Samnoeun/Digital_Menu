class SettingModel {
  final int? id;
  final String restaurantName;
  final String address;
  final String? logo;
  final String? currency;
  final String? language;
  final bool? darkMode;

  SettingModel({
    this.id,
    required this.restaurantName,
    required this.address,
    this.logo,
    this.currency,
    this.language,
    this.darkMode,
  });

  factory SettingModel.fromJson(Map<String, dynamic> json) {
    return SettingModel(
      id: json['id'],
      restaurantName: json['restaurant_name'] ?? '',
      address: json['address'] ?? '',
      logo: json['logo'],
      currency: json['currency'],
      language: json['language'],
      darkMode: json['dark_mode'] == 1 || json['dark_mode'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurant_name': restaurantName,
      'address': address,
      'logo': logo,
      'currency': currency,
      'language': language,
      'dark_mode': darkMode == true ? 1 : 0,
    };
  }
}
