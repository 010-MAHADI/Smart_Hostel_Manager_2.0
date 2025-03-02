import '../models/market.dart';
import 'db_helper.dart';

class MarketService {
  Future<int> addMarketItem(Market market) async {
    final db = await DBHelper.instance.database;
    return await db.insert('market', market.toMap());
  }

  Future<List<Market>> getMarketItems() async {
    final db = await DBHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query('market');
    return result.map((e) => Market.fromMap(e)).toList();
  }

  Future<int> deleteMarketItem(int id) async {
    final db = await DBHelper.instance.database;
    return await db.delete('market', where: "id = ?", whereArgs: [id]);
  }
}
