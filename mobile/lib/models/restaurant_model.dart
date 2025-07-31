class Restaurant {
  final int id;
  final String restaurantName;
  final String? profile;
  final String? address;

  Restaurant({
    required this.id,
    required this.restaurantName,
    this.profile,
    this.address,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      restaurantName: json['restaurant_name'] ?? '',
      profile: json['profile'], // or 'logo' if your API uses that
      address: json['address'],
    );
  }
}
