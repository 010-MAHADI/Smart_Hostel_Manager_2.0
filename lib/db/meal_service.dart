import '../models/meal.dart';
import 'db_helper.dart';

class MealService {
  Future<int> addMeal(Meal meal) async {
    final db = await DBHelper.instance.database;
    return await db.insert('meals', meal.toMap());
  }

  Future<List<Meal>> getMeals() async {
    final db = await DBHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query('meals');
    return result.map((e) => Meal.fromMap(e)).toList();
  }

  Future<int> deleteMeal(int id) async {
    final db = await DBHelper.instance.database;
    return await db.delete('meals', where: "id = ?", whereArgs: [id]);
  }
}
