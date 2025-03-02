class Market {
  int? id;
  String item;
  double amount;
  String date;

  Market({this.id, required this.item, required this.amount, required this.date});

  // Map থেকে Market object তৈরি
  factory Market.fromMap(Map<String, dynamic> map) {
    return Market(
      id: map['id'],
      item: map['item'],
      amount: map['amount'],
      date: map['date'],
    );
  }

  // Market object থেকে Map তৈরি
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item': item,
      'amount': amount,
      'date': date,
    };
  }
}
