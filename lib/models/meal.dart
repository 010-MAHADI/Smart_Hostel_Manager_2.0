class Meal {
  int? id;
  int memberId;
  String date;
  int breakfast;
  int lunch;
  int dinner;

  Meal({
    this.id,
    required this.memberId,
    required this.date,
    this.breakfast = 0,
    this.lunch = 0,
    this.dinner = 0,
  });

  // Map থেকে Meal object তৈরি
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      memberId: map['member_id'],
      date: map['date'],
      breakfast: map['breakfast'],
      lunch: map['lunch'],
      dinner: map['dinner'],
    );
  }

  // Meal object থেকে Map তৈরি
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'date': date,
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
    };
  }
}
