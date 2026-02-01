class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phone;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      name: map['name'],
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
    };
  }
}
