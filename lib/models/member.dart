class Member {
  int? id;
  String name;
  String phone;
  String email;
  String address;
  String mealPreference; // Veg or Non-Veg
  double balance;
  int totalMeals;
  String description;
  String? profileImagePath; // Path to the profile picture

  Member({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.mealPreference,
    this.balance = 0.0,
    this.totalMeals = 0,
    this.description = '',
    this.profileImagePath,
  });

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      mealPreference: map['mealPreference'],
      balance: map['balance'],
      totalMeals: map['totalMeals'],
      description: map['description'],
      profileImagePath: map['profileImagePath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'mealPreference': mealPreference,
      'balance': balance,
      'totalMeals': totalMeals,
      'description': description,
      'profileImagePath': profileImagePath,
    };
  }
}