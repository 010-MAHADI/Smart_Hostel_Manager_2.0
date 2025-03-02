class Member {
  int? id;
  String name;
  double balance;

  Member({this.id, required this.name, required this.balance});

  factory Member.fromMap(Map<String, dynamic> json) => Member(
        id: json['id'],
        name: json['name'],
        balance: json['balance'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
    };
  }
}
