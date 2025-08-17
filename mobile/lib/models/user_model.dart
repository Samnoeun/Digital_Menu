class UserModel {
  final int id;
  final String name;
  final String email;
   final String? token; // Add this field if missing

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.token, // Make sure to initialize this field
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      token: json['token'], 
    );
  }
}
